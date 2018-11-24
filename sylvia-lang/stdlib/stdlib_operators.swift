//
//  stdlib_operators.swift
//

// note: all operators are just syntactic sugar over existing commands, e.g. `1+2` -> `add(1,2)`; this simplifies implementation, integrates with existing documentation generators, and enables easy metaprogramming (a parsed program [AST] is just lots of nested/sequential Commands and other Values, which parser and pretty printer can trivally convert between operator+command syntax and command-only syntax)

// TO DO: pretty sure operators should never be maskable (does this mean corresponding commands must also be non-maskable, or should operator capture that command's handler [or at least its scope] directly? problem with latter approach is that it breaks transforms between operator-sugared syntax and command-only [Lisp-like] syntax, which should both evaluate exactly the same [i.e. operators are purely *syntactic sugar* on top of existing commands])


// TO DO: need to decide policy on operator synonyms, particularly for symbol operators (which must map to word-based names in Swift code): either all operator symbols must map to word-based command names, or handler code generator needs option to specify both symbol name and Swift func name


/******************************************************************************/
// custom parse funcs

func parseNothingOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    return noValue
}


func parseNumericSignOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value { // `SIGN NUMBER` tokens -> `SIGNED_NUMBER` value
    if numericSigns.contains(operatorName), case .number(value: let number) = parser.peek() {
        parser.next()
        return Text(operatorName + number) // TO DO: cache numeric (Scalar) representation
    } else {
        parser.next()
        return Command(definition.command ?? operatorName, leftOperand: try parser.parseExpression(definition.precedence))
    }
}


// parse prefix operator with two right-hand operands, where 2nd operand must be a block (e.g. conditional and loop operators)

func parseExpressionAndBlockOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    
    
    // TO DO: what about expr type? e.g. in loops and conditionals, any expression that evaluates to true/false (with some exceptions, e.g. blocks should probably be disallowed, and silliness such as `if to HANDLER(){} {}` would ideally be discouraged); Q. what about insisting that opening brace appear on same line as [end of] EXPR - e.g. `if EXPR { LF …` but not `if EXPR LF {…` - in order to reduce room for ambiguous-looking code [see .linebreak discussion in general])
    parser.next()
    let expr = try parser.parseExpression(definition.precedence)
    // 2nd operand is required to be a block to avoid syntactic ambiguity (including token patterns such as `WORD WORD` that per-line parsing can use to distinguish probable quoted text from probable code)
    parser.next()
    let block = try parser.parseExpression(definition.precedence) // T|O DO: implement Parser.parseIfBlock, which returns nil if non-block is found, giving caller choice of what to do next [this is preferable to throwing SyntaxError, as errors occuring while parsing contents of block aren't trivially distinguished from error raised when expected block isn't found])
    // TO DO: how best to support 'code' formatting style in error messages? (one option is to treat all error strings as Markdown, and format/escape interpolated values when inserting; may be best to leave this until native 'tagged' text interpolation is implemented, then allow that to be used when constructing error messages in both native and Swift code)
    if !(block is Block) { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found: \(block)") } // TO DO: long code needs elided for readability
    return Command(definition.command ?? operatorName, leftOperand: expr, rightOperand: block)
}


func parseHandlerConstructorOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    // TO DO: handler constructors should use dedicated parsefuncs to read handler signature (we need individual parsefuncs for argument, parameter, and interface signatures; once they're implemented we can call `parseCallableSignature` parsefunc here; for now just require a command)
    parser.next() // step over 'to'/'when'
    let expr = try parser.parseExpression() // read handler signature
    // TO DO: better to use toHandlerSignature coercion here, as it may be a command [if returnType not specified] or it may be a `returning` operator (Q. how should `returning`, which ought to map to command `returning(name(params),returnType)`, produce a signature? on parsing or eval?)
    guard let signature = expr as? Command else { throw SyntaxError("Expected a handler signature after `\(operatorName)`, but found: \(expr)") } // TO DO: as above
    guard case .blockLiteral = parser.peek() else { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found \(parser.this)") }
    parser.next()
    let block = try parser.parseExpression() // TO DO: as above
    if !(block is Block) { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found \(type(of:block)): \(block)") } // TO DO: ditto
    return Command(definition.command ?? operatorName, [Text(signature.name), List(signature.arguments.map{Text(($0 as! Identifier).name)}), asAnything, block]) // kludges; TO DO: parseSignature should ensure all parameters and return type are declared correctly (there will be limits to what can be checked at parse time, e.g. `foo(arg as TYPE1) returning TYPE2` signature has no way of knowing if TYPE1 and TYPE2 are actually Coercions or some other Value type - that can only be determined when script is run [although it might be worth doing a superficial check once script's top-level declarations are all available to introspect, and note which ones can/can't be type-checked without running the script; this will be a particular issue if users use existing 'command' handlers to define their own coercions [it might even be an idea to have a separate CoercionHandler that can make hard guarantees about idempotency, side-effects, and halting - e.g. by only allowing other coercion values/coercion commands to be used within handler body, with hard limits on recursion depth in cases where coercions are used, say, to verify XML/JSON/etc data structures received by web interfaces]])
}


/******************************************************************************/
// operator parsing tables (these supply Pratt parser with parsefuncs to read library-defined operator syntax, along with binding precedence and any synonyms)

// how best to define/auto-generate operator tables? (custom parse funcs will need to be written in Swift, but everything else can be done natively via FFILib; it just needs a suitable command/operator syntax for declaring new operators [e.g. compare how Swift does it])


//  (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName]) // note: higher precedence binds more tightly than lower

let stdlib_operators: [OperatorDefinition] = [
    
    // TO DO: for each definition consider using the first word-based name found as the corresponding command/handler name (in the case of symbol-based operator names where the symbol is the canonical name, the word-based name would appear first in the alias list)
    
    // TO DO: we need word-based aliases for symbol operators, partly to use as primitive func names but also to support dictation and help search; easiest solution would be to require all symbol operators provide at least one word-based alias, and if canonical name is symbol then the first word in aliases list is used as canonical word name (this does leave question of whether underlying handlers should use symbol or word name; if symbol, it avoids additional namespace pollution; if name, it's self-descriptive)
    
    
    // TO DO: need a policy on aliases that should behave as if added to namespace vs those that really just exist for search/translation/voice input
    
    
    // TO DO: precedence of `A as B`?
    ("as", 80, .infix(parseInfixOperator), [], command: nil),

    
    // TO DO: restructure OperatorDefinition as enum, e.g. .infix("^", …)?
    
    ("^",   500, .infix(parseRightInfixOperator), ["exponent"], command: nil),
    
    // TO DO: should prefix `+` and `-` operators peek at next token and, if it's an unsigned .number, combine them and return a signed numeric value?
    ("+",   490, .prefix(parseNumericSignOperator), [], command: "positive"),
    ("-",   490, .prefix(parseNumericSignOperator), [], command: "negative"),
    
    ("×",   480, .infix(parseInfixOperator),      ["*"], command: "multiply"),
    ("÷",   480, .infix(parseInfixOperator),      ["/"], command: "divide"),
    
    ("div", 480, .infix(parseInfixOperator),      ["//", "divideKeepingWhole"], command: "integerDivision"), // "//" = Python div operator
    ("mod", 480, .infix(parseInfixOperator),      ["%", "divideKeepingFraction"], command: "modulus"), // note: if using `%` as a quantity unit (e.g. "100%"), need to make sure it won't be confused for modulus operator (one option is to define it as a postfix operator, which is one way to implement general quantity support [although this approach could get hairy when defining lots of postfix ops with common names like `meters`, `mm`; as a syntactic rule of thumb, it's safer to use coercions to convert to/from/between quantities, as that only has to define one type handler for each unit category: `length(units,min,max)`, `weight(…)`, `volume(…)`, etc])
    
    ("+",   470, .infix(parseInfixOperator),      ["plus"], command: "add"),
    ("-",   470, .infix(parseInfixOperator),      ["minus"], command: "subtract"),
    
    // math comparison
    ("<",  400, .infix(parseInfixOperator), [], command: "isLessThan"),
    ("<=", 400, .infix(parseInfixOperator), ["≤"], command: "isLessThanOrEqualTo"),
    ("==", 400, .infix(parseInfixOperator), [], command: "isEqualTo"),    // TO DO: for this exercise we'll stick to traditional C/Python-style syntax, but need to explore using `=` for equality tests (c.f. AppleScript)
    ("!=", 400, .infix(parseInfixOperator), ["≠"], command: "isNotEqualTo"),
    (">",  400, .infix(parseInfixOperator), [], command: "isGreaterThan"),
    (">=", 400, .infix(parseInfixOperator), ["≥"], command: "isGreaterThanOrEqualTo"),
    
    // text/list comparison (c.f. Perl scalar operators); TO DO: when comparing lists, should `A eq B as list(TYPE)` be required? what about text comparisons in general? (e.g. `A isSameAs B as caseSensitiveText`; other considerations: would it be wise to have `considering(TYPE){…}` that supplies default type for all comparison ops within its scope? If so, should it also apply to handlers called within that scope, and if so, how to do it safely? In AppleScript, considering/ignoring blocks implicitly affect all handlers called within that scope, causing handlers that don't explicitly set their own considering/ignoring flags to behave unpredictably; this could probably be covered by same 'requirements' ('capabilities'?) flags used to specify erroring, envs, pipes, and other external connections, side-effects, etc; thus default behavior would be for a handler to ignore command scope's considering/ignoring options unless it has `considersAndIgnores` in its capababilities list
    ("lt", 400, .infix(parseInfixOperator), ["isBefore"], command: nil),
    ("le", 400, .infix(parseInfixOperator), ["isNotBefore"], command: nil),
    ("eq", 400, .infix(parseInfixOperator), ["isSameAs"], command: nil),
    ("ne", 400, .infix(parseInfixOperator), ["isNotSameAs"], command: nil),
    ("gt", 400, .infix(parseInfixOperator), ["isAfter"], command: nil),
    ("ge", 400, .infix(parseInfixOperator), ["isNotAfter"], command: nil),
    
    // identity comparison
//    ("isSameObjectAs",  400, .infix(parseInfixOperator), [], command: nil), // compare object IDs
    ("isOfType",        400, .infix(parseInfixOperator), [], command: nil), // try coercing value to specified type and return 'true' if it succeeds or 'false' if it fails (an extra trick is to cache successful Coercions within the value, allowing subsequent tests to compare coercion objects instead of coercing the value itself, though of course this cache will be invalidated if the value is mutated) // note: there is difference between using coercions to test type suitability ('protocol-ness') of a Value vs checking its canonical type (e.g. `type of someValue == text`); allowing the latter may prove troublesome (novice users tend to check canonical type for equality when they should just check compatibility), so will need more thought (maybe use `EXPR isOfExactType TYPE`/`exactTypeOf EXPR`); plus it all gets extra thorny when values being checked are blocks, thunks, references, etc (should they be evaled and the result checked [which can cause issues where expression has side-effects or its result is non-idempotent], or should their current type [`codeBlock`, `lazyValue`, `reference`] be used? [note: AppleScript uses the former approach in an effort to appear simple and transparent to users, and frequently ends up causing confusion instead])
    
    // assignment
    // TO DO: if using NAME:VALUE for general assignment, we'll have to rely on coercions to specify read/write, e.g. `foo: 1 as editable(number)`, or else use `[let|var] NAME:VALUE`; using coercions is arguably better as the same syntax then works for handler signatures, allowing handler to indicate if it shares caller's argument value (c.f. pass-by-reference) or makes its own copy if needed (c.f. pass-by-value) (in keeping with existing read-only-by-default assignment policy, the latter behavior would be default and the former behavior explicitly requested using `EXPR as editable(…)`, or maybe even make `editable an atom/prefix operator for cleaner syntax, e.g. `EXPR as editable`, `EXPR as editable text`, etc, `EXPR as editable list(text)`); if we can be really sneaky, `A of B` operator could work by passing B as first argument to A, e.g. `EXPR as editable list of text`, `EXPR as editable list (max:10) of text`
    
    // TO DO: colon should be base punctuation
    (":", 2, .infix(parseInfixOperator), [], command: nil), // assignment (Q. how best to distinguish read-only vs read-write? could probably use colons for constants and `=` for variables, but will need to confirm that colons will still work okay when used in key-value lists and labeled arguments/parameters); another option is to avoid `=` completely (as mistyping `a==b` as `a=b` is a common cause of bugs, especially when it's also legal as an expression) and use e.g. `:=` for assignment and `==` for comparison
    
    ("&", 450, .infix(parseInfixOperator), [], command: "joinValues"), // TO DO: should this accept optional `as` clause for specifying which type to force both operands to before joining (e.g. `A & B as list(text)`); and, if so, how should constraints be applied? (ditto for text/list comparison operators)
    
    
    // Boolean // TO DO: best to uppercase these operator names to avoid misuse by novices who use them as English conjunctions instead of logic operators?
    ("NOT", 100, .prefix(parsePrefixOperator), [], command: nil),
    ("AND",  98, .infix(parseInfixOperator),   [], command: nil),
    ("XOR",  96, .infix(parseInfixOperator),   [], command: nil),
    ("OR",   94, .infix(parseInfixOperator),   [], command: nil),
    
    // key constants
    ("nothing", 0, .atom(parseNothingOperator), ["Ø"], command: nil),
    
    // define handlers
    ("to",   0, .prefix(parseHandlerConstructorOperator), [], command: "defineCommandHandler"), // TO DO: should aliases redeclare canonical name?
    ("when", 0, .prefix(parseHandlerConstructorOperator), [], command: "defineEventHandler"),
    
    // flow control
    ("if",          10, .prefix(parseExpressionAndBlockOperator), [], command: "testIf"),
    ("repeat",      10, .prefix(parseExpressionAndBlockOperator), [], command: "repeatTimes"),
    ("while",       10, .prefix(parseExpressionAndBlockOperator), [], command: "repeatWhile"),
    ("else",         5, .infix(parseInfixOperator), [], command: nil),
    ("catching",     4, .infix(parseInfixOperator), [], command: nil),
    
    // TO DO: don't really want to support a `for NAME in EXPR BLOCK` operator as syntax isn't consistent with `OPERATOR EXPR BLOCK` syntax used by other operators; what about supporting `(NAME,…) BLOCK` syntax for lambdas (unnamed callables)? how practical is that? (it likely rules out using `COMMAND BLOCK` pattern to denote a command with trailing block argument [c.f. Swift], but not a huge fan of that anyway [in Swift, `OPERATOR EXPR BLOCK` and `IDENTIFIER TUPLE BLOCK` are frustratingly inconsistent - two incompatible syntaxes for essentially the same job])
    //
    // e.g. `COMMAND(ARG,{…})` vs `COMMAND(ARG,(PARAM){…})` aren't fundamentally bad syntaxes, although where to put `returning` clause when indicating typed inputs/output; Q. should `to SIGNATURE BLOCK` syntax be redefined as `to NAME PARAMETERIZED_BLOCK`? (it would be nice to have a single consistent syntax for named and unnamed callables, though does raise questions about where capability flags should go)
    
]



