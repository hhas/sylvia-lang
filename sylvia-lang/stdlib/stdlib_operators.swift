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
    if numericSigns.contains(operatorName), case .number(value: let number, _) = parser.peek() {
        parser.advance()
        return Text(operatorName + number) // TO DO: cache numeric (Scalar) representation
    } else {
        parser.advance()
        return Command(definition.handlerName ?? operatorName, leftOperand: try parser.parseExpression(definition.precedence))
    }
}



func handlerConstructorOperatorParser(_ isEventHandler: Bool) -> ParseFunc.Prefix { // used by `to`/`when` operators
    return { (_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value in
        parser.advance() // step over 'to'/'when'
        
        // signature is of form `NAME([LABEL:]IDENTIFIER [as COERCION],…) [returning COERCION]`; note that all coercions are optional, as are labels (Q. if no label is given, should the identifier be usable as label or should argument be positional only? conversely, when labels are given, arguments are not obliged to use them and will be matched positionally; commands should only _need_ to use labels to disambiguate omitted arguments when matching up to optional parameters)
        
        let expr = try parser.parseExpression() // read handler signature // TO DO: handler constructors should use dedicated parsefuncs to read handler signature (we need individual parsefuncs for argument, parameter, and interface signatures; once they're implemented we can call `parseCallableSignature` parsefunc here; for now just take a Command containing handler and parameter names and pull it apart here, with hardcoded parameter and return types) // Q. better to use toHandlerSignature coercion here, as it may be a command [if returnType not specified] or it may be a `returning` operator? (Q. how should `returning`, which ought to map to command `returning(name(params),returnType)`, produce a signature? on parsing or eval?)
        guard let signature = expr as? Command else { throw SyntaxError("Expected a handler signature after `\(operatorName)`, but found: \(expr)") }
        let parameters = signature.arguments.map{Text(($0 as! Identifier).name)}
        let returnType = asAnything
        
        guard case .blockLiteral = parser.peek() else { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found \(parser.this)") }
        parser.advance()
        let action = try parser.parseExpression() // TO DO: as above
        if !(action is Block) { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found \(type(of:action)): \(action)") } // TO DO: ditto
        
        // TO DO: parseSignature should ensure all parameters and return coercion are declared correctly (there will be limits to what can be checked at parse time, e.g. `foo(arg as TYPE1) returning TYPE2` signature has no way of knowing if TYPE1 and TYPE2 are actually Coercions or some other Value coercion - that can only be determined when script is run [although it might be worth doing a superficial check once script's top-level declarations are all available to introspect, and note which ones can/can't be coercion-checked without running the script; this will be a particular issue if users use existing 'command' handlers to define their own coercions [it might even be an idea to have a separate CoercionHandler that can make hard guarantees about idempotency, side-effects, and halting - e.g. by only allowing other coercion values/coercion commands to be used within handler body, with hard limits on recursion depth in cases where coercions are used, say, to verify XML/JSON/etc data structures received by web interfaces]])
        let command = Command(definition.handlerName ?? operatorName,
                              [Text(signature.name), List(parameters), returnType, action, isEventHandler ? trueValue : falseValue])
        command.annotations[operatorAnnotation] = (operatorName: operatorName, definition: definition) // TO DO: error messages should render this Command using its operator syntax
        return command
    }
}

let parseCommandHandlerConstructorOperator = handlerConstructorOperatorParser(false)
let parseEventHandlerConstructorOperator = handlerConstructorOperatorParser(true)


/******************************************************************************/
// operator parsing tables (these supply Pratt parser with parsefuncs to read library-defined operator syntax, along with binding precedence and any synonyms)

// how best to define/auto-generate operator tables? (custom parse funcs will need to be written in Swift, but everything else can be done natively via swiftlib; it just needs a suitable command/operator syntax for declaring new operators [e.g. compare how Swift does it])

// TO DO: for each definition consider using the first word-based name found as the corresponding command/handler name (in the case of symbol-based operator names where the symbol is the canonical name, the word-based name would appear first in the alias list)

// TO DO: we need word-based aliases for symbol operators, partly to use as primitive func names but also to support dictation and help search; easiest solution would be to require all symbol operators provide at least one word-based alias, and if canonical name is symbol then the first word in aliases list is used as canonical word name (this does leave question of whether underlying handlers should use symbol or word name; if symbol, it avoids additional namespace pollution; if name, it's self-descriptive)


// TO DO: need a policy on aliases that should behave as if added to namespace vs those that really just exist for search/translation/voice input



//  (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName], handlerName: String?) // note: higher precedence binds more tightly than lower

let stdlib_operators: [OperatorDefinition] = [

    
    // TO DO: restructure OperatorDefinition as enum, e.g. .infix("^", …)?
    
    
    // TO DO: how to minimize naming clashes between underlying command names and user code (users will generally go by operator name, which may or may not be same as )
    
    // TO DO: generate via sylvia-gen-bridge.py (Q. how best to describe syntax in requirements?)
    
    ("^",   500, .infix(parseRightInfixOperator), ["exponent"], nil),
    
    // unary +/- must bind tighter than `of`, `at`, etc
    ("+",   2000, .prefix(parseNumericSignOperator), [], "positive"),
    ("-",   2000, .prefix(parseNumericSignOperator), [], "negative"),
    
    ("×",   480, .infix(parseInfixOperator),      ["*"], nil),
    ("÷",   480, .infix(parseInfixOperator),      ["/"], nil),
    
    ("div", 480, .infix(parseInfixOperator),      ["//", "divide_keeping_whole"], "integer_division"), // "//" = Python div operator
    ("mod", 480, .infix(parseInfixOperator),      ["%", "divide_keeping_fraction"], "modulus"), // note: if using `%` as a quantity unit (e.g. "100%"), need to make sure it won't be confused for modulus operator (one option is to define it as a postfix operator, which is one way to implement general quantity support [although this approach could get hairy when defining lots of postfix ops with common names like `meters`, `mm`; as a syntactic rule of thumb, it's safer to use coercions to convert to/from/between quantities, as that only has to define one coercion handler for each unit category: `length(units,min,max)`, `weight(…)`, `volume(…)`, etc])
    
    ("+",   470, .infix(parseInfixOperator),      ["plus"], nil),
    ("-",   470, .infix(parseInfixOperator),      ["minus"], nil),
    
    // math comparison
    ("<",  400, .infix(parseInfixOperator), [], nil),
    ("<=", 400, .infix(parseInfixOperator), ["≤"], nil),
    ("==", 400, .infix(parseInfixOperator), [], nil),    // TO DO: for this exercise we'll stick to traditional C/Python-style syntax, but need to explore using `=` for equality tests (c.f. AppleScript)
    ("!=", 400, .infix(parseInfixOperator), ["≠"], nil),
    (">",  400, .infix(parseInfixOperator), [], nil),
    (">=", 400, .infix(parseInfixOperator), ["≥"], nil),
    
    // text/list comparison (c.f. Perl scalar operators); TO DO: when comparing lists, should `A eq B as list(TYPE)` be required? what about text comparisons in general? (e.g. `A isSameAs B as caseSensitiveText`; other considerations: would it be wise to have `considering(TYPE){…}` that supplies default coercion for all comparison ops within its scope? If so, should it also apply to handlers called within that scope, and if so, how to do it safely? In AppleScript, considering/ignoring blocks implicitly affect all handlers called within that scope, causing handlers that don't explicitly set their own considering/ignoring flags to behave unpredictably; this could probably be covered by same 'requirements' ('capabilities'?) flags used to specify erroring, envs, pipes, and other external connections, side-effects, etc; thus default behavior would be for a handler to ignore command scope's considering/ignoring options unless it has `considersAndIgnores` in its capababilities list
    ("lt", 400, .infix(parseInfixOperator), ["is_before"], nil),
    ("le", 400, .infix(parseInfixOperator), ["is_not_before"], nil),
    ("eq", 400, .infix(parseInfixOperator), ["is_same_as"], nil),
    ("ne", 400, .infix(parseInfixOperator), ["is_not_same_as"], nil),
    ("gt", 400, .infix(parseInfixOperator), ["is_after"], nil),
    ("ge", 400, .infix(parseInfixOperator), ["is_not_after"], nil),
    
    // identity comparison
//    ("isSameObjectAs",  400, .infix(parseInfixOperator), [], nil), // compare object IDs
    ("is_a",              400, .infix(parseInfixOperator), [], nil), // try coercing value to specified coercion and return 'true' if it succeeds
    
    // assignment
    // TO DO: if using NAME:VALUE for general assignment, we'll have to rely on coercions to specify read/write, e.g. `foo: 1 as editable(number)`, or else use `[let|var] NAME:VALUE`; using coercions is arguably better as the same syntax then works for handler signatures, allowing handler to indicate if it shares caller's argument value (c.f. pass-by-reference) or makes its own copy if needed (c.f. pass-by-value) (in keeping with existing read-only-by-default assignment policy, the latter behavior would be default and the former behavior explicitly requested using `EXPR as editable(…)`, or maybe even make `editable an atom/prefix operator for cleaner syntax, e.g. `EXPR as editable`, `EXPR as editable text`, etc, `EXPR as editable list(text)`); if we can be really sneaky, `A of B` operator could work by passing B as first argument to A, e.g. `EXPR as editable list of text`, `EXPR as editable list (max:10) of text`
    
    // TO DO: colon should be base punctuation
//    (":", 2, .infix(parseInfixOperator), [], nil), // assignment (Q. how best to distinguish read-only vs read-write? could probably use colons for constants and `=` for variables, but will need to confirm that colons will still work okay when used in key-value lists and labeled arguments/parameters); another option is to avoid `=` completely (as mistyping `a==b` as `a=b` is a common cause of bugs, especially when it's also legal as an expression) and use e.g. `:=` for assignment and `==` for comparison
    
    ("&", 450, .infix(parseInfixOperator), [], nil), // TO DO: should this accept optional `as` clause for specifying which coercion to force both operands to before joining (e.g. `A & B as list(text)`); and, if so, how should constraints be applied? (ditto for text/list comparison operators)
    
    
    // Boolean // TO DO: best to uppercase these operator names to avoid misuse by novices who use them as English conjunctions instead of logic operators?
    ("NOT", 100, .prefix(parsePrefixOperator), [], nil),
    ("AND",  98, .infix(parseInfixOperator),   [], nil),
    ("XOR",  96, .infix(parseInfixOperator),   [], nil),
    ("OR",   94, .infix(parseInfixOperator),   [], nil),
    
    // key constants
    ("nothing", 0, .atom(parseNothingOperator), ["Ø"], nil),
    
    // coercion // TO DO: precedence of `A as B`?
    ("as", 80, .infix(parseInfixOperator), [], nil),
    
    // define handlers
    ("to",   0, .prefix(parseCommandHandlerConstructorOperator), [], "define_handler"), // TO DO: should aliases redeclare canonical name?
    ("when", 0, .prefix(parseEventHandlerConstructorOperator),   [], "define_handler"),
    
    // flow control
    ("if",          10, .prefix(parsePostfixOperatorWithBlock), [], nil),
    ("repeat",      10, .prefix(parsePostfixOperatorWithBlock), [], nil),
    ("while",       10, .prefix(parsePostfixOperatorWithBlock), [], nil),
    
    // flow control (conjunctions)
    ("else",         5, .infix(parseInfixOperator),    [], nil),
    ("catching",     4, .infix(parseInfixOperator),    [], nil), // "defineErrorHandler"?
    
    // reference
    ("of",         1000, .infix(parseInfixOperator),   [], nil),
    //(".",         1000, .infix(parseReverseInfixOperator), [], "of_clause"), // TO DO: dot notation is useful for reverse domain name-style references
    
    // selectors
    ("at",         1200, .infix(parseInfixOperator),   [], nil),
    ("named",      1200, .infix(parseInfixOperator),   [], nil),
    ("where",      1200, .infix(parseInfixOperator),   [], nil),
    ("every",      1200, .prefix(parsePrefixOperator), [], nil),
    
    // range
    ("thru",       1210, .infix(parseInfixOperator),   [], nil),
    
    // note: default precedence is 0; punctuation is -ve; annotation is high; infix/postfix ops should come somewhere inbetween (hardcoding precedence as ints is icky, requiring sufficient sized gaps between different operator sets to allow for new operators to be defined inbetween, but will do for now); TO DO: if sticking to ints, consider defining operator precedence as CATEGORYOperatorPrecedence+relativePrecedence, e.g. booleanOperatorPrecedence = 0x00010000, with NOT,AND,XOR,OR having relative precedence of 3,2,1,0 to each other
    
    // TO DO: don't really want to support a `for NAME in EXPR BLOCK` operator as syntax isn't consistent with `OPERATOR EXPR BLOCK` syntax used by other operators; what about supporting `(NAME,…) BLOCK` syntax for lambdas (unnamed callables)? how practical is that? (it likely rules out using `COMMAND BLOCK` pattern to denote a command with trailing block argument [c.f. Swift], but not a huge fan of that anyway [in Swift, `OPERATOR EXPR BLOCK` and `IDENTIFIER TUPLE BLOCK` are frustratingly inconsistent - two incompatible syntaxes for essentially the same job])
    //
    // e.g. `COMMAND(ARG,{…})` vs `COMMAND(ARG,(PARAM){…})` aren't fundamentally bad syntaxes, although where to put `returning` clause when indicating typed inputs/output; Q. should `to SIGNATURE BLOCK` syntax be redefined as `to NAME PARAMETERIZED_BLOCK`? (it would be nice to have a single consistent syntax for named and unnamed callables, though does raise questions about where capability flags should go)
    
]



