//
//  parser.swift
//

// Pratt parser (enhanced recursive descent parser that supports operator fixity and associativity)


/* TO DO: each [non-comment/-disable] annotation should bind to an adjacent expression on same line (or to parent block/list/group if nothing else on that line); e.g. annotations on right-end of line should bind left, ignoring punctuation:
 
 
    to foo( «one-line summary of handler's purpose»
            arg1 as TYPE, «1st argument description»
            arg2 as TYPE «2nd argument description»
            ) returning TYPE { «result description»
        «/body code goes here»
    } «long documentation goes here»
    «#hashtags #go #here?»
 
 This is going to need some thought, particularly as parser should handle all annotations automatically, skipping/extracting them in peek()/next()'s skip loop and collecting in temporary list, then automatically binding to an AST Value [in parseExpression loop?]
 
 Also need to decide how to distinguish dev comment vs user doc vs disabled code vs section headings vs whatever other semantics users might want to apply. (Editor will want to provide menu options for inserting different types of annotations, and apply formatting+tooltips when pretty printing)
 */


// TO DO: how best to implement incremental parsing e.g. might do per-line parsing, with each Line keeping a count of any opening/closing { }, [ ], ( ), « » blocks and quotes, along with any other hints such as indentation and possible keywords; a block-level analyzer could then attempt to collate lines into balanced blocks, detecting both obvious imbalances (e.g. `{[}]`, `{[[]}`) and more subtle ones (e.g. `{[]{[]}`) and providing best guesses as to where the correction should be made (e.g. given equally indented blocks, `{}{{}{}` the unbalanced `{` is more likely to need the missing `}` inserted before the next `{}`, not at end of script [as a dumber parser would report]; looking for keywords that are commonly expected at top-level or within blocks may also provide hints as to when to discard previous tally as unbalanced and start a new one from top level); TBH, code editor only really needs to keep lines balanced during editing (and flag where imbalanced quotes/braces/etc are detected), and provide basic dictionary-based auto-suggest/-correct/-complete; when balanced, document can be parsed quite coarsely (either in full, or per top-level block); that just leaves the question of tooling for selecting and moving subnodes around, which again could probably be done with basic block balancing followed by a quick re-parse to validate (a really smart editor might try to be more helpful, e.g. ensuring dragging an item into a list literal either replaces an existing item or inserts a comma separator automatically, but not convinced that will really assist more than it irritates; after all, if user wants to assemble invalid code, they should)


// TO DO: all Value subclasses instantiated by Parser should be defined on a struct passed as optional argument to parser's initializer; this will allow parser to generate AST trees for multiple purposes: running, debugging, profiling, structure editing, optimizing, cross-compiling (Q. is it enough to provide an instantiable ASTNodes struct, or is it better to define ASTNodes as a protocol? be aware that all attributes need to conform to Value plus appropriate initializer, which is probably best done as `typealias ASTTextNode = Value & TextInterface`)



// TO DO: what about `parseIfBlock`, `parseIfGroup`, etc for use by custom parse funcs, e.g. `if EXPR BLOCK` operator (note, incidentally, that this could be defined as `if EXPR EXPR`, but that might be risky if `EXPR EXPR` is a special pattern, e.g. `documentFile 1` [shorthand for `documentFiles[1]`, or `documentFile at 1`, or whatever], or `WORD WORD` [invalid identifier sequence, indicative of quoted text body])

// TO DO: what about taking advantage of Markdown heading syntax in annotations (e.g. `«= SECTION =»` `«== SUBSECTION ==»`) to enable developer notes to better describe high-level program structure? (standardizes traditional ad-hoc customs for describing layout and allows code editor's pretty printer to apply literate formatting, as well as fast navigation around large scripts, code folding/executive summary, etc); also decide if developer annotations should be formally 'typed', e.g. `«TODO:…»`, or if they should just employ existing hashtags, e.g. `«#TODO…»` (hashtags have benefit of being open-ended); still need to decide how userdoc annotations are distinguished from other types of annotations (obviously we don't want to leak internal developer notes to end users should author use wrong coercion, so probably want to use `«…»` for private annotations and `«XXXX…»` for user-visible notes, where `XXXX` is concise but distinctive symbol/word that is unlikely to appear accidentally at start of other annotations, e.g. `«?…»`, where `?` denotes 'help' in both annotations and language syntax [e.g. `COMMAND()?` could put interpreter into exploratory/debug mode when that command is reached, allowing user to view/edit command's current arguments, call stack, target handler[s] documentation/definition, etc, then halt/resume execution when happy])

