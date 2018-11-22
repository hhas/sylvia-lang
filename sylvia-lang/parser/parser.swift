//
//  parser.swift
//

// Pratt parser (enhanced recursive descent parser that supports operator fixity and associativity)

// TO DO: how best to implement incremental parsing e.g. might do per-line parsing, with each Line keeping a count of any opening/closing { }, [ ], ( ), « » blocks and quotes, along with any other hints such as indentation and possible keywords; a block-level analyzer could then attempt to collate lines into balanced blocks, detecting both obvious imbalances (e.g. `{[}]`, `{[[]}`) and more subtle ones (e.g. `{[]{[]}`) and providing best guesses as to where the correction should be made (e.g. given equally indented blocks, `{}{{}{}` the unbalanced `{` is more likely to need the missing `}` inserted before the next `{}`, not at end of script [as a dumber parser would report]; looking for keywords that are commonly expected at top-level or within blocks may also provide hints as to when to discard previous tally as unbalanced and start a new one from top level)

// TO DO: all Value subclasses instantiated by parsefuncs should be defined as constants on a struct which is passed as [optional] argument to parser's initializer; this will allow parser to generate AST trees for multiple purposes: running, debugging, profiling, structure editing, optimizing, cross-compiling (Q. is it enough to provide an instantiable ASTNodes struct, or is it better to define ASTNodes as a protocol? be aware that all attributes need to conform to Value plus appropriate initializer, which is probably best done as `typealias ASTTextNode = Value & TextInterface`)



// TO DO: what about `parseIfBlock`, `parseIfGroup`, etc for use by custom parse funcs, e.g. `if EXPR BLOCK` operator (note, incidentally, that this could be defined as `if EXPR EXPR`, but that might be risky if `EXPR EXPR` is a special pattern, e.g. `documentFile 1` [shorthand for `documentFiles[1]`, or `documentFile at 1`, or whatever], or `WORD WORD` [invalid identifier sequence, indicative of quoted text body])

// TO DO: what about taking advantage of Markdown heading syntax in annotations (e.g. `«= SECTION =»` `«== SUBSECTION ==»`) to enable developer notes to better describe high-level program structure? (standardizes traditional ad-hoc customs for describing layout and allows code editor's pretty printer to apply literate formatting, as well as fast navigation around large scripts, code folding/executive summary, etc); also decide if developer annotations should be formally 'typed', e.g. `«TODO:…»`, or if they should just employ existing hashtags, e.g. `«#TODO…»` (hashtags have benefit of being open-ended); still need to decide how userdoc annotations are distinguished from other types of annotations (obviously we don't want to leak internal developer notes to end users should author use wrong type, so probably want to use `«…»` for private annotations and `«XXXX…»` for user-visible notes, where `XXXX` is concise but distinctive symbol/word that is unlikely to appear accidentally at start of other annotations, e.g. `«?…»`, where `?` denotes 'help' in both annotations and language syntax [e.g. `COMMAND()?` could put interpreter into exploratory/debug mode when that command is reached, allowing user to view/edit command's current arguments, call stack, target handler[s] documentation/definition, etc, then halt/resume execution when happy])


// caution: don't allow `(…,…,…)` as arbitrary evaluation sequence (c.f. blocks), as it's already used as tuple syntax in commands and handlers

// TO DO: parser doesn't handle trailing line breaks in scripts yet (hopefully just needs .endOfCode to have its own precedence)

// TO DO: consider recognizing `NAME(ARGUMENTS) «?returning TYPE» BLOCK` pattern as named, unbound handler that optionally takes arguments and may declare return type, i.e. a standard closure (in which case `to`/`when` operators are effectively just binding agents, although exact implementation will differ as they won't create a closure for it); difference between this and BLOCK (`{…}`) is that latter is an unnamed closure that takes no arguments; this saves users having to declare and bind a handler before passing it as argument to a command, e.g. `sortList(listOfObjects, key:_(item){item.attributeToSortOn})` (e.g. in Python, either `def NAME(ARGUMENTS):BLOCK` statement or `lambda ARGUMENTS:EXPR` expression must be used); also note that this syntax forbids treating `COMMAND BLOCK` as a command whose last argument is trailing block (c.f. Swift)

// TO DO: parser needs to maintain line count and annotate AST values with file, line, and start+end indexes for use in error messages (non-AST values might also optionally be annotated during debug sessions, enabling introspection tools to determine runtime-created values' origins)



import Foundation



class Parser {
    
    // TO DO: how do .lineBreak tokens interact with expression parsing? how suitable is recursive implementation for interactive per-line use? (or is better to use line analyzer - which doesn't generate AST, only line-balancing tallys - during editing, and only invoke parser when all tallys balance?)
    
