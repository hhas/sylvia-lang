//
//  parser.swift
//

// Pratt parser (enhanced recursive descent parser that supports operator fixity and associativity)

// TO DO: how best to implement incremental parsing e.g. might do per-line parsing, with each Line keeping a count of any opening/closing { }, [ ], ( ), « » blocks and quotes, along with any other hints such as indentation and possible keywords; a block-level analyzer could then attempt to collate lines into balanced blocks, detecting both obvious imbalances (e.g. `{[}]`, `{[[]}`) and more subtle ones (e.g. `{[]{[]}`) and providing best guesses as to where the correction should be made (e.g. given equally indented blocks, `{}{{}{}` the unbalanced `{` is more likely to need the missing `}` inserted before the next `{}`, not at end of script [as a dumber parser would report]; looking for keywords that are commonly expected at top-level or within blocks may also provide hints as to when to discard previous tally as unbalanced and start a new one from top level)

// TO DO: all Value subclasses instantiated by parsefuncs should be defined as constants on a struct which is passed as [optional] argument to parser's initializer; this will allow parser to generate AST trees for multiple purposes: running, debugging, profiling, structure editing, optimizing, cross-compiling (Q. is it enough to provide an instantiable ASTNodes struct, or is it better to define ASTNodes as a protocol? be aware that all attributes need to conform to Value plus appropriate initializer, which is probably best done as `typealias ASTTextNode = Value & TextInterface`)


import Foundation



class Parser {
    
    // TO DO: how do .lineBreak tokens interact with expression parsing? how suitable is recursive implementation for interactive per-line use? (or is better to use line analyzer - which doesn't generate AST, only line-balancing tallys - during editing, and only invoke parser when all tallys balance?)
    
    let tokens: [TokenInfo]
    var index = 0
    
    init(_ tokens: [TokenInfo]) {
        self.tokens = tokens
    }
    
    // cursor
    
    var this: Token { return self.tokens[self.index].type }
    
    // TO DO: might be simpler always to ignore whitespace and set a didSkipWhitespace flag which can be checked when needed (or provide an optional callback hook on ASTNodes struct, allowing clients to subscribe/ignore as they need; or, assuming parsing for execution never requires whitespace knowledge, put discardWhitespace option on Lexer initializer)
    
    func next(ignoringWhitespace: Bool = true) -> Token {
        self.index += 1
        while ignoringWhitespace, self.index < self.tokens.count, case .whitespace(_) = self.tokens[self.index].type { self.index += 1 }
        return self.index < self.tokens.count ? self.tokens[self.index].type : .endOfCode
    }
    
    func peek(ignoringWhitespace: Bool = true) -> Token { // options to ignore .whitespace (default is probably true) and .lineBreak
        var index = self.index + 1
        while ignoringWhitespace, index < self.tokens.count, case .whitespace(_) = self.tokens[index].type { index += 1 }
        return index < self.tokens.count ? self.tokens[index].type : .endOfCode
    }
    
    // token matching
    