// TO DO: parser doesn't handle trailing line breaks in scripts yet (hopefully just needs .endOfCode to have its own precedence)

// TO DO: consider recognizing `NAME(ARGUMENTS) «?returning TYPE» BLOCK` pattern as named, unbound handler that optionally takes arguments and may declare return coercion, i.e. a standard closure (in which case `to`/`when` operators are effectively just binding agents, although exact implementation will differ as they won't create a closure for it); difference between this and BLOCK (`{…}`) is that latter is an unnamed closure that takes no arguments; this saves users having to declare and bind a handler before passing it as argument to a command, e.g. `sortList(listOfObjects, key:_(item){item.attributeToSortOn})` (e.g. in Python, either `def NAME(ARGUMENTS):BLOCK` statement or `lambda ARGUMENTS:EXPR` expression must be used); also note that this syntax forbids treating `COMMAND BLOCK` as a command whose last argument is trailing block (c.f. Swift)

// TO DO: parser needs to maintain line count and annotate AST values with file, line, and start+end indexes for use in error messages (non-AST values might also optionally be annotated during debug sessions, enabling introspection tools to determine runtime-created values' origins)



import Foundation


struct CodeRange {
    let start: String.Index
    let end: String.Index
}



class Parser {
    
    // TO DO: how do .lineBreak tokens interact with expression parsing? how suitable is recursive implementation for interactive per-line use? (or is better to use line analyzer - which doesn't generate AST, only line-balancing tallys - during editing, and only invoke parser when all tallys balance?)
    
    private let tokens: [TokenInfo]
    private var index = 0
    private var annotations = [TokenInfo]() // TO DO: parser needs to bind extracted annotations to AST nodes automatically (this may be easier once TokenInfo includes line numbers)
    
    init(_ tokens: [TokenInfo]) {
        self.tokens = tokens
    }
    
    // cursor
    
    var thisInfo: TokenInfo { return self.index < self.tokens.count ? self.tokens[self.index] : self.tokens.last! }
    
    var this: Token { return self.index < self.tokens.count ? self.tokens[self.index].coercion : .endOfCode }
    
    @discardableResult func next(ignoringLineBreaks: Bool = false) -> Token { // TO DO: rename `advance()` and return nothing (while returning a Token may seem convenient, it makes the sequence of operation harder to follow in parser code)
        self.index += 1
        var loop = true
        while loop && self.index < self.tokens.count {
            switch self.tokens[self.index].coercion {
            case .whitespace(_): self.index += 1
            case .lineBreak where ignoringLineBreaks: self.index += 1
            case .annotationLiteral(_):
                print("TO DO: reattach extracted annotation:", self.tokens[self.index])
                annotations.append(self.tokens[self.index])
                self.index += 1
            default: loop = false
            }
        }
        return self.this
    }
    
    func peek(ignoringLineBreaks: Bool = false) -> Token {
        var index = self.index + 1
        var loop = true
        while loop && index < self.tokens.count {
            switch self.tokens[index].coercion {
            case .whitespace(_), .annotationLiteral(_): index += 1
            case .lineBreak where ignoringLineBreaks: index += 1
            default: loop = false
            }
        }
        return index < self.tokens.count ? self.tokens[index].coercion : .endOfCode
    }
    
    //
    
