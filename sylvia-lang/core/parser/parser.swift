//
//  parser.swift
//

// Pratt parser (enhanced recursive descent parser that supports operator fixity and associativity)


// TO DO: unparenthesized commands need to adjust their precedence depending on whether they are inside or outside an `of` operand, e.g. when parsing `get text of document 1`, `get` should have lower precedence than `of` whereas `document` should have higher precedence than `of`; how best to implement variable precedence as generic behavior that library-defined operators can customize? (requiring context-sensitive parsing is a royal pain for both developers and users, but unavoidable - at least in this use-case - but unavoidable if we want to keep AST/pure-command representations remotely readable/logical/supportable while allowing unparenthesized commands in operator-enabled code for readability/friendliness/ease-of-use); consider also mathematical code, e.g. how should `sin 30° ÷ 2` parse?


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


// TO DO: how practical to capture a bad token and continue parsing to see what comes next? (this might not involve full parser, just lexer with balancing counters); as extension to this, given an unrecognized/unsupported token pattern, what about delegating to a lookup table of client-supplied parsefuncs, e.g. `IDENTIFIER INTEGER` might be custom matched as syntactic shorthand for `IDENTIFIER at INTEGER`, e.g. `paragraph 1 of document 1` -> `paragraph at 1 of document at 1` (or `paragraph index 1 of document index 1` in AS longhand syntax); this wouldn't be quite as flexible as AS, e.g. `paragraph i` wouldn't work (since `i` is an identifier, the `at` selector form needs to be explicit to distinguish reliably from typo, plus weaker typing requires more explicit disambiguation by operator choice [c.f. Perl and Mac::Glue, where numbers and text could not be distinguished by datatype])


// TO DO: how best to implement incremental parsing e.g. might do per-line parsing, with each Line keeping a count of any opening/closing { }, [ ], ( ), « » blocks and quotes, along with any other hints such as indentation and possible keywords; a block-level analyzer could then attempt to collate lines into balanced blocks, detecting both obvious imbalances (e.g. `{[}]`, `{[[]}`) and more subtle ones (e.g. `{[]{[]}`) and providing best guesses as to where the correction should be made (e.g. given equally indented blocks, `{}{{}{}` the unbalanced `{` is more likely to need the missing `}` inserted before the next `{}`, not at end of script [as a dumber parser would report]; looking for keywords that are commonly expected at top-level or within blocks may also provide hints as to when to discard previous tally as unbalanced and start a new one from top level); TBH, code editor only really needs to keep lines balanced during editing (and flag where imbalanced quotes/braces/etc are detected), and provide basic dictionary-based auto-suggest/-correct/-complete; when balanced, document can be parsed quite coarsely (either in full, or per top-level block); that just leaves the question of tooling for selecting and moving subnodes around, which again could probably be done with basic block balancing followed by a quick re-parse to validate (a really smart editor might try to be more helpful, e.g. ensuring dragging an item into a list literal either replaces an existing item or inserts a comma separator automatically, but not convinced that will really assist more than it irritates; after all, if user wants to assemble invalid code, they should)


// TO DO: all Value subclasses instantiated by Parser should be defined on a struct passed as optional argument to parser's initializer; this will allow parser to generate AST trees for multiple purposes: running, debugging, profiling, structure editing, optimizing, cross-compiling (Q. is it enough to provide an instantiable ASTNodes struct, or is it better to define ASTNodes as a protocol? be aware that all attributes need to conform to Value plus appropriate initializer, which is probably best done as `typealias ASTTextNode = Value & TextInterface`)



// TO DO: what about `parseIfBlock`, `parseIfGroup`, etc for use by custom parse funcs, e.g. `if EXPR BLOCK` operator (note, incidentally, that this could be defined as `if EXPR EXPR`, but that might be risky if `EXPR EXPR` is a special pattern, e.g. `documentFile 1` [shorthand for `documentFiles[1]`, or `documentFile at 1`, or whatever], or `WORD WORD` [invalid identifier sequence, indicative of quoted text body])