    func parseAtom(_ token: Token, _ precedence: Int = 0) throws -> Value {
        var token = token
        // TO DO: what about .endOfCode? can it occur here?
        switch token {
        case .annotationLiteral(let annotation): // «...» // attaches arbitrary metadata to subsequent node (TO DO: should really behave as postfix, attaching itself to preceding node [except at top level of script/block where it attaches to parent node, e.g. handler docs would appear at top of handler body], although we might need to jig that top-level behavior a bit)
            let value = try self.parseExpression(token.precedence) // bind like glue // TO DO: is this right? (or should it just call `parseAtom(next(),precedence)`, which avoids possibility of anything having higher precedence than annotations?)
            value.annotations.append(annotation) // TO DO: for straightforward evaluation, discard annotations that aren't introspectable (e.g. comments); don't worry about annotating for structure editors, as they'll probably use their own mutable Node objects
            return value
        case .listLiteral:      // `[…]` - an ordered collection (array) or key-value collection (dictionary)
            var result = [Value]()
            // Swift allows `while case ENUM = EXPR` but not `while !(case ENUM = EXPR)`, so have to use separate `if…break` condition
            while true {
                if case Token.listLiteralEnd = self.peek() { break } // (note: if next token is .endOfCode, parseExpression will catch that so don't need to check for it here)
                result.append(try self.parseExpression())
            }
            guard case .listLiteralEnd = self.next() else { throw SyntaxError("Expected “]” but found \(self.this)") }
            return List(result)
        case .blockLiteral:     // `{…}`
            var result = [Value]()
            while true {
                if case Token.blockLiteralEnd = self.peek() { break }
                result.append(try self.parseExpression())
                // TO DO: if self.peek() [ignoring whitespace] is not blockLiteralEnd or .lineFeed (or .itemSeparator ignoring linefeeds as well for lists)
            }
            guard case .blockLiteralEnd = self.next() else { throw SyntaxError("Expected “}” but found \(self.this)") }
            return Block(result)
        case .groupLiteral:     // `(…)`
            let value = try self.parseExpression() // TO DO: how should comma separators be treated? (argument lists use them; not sure about precedence groups, e.g. `1 * (foo, 3 + 4)` could be problematic)
            guard case .blockLiteralEnd = self.next() else { throw SyntaxError("Expected “)” but found \(self.this)") }
            return value
        case .textLiteral(value: let string):
            return Text(string)
        case .identifier(value: let name, isQuoted: _): // `NAME`
            if case Token.groupLiteral = self.peek() {  // `NAME(…`
                var arguments = [Value]()
                while true {
                    if case Token.groupLiteralEnd = self.next() { break } // advance to first item in argument list, or break if empty
                    do {
                        arguments.append(try self.parseExpression())
                    } catch {
                        print("Failed to read argument \(arguments.count):", error)
                        throw error
                    }
                    if case Token.itemSeparator = self.peek() { () } else { break } // TO DO: skipIfItemSeparator()->Bool
                }
                guard case .groupLiteralEnd = self.next() else { throw SyntaxError("Expected “)” but found \(self.this)") }
                return Command(name, arguments)
            } else {
                return Identifier(name)
            }
        case .number(value: let string): // TO DO: use Scalar
            let value = Text(string)
            value.annotations.append(Double(string) as Any) // TO DO: annotation API
            return value
        case .operatorName(value: let name, prefix: let definition, infix: nil) where definition != nil:
            switch definition!.parseFunc {
            case .atom(let parseFunc), .prefix(let parseFunc):
                return try parseFunc(self, name, definition!.precedence) // note: this does not prevent custom parseFuncs reading/not reading next token[s]; thus the distinction between .atom and .prefix (or .infix and .suffix) is informative only; some parsefuncs may even deliberately support both, peeking ahead to determine whether or not a trailing operand is present and outputting the appropriate .atom/.prefix (or .infix/.suffix) Command (although this is frowned on as it means the parsefunc must supply custom commands names itself rather than using canonical name from operator definition, which isn't something [currently/ever?] supported by auto-documentation tools)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in atom/prefix table.")
            }
        case .lineBreak: // TO DO: how best to process line breaks? // note: if line ends on prefix/infix operator, this will grab remaining operand from subsequent line; we may want to guard against this, or at least limit its scope of action to next line only
            while case .lineBreak = token {
                token = self.next()
            }
            return try self.parseAtom(token)
        default:
            throw SyntaxError("Expected expression but found \(token)")
        }
    }
    func parseOperation(_ token: Token, _ leftExpr: Value) throws -> Value {
        switch token {
        case .annotationLiteral(let string): // «...» // attaches arbitrary contents to preceding node as metadata
            leftExpr.annotations.append(string)
            return leftExpr
        case .operatorName(value: let name, prefix: _, infix: let definition):
            if definition == nil { return try self.parseAtom(token)  }
            switch definition!.parseFunc {
            case .infix(let parseFunc), .postfix(let parseFunc):
                return try parseFunc(self, leftExpr, name, definition!.precedence)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in infix/postfix table.")
            }
        case .lineBreak: // TO DO: how best to process line breaks? // note: if line ends on prefix/infix operator, this will grab remaining operand from subsequent line; we may want to guard against this, or at least limit its scope of action to next line only
            var token = token
            while case .lineBreak = token {
                token = self.next()
            }
            return try self.parseOperation(token, leftExpr)
//        case .itemSeparator: // TO DO: make sure this token has appropriate precedence to ensure parseExpression exits its while look, and delete this case
//            print("Found item separator (caller is responsible for discarding it); returning current leftexpr:",leftExpr)
//            return leftExpr
        default:
            throw SyntaxError("Invalid token after \(leftExpr): \(token)")
        }
    }
    
    func parseExpression(_ precedence: Int = 0) throws -> Value { // cursor should be on preceding token when called
        let token = self.next()
       // print("parseExpression reading:",token)
        var left = try self.parseAtom(token)
       // print("Parsed atom; now on \(self.this); next is:",self.peek(), "precedence (expression<next):", precedence, "<", self.peek().precedence)
        while precedence < self.peek().precedence { // TO DO:
            left = try self.parseOperation(self.next(), left)
            //print(precedence,"<", self.peek().precedence)
        }
       // print("ended parseExpression on:",self.this)
        return left
    }
    
    // main
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        guard case .startOfCode = self.this else { throw SyntaxError("Expected start of code but found: \(self.this)") }
        var result = [Value]()
        do {
        while true {
            if case .endOfCode = self.peek() { break } // note: can't parameterize Token as some cases have associated values
            result.append(try self.parseExpression())
            // TO DO: what delimiters? (.lineBreak)
        }
        guard case .endOfCode = self.next() else { throw SyntaxError("Expected end of code but found: \(self.this)") }
        return ScriptAST(result) // TBH, should swap this around so ScriptAST initializer takes code as argument and lexes and parses it
        } catch {
            print("Partially parsed script:", result)
            throw error
        }
    }
    
}