    func readBlock() throws -> Block { // start on '{'
        guard case .blockLiteral = self.this else { throw InternalError("Parser.readBlock() should start on '{' but is on: \(self.this)") } // sanity check
        self.next(ignoringLineBreaks: true) // step over '{' to first expression
        var items = [Value]()
        // note: `if case`/`guard case` is awful: it can't take more than one .CASE and isn't a comparison operation so doesn't compose with Boolean tests, so there's no way to say 'if not .CASE then…' or 'if .THISCASE or .THATCASE then…'
        while true {
            if case .blockLiteralEnd = self.this { break }
            items.append(try self.parseExpression(ignoringLineBreaks: false))
            self.next() // advance to first token after expression, which should be either end of block or line break
            guard case .lineBreak = self.this else { break } // check for line break separator after expression
            // (note: if also allowing semicolons as an alternative to line breaks for separating expressions, with no obvious way to do an OR test we'd have to nest a second `guard case .semicolon = self.this else {break}` within the first)
            self.next(ignoringLineBreaks: true) // skip over line break[s] to start of next line
        }
        // make sure block has closing '}'
        guard case .blockLiteralEnd = self.this else { throw SyntaxError("Expected expression or end of block but found: \(self.this)") }
        return Block(items) // end on '}'
    }
    
    func readCommaDelimitedValues(_ isEndToken: ((Token) -> Bool)) throws -> [Value] { // e.g. `[EXPR,EXPR,EXPR]` // start on '('/'['
        var items = [Value]()
        // TO DO: could do with a sanity test here, but would need to pass an additional isBeginToken callback as there's no way to compare token directly (short of implementing `isCase()` method on it with big old switch block)
        self.next(ignoringLineBreaks: true) // step over '('/'[' or ','
        while !isEndToken(self.this) { // check for ')'/']'
            do {
                items.append(try self.parseExpression()) // this starts on first token of expression and ends on last
            } catch { // TO DO: get rid of this once parser reports error locations
                print(items)
                print("Failed to read item \(items.count+1):", error) // DEBUGGING
                throw error
            }
            self.next(ignoringLineBreaks: true) // move to next token, which should be ')'/']' or '/'
            // TO DO: what about annotations?
            guard case Token.itemSeparator = self.this else { break } // if it's a comma then read next item, else break
            self.next(ignoringLineBreaks: true) // step over ','
        }
        // make sure there's a closing ')'/']'
        guard isEndToken(self.this) else { throw SyntaxError("Unexpected code after item \(items.count) of \(items): \(self.this)") }
        return items // finish on ')'/']'
    }
    
    // token matching
    
    private func parseAtom(_ precedence: Int = 0) throws -> Value {
        let tokenInfo = self.thisInfo
        let token = tokenInfo.coercion
        let value: Value
        // TO DO: what about .endOfCode? can it occur here?
        switch token {
        case .listLiteral:      // `[…]` - an ordered collection (array) or key-value collection (dictionary)
            value = try List(self.readCommaDelimitedValues(isEndOfList))
        case .blockLiteral:     // `{…}`
            value = try self.readBlock()
        case .groupLiteral:     // `(…)` // precedence group (unlike a command's argument tuple, this must contain exactly 1 expression)
            // caution: don't use `(…,…,…)` as block-style sequence as it's already used as tuple syntax in commands and handlers (OTOH, if commands/handlers take a `{…,…,…}` record value as unary argument c.f. entoli, `(…,…,…)` could be used as block syntax wherever 'block' is *explicitly* allowed as argument coercion; however, anywhere else it must only work as precedence group, e.g. `(1+2)*3` but not `(foo,1+2)*3`, to avoid introducing potential gotchas)
            self.next(ignoringLineBreaks: true) // step over '('
            value = try self.parseExpression()
            self.next(ignoringLineBreaks: true) // step over ')'
            guard case .groupLiteralEnd = self.this else { throw SyntaxError("Expected end of precedence group, “)”, but found: \(self.this)") }
        case .textLiteral(value: let string):
            value = Text(string)
        case .identifier(value: let name, isQuoted: _): // found `NAME`
            if case Token.groupLiteral = self.peek() {  // check for an argument tuple; if found it's a command name, `NAME(…)`, else it's an identifier
                self.next() // advance cursor onto "("
                value = try Command(name, self.readCommaDelimitedValues(isEndOfGroup)) // read the argument tuple
            } else {
                value = Identifier(name)
            }
        case .number(value: let string): // TO DO: use Scalar
            value = Text(string)
            value.annotations.append(try Scalar(string)) // TO DO: annotation API
        case .operatorName(value: let name, prefix: let definition, infix: _) where definition != nil:
            switch definition!.parseFunc {
            case .atom(let parseFunc), .prefix(let parseFunc):
                // operator name is passed for convenience, though parsefunc could get .operatorToken itself
                value = try parseFunc(self, name, definition!) // note: this does not prevent custom parseFuncs reading/not reading next token[s]; thus the distinction between .atom and .prefix (or .infix and .suffix) is informative only; some parsefuncs may even deliberately support both, peeking ahead to determine whether or not a trailing operand is present and outputting the appropriate .atom/.prefix (or .infix/.suffix) Command (although this is frowned on as it means the parsefunc must supply custom commands names itself rather than using canonical name from operator definition, which isn't something [currently/ever?] supported by auto-documentation tools)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in atom/prefix table.")
            }
        case .endOfCode:
            throw SyntaxError("Expected an expression but found end of code instead.")
        default:
            throw SyntaxError("Expected an expression but found \(token)")
        }
        value.annotations.append(CodeRange(start: tokenInfo.start, end: self.thisInfo.end))
        return value
    } // important: this should always leave cursor on last token of expression
    