// TO DO: what about taking advantage of Markdown heading syntax in annotations (e.g. `«= SECTION =»` `«== SUBSECTION ==»`) to enable developer notes to better describe high-level program structure? (standardizes traditional ad-hoc customs for describing layout and allows code editor's pretty printer to apply literate formatting, as well as fast navigation around large scripts, code folding/executive summary, etc); also decide if developer annotations should be formally 'typed', e.g. `«TODO:…»`, or if they should just employ existing hashtags, e.g. `«#TODO…»` (hashtags have benefit of being open-ended); still need to decide how userdoc annotations are distinguished from other types of annotations (obviously we don't want to leak internal developer notes to end users should author use wrong coercion, so probably want to use `«…»` for private annotations and `«XXXX…»` for user-visible notes, where `XXXX` is concise but distinctive symbol/word that is unlikely to appear accidentally at start of other annotations, e.g. `«?…»`, where `?` denotes 'help' in both annotations and language syntax [e.g. `COMMAND()?` could put interpreter into exploratory/debug mode when that command is reached, allowing user to view/edit command's current arguments, call stack, target handler[s] documentation/definition, etc, then halt/resume execution when happy])


// TO DO: consider recognizing `NAME(ARGUMENTS) «?returning TYPE» BLOCK` pattern as named, unbound handler that optionally takes arguments and may declare return coercion, i.e. a standard closure (in which case `to`/`when` operators are effectively just binding agents, although exact implementation will differ as they won't create a closure for it); difference between this and BLOCK (`{…}`) is that latter is an unnamed closure that takes no arguments; this saves users having to declare and bind a handler before passing it as argument to a command, e.g. `sortList(listOfObjects, key:_(item){item.attributeToSortOn})` (e.g. in Python, either `def NAME(ARGUMENTS):BLOCK` statement or `lambda ARGUMENTS:EXPR` expression must be used); also note that this syntax forbids treating `COMMAND BLOCK` as a command whose last argument is trailing block (c.f. Swift)

// TO DO: parser needs to maintain line count and annotate AST values with file, line, and start+end indexes for use in error messages (non-AST values might also optionally be annotated during debug sessions, enabling introspection tools to determine runtime-created values' origins)


// TO DO: if using `NAME:EXPR` for assignment as well as pair operators in argument lists and key-value lists, parser may need to output different Values according to context (StoreValue, LabelledArgument/LabelledParameter, KeyValuePair) as each has different evaluation rules (operator precedence should be higher than comma separator/linebreak, lower than everything else); alternatively, block and argument tuple contexts might apply different coercions to Pair (although that's not ideal in block context as coercions really shouldn't have side effects); in any case, parser will want to distinguish key-value list literals from ordered/unique lists so that it can annotate/use alternative value representation to use Swift Dictionary instead of Array for internal storage

// TO DO: `item -n of LIST` is not valid code as it's not clear if `-` is unary or binary operator; ideally, parser should use whitespace analysis to guess user's intention and parenthesize automatically (highlighting automatic changes for user to confirm/correct), but that should be implemented as callback API which throws 'ambiguous syntax' error by default but can be overridden with library-supplied code analyzers


// TO DO: going to need parameterized blocks for map, filter: `([LABEL:] IDENTIFIER [as TYPE],…) [returning TYPE] BLOCK`

// TO DO: considering `;` for PIPE operator (or should it be core punctuation?), where `A(a,b); B(c,d)` -> `B(A(a,b),c,d)`; what are challenges of that transform?

// TO DO: might consider `(NAME1,NAME2):EXPR` for multiple assignment (Q. how should this handle more/less items on RHS? not convinced it merits dedicated `REST…` syntax)

// TO DO: `@UID`, `#TAG`?