    let tokens: [TokenInfo]
    var index = 0
    
    init(_ tokens: [TokenInfo]) {
        self.tokens = tokens
    }
    
    // cursor
    
    var this: Token { return self.index < self.tokens.count ? self.tokens[self.index].type : .endOfCode }
    
    // TO DO: might be simpler always to ignore whitespace and set a didSkipWhitespace flag which can be checked when needed (or provide an optional callback hook on ASTNodes struct, allowing clients to subscribe/ignore as they need; or, assuming parsing for execution never requires whitespace knowledge, put discardWhitespace option on Lexer initializer)
    
    @discardableResult func next(ignoringWhitespace: Bool = true) -> Token {
        self.index += 1
        while ignoringWhitespace, self.index < self.tokens.count, case .whitespace(_) = self.tokens[self.index].type { self.index += 1 }
        return self.this
    }
    
    func peek(ignoringWhitespace: Bool = true) -> Token { // options to ignore .whitespace (default is probably true) and .lineBreak
        var index = self.index + 1
        while ignoringWhitespace, index < self.tokens.count, case .whitespace(_) = self.tokens[index].type { index += 1 }
        return index < self.tokens.count ? self.tokens[index].type : .endOfCode
    }
    
    func skipLineBreaks() {
        while case .lineBreak = self.this { self.next() }
    }
    
    //
    
    func readBlock() throws -> Block {
        var items = [Value]()
        self.next()
        while true {
            self.skipLineBreaks()
            if case Token.blockLiteralEnd = self.this { break }
            items.append(try self.parseExpression(self.this)) // parseExpression starts by advancing 1 token
            //print("readBlock read line:", items.last!)
            guard case Token.lineBreak = self.next() else { break }
            if case Token.blockLiteralEnd = self.this { break }
        }
        guard case .blockLiteralEnd = self.this else {
            throw SyntaxError("Expected expression or end of block but found: \(self.this)")
        }
        return Block(items)
    }
    
    func readCommaDelimitedValues(_ isEndToken: ((Token) -> Bool)) throws -> [Value] { // e.g. `[EXPR,EXPR,EXPR]` // cursor should be on opening brace when calling this; on completion, cursor is on closing brace
        // TO DO: needs better error messages; best would be to call Parser.syntaxError(…) with cursor on problem token; it can then add token info, chained exception, etc
        var items = [Value]()
        //print("reading arglist, this=\(self.this), next=\(self.peek())")
        while !isEndToken(self.next()) {
            do {
                items.append(try self.parseExpression(self.this)) // this advances onto next token
            } catch { // TO DO: get rid of this once parser reports error locations
                print("Failed to read item \(items.count+1):", error)
                throw error
            }
            if case Token.itemSeparator = self.next() { () } else { break } // TO DO: token type is dependent on block type (current func name is misleading as it's also used for blocks, which contain return-, not comma-, delimited expressions); where commas are used as separators, returns may also be inserted to wrap long lists across multiple lines for readability, so these must be allowed for too [we might restrict position of line breaks to after comma separators only, as dynamically wrapping long expressions to fit display width should really be code editor's job, not pretty printer's]
        }
        guard isEndToken(self.this) else {
            //print("prev:", self.tokens[self.index-1])
            //print(self.tokens[self.index..<self.tokens.count].map{$0.type})
            throw SyntaxError("Unexpected code after item \(items.count+1): \(self.this)")
        }
        return items
    }
    
    // token matching
    