    private func parseOperation(_ leftExpr: Value) throws -> Value {
        let tokenInfo = self.thisInfo
        let token = tokenInfo.coercion
        let value: Value
        switch token {
        case .operatorName(value: let name, prefix: _, infix: let definition) where definition != nil:
            switch definition!.parseFunc {
            case .infix(let parseFunc), .postfix(let parseFunc):
                value = try parseFunc(self, leftExpr, name, definition!)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in infix/postfix table.")
            }
        case .endOfCode:
            throw SyntaxError("Expected an operand after the following code but found end of code instead: \(leftExpr)")
        default:
            throw SyntaxError("Invalid token after \(leftExpr): \(token)")
        }
        value.annotations.append(CodeRange(start: tokenInfo.start, end: self.thisInfo.end))
        return value
    } // important: this should always leave cursor on last token of expression
    
    
    func parseExpression(_ precedence: Int = 0, ignoringLineBreaks: Bool = false) throws -> Value { // cursor should be on _preceding_ token when this is called // TO DO: should this method be responsible for binding extracted annotations to adjacent Values?
        var left = try self.parseAtom()
        while precedence < self.peek(ignoringLineBreaks: ignoringLineBreaks).precedence { // TO DO:
            self.next(ignoringLineBreaks: ignoringLineBreaks) // TO DO: CHECK
            left = try self.parseOperation(left)
        }
        return left
    } // important: this should always leave cursor on last token of expression
    
    // main
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        guard case .startOfCode = self.this else { throw SyntaxError("Expected start of code but found: \(self.this)") }
        var result = [Value]()
        self.next(ignoringLineBreaks: true)
        do {
            while true {
                if case .endOfCode = self.this { break } // infernal uncomposable `if case` syntax
                result.append(try self.parseExpression())
                self.next(ignoringLineBreaks: false) // TO DO: check if an annotation can be first token after end of expression; if so, will need some extra checks here to parse and attach it to preceding expression
                // make sure there's a line break
                guard case .lineBreak = self.this else {
                    if case .endOfCode = self.this { break }
                    throw SyntaxError("Expected end of line but found: \(self.thisInfo)")
                }
                self.next(ignoringLineBreaks: true) // skip over line break[s]
            }
            guard case .endOfCode = self.next() else { throw SyntaxError("Expected end of code but found: \(self.this)") }
            return ScriptAST(result) // TBH, should swap this around so ScriptAST initializer takes code as argument and lexes and parses it
        } catch { // TO DO: delete once syntax errors provide decent debugging info
            print("Partially parsed script:", result) // DEBUG
            throw error
        }
    }
    
}