// TO DO: how should AST represent interpolated text literals, e.g. `“Hello, ««name»»!««return»»”`? (e.g. a thunk around `expand_text(TEXT_LITERAL)` command, a self-thunking Text subclass? [possible advantage of the latter is it can be passed around as a 'normal' Text value])

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
    
    var this: Token { return self.index < self.tokens.count ? self.tokens[self.index].token : .endOfCode }
    
    func peek(ignoringLineBreaks: Bool = false) -> Token {
        var index = self.index + 1
        var loop = true
        while loop && index < self.tokens.count {
            switch self.tokens[index].token {
            case .whitespace(_), .annotationLiteral(_): index += 1
            case .lineBreak where ignoringLineBreaks: index += 1
            default: loop = false
            }
        }
        return index < self.tokens.count ? self.tokens[index].token : .endOfCode
    }
    
    func advance(ignoringLineBreaks: Bool = false) {
        self.index += 1
        var loop = true
        while loop && self.index < self.tokens.count {
            switch self.tokens[self.index].token {
            case .whitespace(_): self.index += 1
            case .lineBreak where ignoringLineBreaks: self.index += 1
            case .annotationLiteral(_):
                //print("TO DO: reattach extracted annotation:", self.tokens[self.index])
                annotations.append(self.tokens[self.index])
                self.index += 1
            default: loop = false
            }
        }
    }
    
    //
    
    func readBlock() throws -> Block { // start on '{'
        guard case .blockLiteral = self.this else { throw InternalError("Parser.readBlock() should start on '{' but is on: \(self.this)") } // sanity check
        self.advance(ignoringLineBreaks: true) // step over '{' to first expression // TO DO: could do with knowing if linebreaks were skipped so that block can be annotated with formatting hints
        var items = [Value]()
        while true {
            if case .blockLiteralEnd = self.this { break }
            items.append(try self.parseExpression())
            self.advance(ignoringLineBreaks: false) // advance to first token after expression, which should be either end of block or line break
            switch self.this {
            case .lineBreak, .itemSeparator: self.advance(ignoringLineBreaks: true) // skip over optional comma separator and/or line break[s] to start of next line // TO DO: need to annotate preceding expression with formatting hints
            default: break
            } // check for line break separator after expression
        }
        // make sure block has closing '}'
        guard case .blockLiteralEnd = self.this else { throw SyntaxError("Expected expression or end of block but found: \(self.this)") }
        return Block(items) // end on '}'
    }
    
    func readCommaDelimitedValues(_ parseFunc: (() throws -> Value), _ isEndToken: ((Token) -> Bool)) throws -> [Value] { // e.g. `[EXPR,EXPR,EXPR]` // start on '('/'['
        var items = [Value]()
        // TO DO: could do with a sanity test here, but would need to pass an additional isBeginToken callback as there's no way to compare token directly (short of implementing `isCase()` method on it with big old switch block)
        self.advance(ignoringLineBreaks: true) // step over '('/'[' or ','
        while !isEndToken(self.this) { // check for ')'/']'
            do {
                items.append(try parseFunc()) // this starts on first token of expression and ends on last
            } catch { // TO DO: get rid of this once parser reports error locations
                print(items)
                print("Failed to read item \(items.count+1):", error) // DEBUGGING
                throw error
            }
            self.advance(ignoringLineBreaks: true) // move to next token, which should be ')'/']' or '/'
            guard case Token.itemSeparator = self.this else { break } // if it's a comma then read next item, else break
            self.advance(ignoringLineBreaks: true) // step over ','
        }
        // make sure there's a closing ')'/']'
        guard isEndToken(self.this) else {
            // TO DO: need to format items as partial list; right now it displays badly
            throw SyntaxError("Unexpected token after item \(items.count) of list: \(self.thisInfo)") // TO DO: need to pass source string + self.thisInfo to all SyntaxErrors so that it can display position of problem code
        }
        return items // finish on ')'/']'
    }
    
    // token matching
    
    private func parseAtom() throws -> Value {
        let tokenInfo = self.thisInfo
        let token = tokenInfo.token
        let value: Value
        switch token {
        case .listLiteral:      // `[…]` - an ordered collection (array) or key-value collection (dictionary)
            if case .pairSeparator = self.peek(ignoringLineBreaks: false) { // accept `[:]` as literal notation for empty record (key-value list)
                self.advance(ignoringLineBreaks: false)
                self.advance(ignoringLineBreaks: false)
                guard case .listLiteralEnd = self.this else {
                    throw SyntaxError("Expected end of empty record, “]”, but found: \(self.this)")
                }
                value = Record()
            } else if case .listLiteralEnd = self.peek(ignoringLineBreaks: false) { // found `[]` (empty list)
                self.advance(ignoringLineBreaks: false)
                value = List()
            } else { // found non-empty list/record, so need to start parsing it to determine which it is
                var dict = [RecordKey:Value]() // optimistically populating a dictionary as side-effect is not beautiful, but it gets the job done
                let items: [Value] = try self.readCommaDelimitedValues({ () throws -> Value in
                    if case .groupLiteral = self.this {
                        return try self.parseExpression() // list item is parenthesized, so *cannot* be a  Record field (i.e. Pairs can appear in *List* literals as long as they're parenthesized, e.g. `[("foo":1)]`)
                    } else {
                        let item = try self.parseExpression()
                        if let pair = item as? Pair { // found unparenethesized Pair (i.e. Record field), though still need to check key is valid type
                            guard let key = (pair.key as? Text)?.recordKey ?? (pair.key as? Tag)?.recordKey else { // e.g. `["foo":1]`, `[#bar:2]`
                                throw SyntaxError("Not a valid record key (expected string or tag but found \(pair.key.nominalType)): \(pair)")
                            }
                            dict[key] = pair.value
                        }
                        return item
                    }
                }, isEndOfList)
                if dict.count == 0 { // no items are unparenthesized Pairs, so it's a List
                    value = List(items)
                } else if dict.count == items.count { // all items are Pairs with literal keys, so create a Record with internal `[RecordKey:Value]` storage
                    value = Record(dict)
                } else {
                    throw SyntaxError("Not a valid record (\(items.count - dict.count) missing/duplicate key[s]): \(items)")
                }
            }
        case .blockLiteral:     // `{…}`
            value = try self.readBlock()
        case .groupLiteral:     // `(…)` // precedence group (unlike a command's argument tuple, this must contain exactly 1 expression)
            // caution: don't use `(…,…,…)` as block-style sequence as it's already used as tuple syntax in commands and handlers (OTOH, if commands/handlers take a `{…,…,…}` record value as unary argument c.f. entoli, `(…,…,…)` could be used as block syntax wherever 'block' is *explicitly* allowed as argument coercion; however, anywhere else it must only work as precedence group, e.g. `(1+2)*3` but not `(foo,1+2)*3`, to avoid introducing potential gotchas)
            self.advance(ignoringLineBreaks: true) // step over '('
            value = try self.parseExpression()
            // TO DO: need to annotate value in order to preserve elective parens when pretty printing; also to determine if a list literal represents a table or a list of arbitrary pairs (e.g. ["foo":1] = Record, [("foo":1)] = List)
            self.advance(ignoringLineBreaks: true) // step over ')'
            guard case .groupLiteralEnd = self.this else { throw SyntaxError("Expected end of precedence group, “)”, but found: \(self.this)") }
        case .textLiteral(value: let string):
            value = Text(string)
        case .tagLiteral(value: let string):
            value = Tag(string)
        case .identifier(value: let name, isQuoted: _): // found `NAME`
            // TO DO:
            // 1. how safe to accept a single unparenthesized argument? e.g. `get file 1` = `get (file (1))`
            // 2. how practical to allow multiple unparenthesized labeled arguments, e.g. `move FOO to: BAR replacing: ASK`?
            // 3. how to eliminate distinction between NAME and argless COMMAND? (as in entoli, NAME would be an 'argless command' that returns a stored value)
            // if all three questions can be successfully answered, we can define syntax rules for achieving very-close-to-AS-syntax in both application- and user-defined commands
            switch self.peek(ignoringLineBreaks: false) {  // is there an argument tuple after NAME (i.e. is it a command name or identifier?)
            case .groupLiteral: // read zero or more parenthesized arguments
                // TO DO: call parseRecord/parseTuple to read arg list; this should know how to read Pairs (this is context-sensitive: pair labels that lexer marks as .operator must be converted to .identifier)
                self.advance(ignoringLineBreaks: false) // advance cursor onto "("
                value = try Command(name, self.readCommaDelimitedValues({try self.parseExpression()}, isEndOfGroup)) // read the argument tuple // TO DO: tuples need their own parsefunc that knows how to handle labels that are represented as .operator tokens (i.e. for each item, if it starts with an .operator, check if next token is .pairSeparator and convert the operator to identifier if it is)
            /*
            case .listLiteral, .textLiteral, .tagLiteral, .identifier, .number: // read single unparenthesized argument (note: a .blockLiteral argument must be parenthesized to avoid ambiguity in `PREFIX_OPERATOR IDENTIFIER BLOCK` pattern commonly used by flow control)
                self.advance(ignoringLineBreaks: false)
                value = try Command(name, [self.parseAtom()])
             */
            default:
                value = Identifier(name)
            }
        case .number(value: let string, scalar: let scalar):
            let text = Text(string)
            text.scalar = scalar
            value = text
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
        value.annotations[codeAnnotation] = CodeRange(start: tokenInfo.start, end: self.thisInfo.end)
        return value
    } // important: this should always leave cursor on last token of expression
    
    private func parseOperation(_ leftExpr: Value) throws -> Value {
        let tokenInfo = self.thisInfo
        let token = tokenInfo.token
        let value: Value
        switch token {
        case .operatorName(value: let name, prefix: _, infix: let definition) where definition != nil:
            switch definition!.parseFunc {
            case .infix(let parseFunc), .postfix(let parseFunc):
                value = try parseFunc(self, leftExpr, name, definition!)
            default: // this should never happen
                throw InternalError("OperatorRegistry bug: \(String(describing: definition)) found in infix/postfix table.")
            }
        case .pairSeparator:
            self.advance(ignoringLineBreaks: false) // skip over ":"
            value = try Pair(leftExpr, self.parseExpression(token.precedence - 1)) // pairs are right-associative
        case .endOfCode:
            throw SyntaxError("Expected an operand after the following code but found end of code instead: \(leftExpr)")
        default:
            throw SyntaxError("Invalid token after \(leftExpr): \(token)")
        }
        value.annotations[codeAnnotation] = CodeRange(start: tokenInfo.start, end: self.thisInfo.end)
        return value
    } // important: this should always leave cursor on last token of expression
    
    
    func parseExpression(_ precedence: Int = 0) throws -> Value { // TO DO: should this method be responsible for binding extracted annotations to adjacent Values?
        var left = try self.parseAtom()
        while precedence < self.peek(ignoringLineBreaks: false).precedence { // note: this disallows line breaks between operands and operator
            self.advance(ignoringLineBreaks: false)
            left = try self.parseOperation(left)
        }
        return left
    } // important: this should always leave cursor on last token of expression
    
    // main
    
    func parseScript() throws -> ScriptAST { // ASTDocument? (see above notes about defining standard ASTNode protocols); also provide public API for parsing a single data structure (c.f. JSON deserialization)
        guard case .startOfCode = self.this else { throw SyntaxError("Expected start of code but found: \(self.this)") }
        var result = [Value]()
        self.advance(ignoringLineBreaks: true)
        do {
            if !isEndOfCode(self.this) { // skip if no expressions found (i.e. whitespace and/or annotations only)
                readLine: while true {
                    result.append(try self.parseExpression())
                    self.advance(ignoringLineBreaks: false) // move to first token after expression
                    switch self.this {
                    case .lineBreak, .itemSeparator:
                        self.advance(ignoringLineBreaks: true) // skip over comma separator and/or line break[s]
                    case .endOfCode:
                        break readLine
                    default:
                        throw SyntaxError("Expected end of line but found: \(self.thisInfo)")
                    }
                }
                guard case .endOfCode = self.this else { throw SyntaxError("Expected end of code but found: \(self.this)") }
            }
            return ScriptAST(result) // TBH, should swap this around so ScriptAST initializer takes code as argument and lexes and parses it
        } catch { // TO DO: delete once syntax errors provide decent debugging info
            print("[DEBUG] Partially parsed script:", result.map{$0.description}.joined(separator: " "))
            throw error
        }
    }
    
}