    func parseAtom(_ token: Token, _ precedence: Int = 0) throws -> Value {
        //print("parseAtom", token)
        // TO DO: what about .endOfCode? can it occur here?
        switch token {
        case .annotationLiteral(let annotation): // «...» // attaches arbitrary metadata to subsequent node (TO DO: should really behave as postfix, attaching itself to preceding node [except at top level of script/block where it attaches to parent node, e.g. handler docs would appear at top of handler body], although we might need to jig that top-level behavior a bit)
            self.next()
            let value = try self.parseExpression(self.this, token.precedence) // bind like glue // TO DO: is this right? (or should it just call `parseAtom(next(),precedence)`, which avoids possibility of anything having higher precedence than annotations?)
            value.annotations.append(annotation) // TO DO: for straightforward evaluation, discard annotations that aren't introspectable (e.g. comments); don't worry about annotating for structure editors, as they'll probably use their own mutable Node objects
            return value
        case .listLiteral:      // `[…]` - an ordered collection (array) or key-value collection (dictionary)
            return try List(self.readCommaDelimitedValues(isEndOfList))
        case .blockLiteral:     // `{…}`
            return try self.readBlock()
        case .groupLiteral:     // `(…)`
            let value = try self.parseExpression(self.next()) // TO DO: how should comma separators be treated? (argument lists use them; not sure about precedence groups, e.g. `1 * (foo, 3 + 4)` could be problematic)
            guard case .groupLiteralEnd = self.next() else { throw SyntaxError("Expected “)” but found \(self.this)") }
            return value
        case .textLiteral(value: let string):
            return Text(string)
        case .identifier(value: let name, isQuoted: _): // `NAME`
            if case Token.groupLiteral = self.peek() {  // `NAME (…` (i.e. COMMAND = `NAME GROUP`)
                self.next() // advance cursor onto "("
                return try Command(name, self.readCommaDelimitedValues(isEndOfGroup))
            } else {
                return Identifier(name)
            }
        case .number(value: let string): // TO DO: use Scalar
            let value = Text(string)
            value.annotations.append(Double(string) as Any) // TO DO: annotation API
            return value
        case .operatorName(value: let name, prefix: let definition, infix: _) where definition != nil:
            switch definition!.parseFunc {
            case .atom(let parseFunc), .prefix(let parseFunc):
                
                // TO DO: parseFunc needs full definition: underlying commands should use word names, not symbol names
                
                return try parseFunc(self, name, definition!) // note: this does not prevent custom parseFuncs reading/not reading next token[s]; thus the distinction between .atom and .prefix (or .infix and .suffix) is informative only; some parsefuncs may even deliberately support both, peeking ahead to determine whether or not a trailing operand is present and outputting the appropriate .atom/.prefix (or .infix/.suffix) Command (although this is frowned on as it means the parsefunc must supply custom commands names itself rather than using canonical name from operator definition, which isn't something [currently/ever?] supported by auto-documentation tools)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in atom/prefix table.")
            }
        case .lineBreak: // TO DO: how best to process line breaks? // note: if line ends on prefix/infix operator, this will grab remaining operand from subsequent line; we may want to guard against this, or at least limit its scope of action to next line only
            var token = token
            while case .lineBreak = token { token = self.next() }
            // TO DO: after skipping line breaks, should next value be annotated with formatting hint for pretty printer?
            return try self.parseAtom(token) // TO DO: throws syntax error if token is .endOfCode
        case .endOfCode:
            // TO DO: need to sort out some janky control flow
            throw SyntaxError("endOfCode; TO DO: FIX: if preceding expression was at top-level of program then parseScript() should have return successfully")
        default:
            throw SyntaxError("parseAtom Expected expression but found \(token)")
        }
    }
    
    func parseOperation(_ token: Token, _ leftExpr: Value) throws -> Value {
        //print("parseOperation", token)
        switch token {
        case .annotationLiteral(let string): // «...» // attaches arbitrary contents to preceding node as metadata
            leftExpr.annotations.append(string)
            return leftExpr
        case .operatorName(value: let name, prefix: _, infix: let definition):
            if definition == nil { return try self.parseAtom(token)  }
            switch definition!.parseFunc {
            case .infix(let parseFunc), .postfix(let parseFunc):
                return try parseFunc(self, leftExpr, name, definition!)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in infix/postfix table.")
            }
        case .lineBreak: // TO DO: how best to process line breaks? // note: if line ends on prefix/infix operator, this will grab remaining operand from subsequent line; we may want to guard against this, or at least limit its scope of action to next line only
            var token = token
            while case .lineBreak = token { token = self.next() }
            return try self.parseOperation(token, leftExpr)
        case .endOfCode:
            throw SyntaxError("Expected an operand after the following code but found end of code instead: \(leftExpr)")
        default:
            throw SyntaxError("Invalid token after \(leftExpr): \(token)")
        }
    }
    
    // parseAtom and parseOperation start on the token they're given; parseExpression does not
    
    func parseExpression(_ token: Token, _ precedence: Int = 0) throws -> Value { // cursor should be on _preceding_ token when this is called
        //print("parseExpression reading:",token)
        var left = try self.parseAtom(token)
        //print("Parsed atom; now on \(self.this); next is:",self.peek(), "precedence (expression<next):", precedence, "<", self.peek().precedence)
        while precedence < self.peek().precedence { // TO DO:
            self.skipLineBreaks()
            left = try self.parseOperation(self.next(), left)
            //print(precedence,"<", self.peek().precedence)
        }
        //print("ended parseExpression on:",self.this)
        return left
    }
    
    // main
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        guard case .startOfCode = self.this else { throw SyntaxError("Expected start of code but found: \(self.this)") }
        var result = [Value]()
        do {
            while true {
                let token = self.next()
                if case .endOfCode = token { break } // note: can't parameterize Token as some cases have associated values
                result.append(try self.parseExpression(token))
                self.skipLineBreaks()
                //print("parsed top-level expr:", result.last!)
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

