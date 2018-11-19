//
//  stdlib_operators.swift
//

// note: all operators are just syntactic sugar over existing commands, e.g. `1+2` -> `add(1,2)`; this simplifies implementation, integrates with existing documentation generators, and enables easy metaprogramming (a parsed program [AST] is just lots of nested/sequential Commands and other Values, which parser and pretty printer can trivally convert between operator+command syntax and command-only syntax)


// custom parse funcs


func parseNothingOperator(_ parser: Parser, operatorName: String, precedence: Int) throws -> Value {
    return noValue
}


// how best to define/auto-generate operator tables? (custom parse funcs will need to be written in Swift, but everything else can be done natively via FFILib; it just needs a suitable command/operator syntax for declaring new operators [e.g. compare how Swift does it])


//  (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName]) // note: higher precedence binds more tightly than lower

let stdlib_operators: [OperatorDefinition] = [
    
    // TO DO: for each definition consider using the first word-based name found as the corresponding command/handler name (in the case of symbol-based operator names where the symbol is the canonical name, the word-based name would appear first in the alias list)
    
    // TO DO: we need word-based aliases for symbol operators, partly to use as primitive func names but also to support dictation and help search; easiest solution would be to require all symbol operators provide at least one word-based alias, and if canonical name is symbol then the first word in aliases list is used as canonical word name (this does leave question of whether underlying handlers should use symbol or word name; if symbol, it avoids additional namespace pollution; if name, it's self-descriptive)
    
    ("^",   500, .infix(parseRightInfixOperator), ["exponent"]),
    
    // TO DO: should prefix `+` and `-` operators peek at next token and, if it's an unsigned .number, combine them and return a signed numeric value?
    ("+",   490, .prefix(parsePrefixOperator),    ["positive"]),
    ("-",   490, .prefix(parsePrefixOperator),    ["negative"]),
    
    ("×",   480, .infix(parseInfixOperator),      ["*", "multiply"]),
    ("÷",   480, .infix(parseInfixOperator),      ["/", "divide"]),
    
    ("div", 480, .infix(parseInfixOperator),      ["//", "integerDivision", "divideKeepingWhole"]), // "//" = Python div operator
    ("mod", 480, .infix(parseInfixOperator),      ["%", "modulus", "divideKeepingFraction"]), // note: if using `%` as a quantity unit (e.g. "100%"), need to make sure it won't be confused for modulus operator (one option is to define it as a postfix operator, which is one way to implement general quantity support [although this approach could get hairy when defining lots of postfix ops with common names like `meters`, `mm`; as a syntactic rule of thumb, it's safer to use coercions to convert to/from/between quantities, as that only has to define one type handler for each unit category: `length(units,min,max)`, `weight(…)`, `volume(…)`, etc])
    
    ("+",   470, .infix(parseInfixOperator),      ["add"]),
    ("-",   470, .infix(parseInfixOperator),      ["subtract"]),
    
    // math comparison
    ("<",  400, .infix(parseInfixOperator), ["isLessThan"]),
    ("<=", 400, .infix(parseInfixOperator), ["isLessThanOrEqualTo", "≤"]),
    ("==", 400, .infix(parseInfixOperator), ["isEqualTo"]),    // TO DO: for this exercise we'll stick to traditional C/Python-style syntax, but need to explore using `=` for equality tests (c.f. AppleScript)
    ("!=", 400, .infix(parseInfixOperator), ["isNotEqualTo", "≠"]),
    (">",  400, .infix(parseInfixOperator), ["isGreaterThan"]),
    (">=", 400, .infix(parseInfixOperator), ["isGreaterThanOrEqualTo", "≥"]),
    
    // text/list comparison (c.f. Perl scalar operators); TO DO: when comparing lists, should `A eq B as list(TYPE)` be required? what about text comparisons in general? (e.g. `A isSameAs B as caseSensitiveText`; other considerations: would it be wise to have `considering(TYPE){…}` that supplies default type for all comparison ops within its scope? If so, should it also apply to handlers called within that scope, and if so, how to do it safely? In AppleScript, considering/ignoring blocks implicitly affect all handlers called within that scope, causing handlers that don't explicitly set their own considering/ignoring flags to behave unpredictably; this could probably be covered by same 'requirements' ('capabilities'?) flags used to specify erroring, envs, pipes, and other external connections, side-effects, etc; thus default behavior would be for a handler to ignore command scope's considering/ignoring options unless it has `considersAndIgnores` in its capababilities list
    ("lt", 400, .infix(parseInfixOperator), ["isBefore"]),
    ("le", 400, .infix(parseInfixOperator), ["isNotBefore"]),
    ("eq", 400, .infix(parseInfixOperator), ["isSameAs"]),
    ("ne", 400, .infix(parseInfixOperator), ["isNotSameAs"]),
    ("gt", 400, .infix(parseInfixOperator), ["isAfter"]),
    ("ge", 400, .infix(parseInfixOperator), ["isNotAfter"]),
    
    // identity comparison
    ("isObject",    400, .infix(parseInfixOperator), []), // compare object IDs
    ("isOfType",    400, .infix(parseInfixOperator), []), // try coercing value to specified type and return 'true' if it succeeds or 'false' if it fails (an extra trick is to cache successful Coercions within the value, allowing subsequent tests to compare coercion objects instead of coercing the value itself, though of course this cache will be invalidated if the value is mutated) // note: there is difference between using coercions to test type suitability ('protocol-ness') of a Value vs checking its canonical type (e.g. `type of someValue == text`); allowing the latter may prove troublesome (novice users tend to check canonical type for equality when they should just check compatibility), so will need more thought (maybe use `EXPR isOfExactType TYPE`/`exactTypeOf EXPR`); plus it all gets extra thorny when values being checked are blocks, thunks, references, etc (should they be evaled and the result checked [which can cause issues where expression has side-effects or its result is non-idempotent], or should their current type [`codeBlock`, `lazyValue`, `reference`] be used? [note: AppleScript uses the former approach in an effort to appear simple and transparent to users, and frequently ends up causing confusion instead])
    
    // assignment
    // TO DO: if using NAME:VALUE for general assignment, we'll have to rely on coercions to specify read/write, e.g. `foo: 1 as editable(number)`, or else use `[let|var] NAME:VALUE`; using coercions is arguably better as the same syntax then works for handler signatures, allowing handler to indicate if it shares caller's argument value (c.f. pass-by-reference) or makes its own copy if needed (c.f. pass-by-value) (in keeping with existing read-only-by-default assignment policy, the latter behavior would be default and the former behavior explicitly requested using `EXPR as editable(…)`, or maybe even make `editable an atom/prefix operator for cleaner syntax, e.g. `EXPR as editable`, `EXPR as editable text`, etc, `EXPR as editable list(text)`); if we can be really sneaky, `A of B` operator could work by passing B as first argument to A, e.g. `EXPR as editable list of text`, `EXPR as editable list (max:10) of text`
    
    ("=", 400, .infix(parseInfixOperator), []), // assignment (Q. how best to distinguish read-only vs read-write? could probably use colons for constants and `=` for variables, but will need to confirm that colons will still work okay when used in key-value lists and labeled arguments/parameters); another option is to avoid `=` completely (as mistyping `a==b` as `a=b` is a common cause of bugs, especially when it's also legal as an expression) and use e.g. `:=` for assignment and `==` for comparison
    
    ("&", 450, .infix(parseInfixOperator), ["concatenatedWith"]), // TO DO: should this accept optional `as` clause for specifying which type to force both operands to before joining (e.g. `A & B as list(text)`); and, if so, how should constraints be applied? (ditto for text/list comparison operators)

    
    // Boolean // TO DO: best to uppercase these operator names to avoid misuse by novices who use them as English conjunctions instead of logic operators?
    ("NOT", 100, .prefix(parsePrefixOperator), []),
    ("AND",  98, .infix(parseInfixOperator),   []),
    ("XOR",  96, .infix(parseInfixOperator),   []),
    ("OR",   94, .infix(parseInfixOperator),   []),
    
    // key constants
    ("nothing", 0, .atom(parseNothingOperator), ["Ø"]),
    
    
    ("to",   0, .prefix(parseHandlerConstructorOperator), ["defineCommandHandler"]), // TO DO: should aliases redeclare canonical name?
    ("when", 0, .prefix(parseHandlerConstructorOperator), ["defineEventHandler"]),
    
]



// parse prefix operator with two right-hand operands, where 2nd operand must be a block (e.g. conditional and loop operators)

func parseExpressionAndBlockOperator(_ parser: Parser, operatorName: String, precedence: Int) throws -> Value {
    
    // TO DO: what about expr type? e.g. in loops and conditionals, any expression that evaluates to true/false (with some exceptions, e.g. blocks should probably be disallowed, and silliness such as `if to HANDLER(){} {}` would ideally be discouraged); Q. what about insisting that opening brace appear on same line as [end of] EXPR - e.g. `if EXPR { LF …` but not `if EXPR LF {…` - in order to reduce room for ambiguous-looking code [see .linebreak discussion in general])
    

    let expr = try parser.parseExpression(precedence)
    // 2nd operand is required to be a block to avoid syntactic ambiguity (including token patterns such as `WORD WORD` that per-line parsing can use to distinguish probable quoted text from probable code)
    let block = try parser.parseExpression(precedence) // T|O DO: implement Parser.parseIfBlock, which returns nil if non-block is found, giving caller choice of what to do next [this is preferable to throwing SyntaxError, as errors occuring while parsing contents of block aren't trivially distinguished from error raised when expected block isn't found])
    // TO DO: how best to support 'code' formatting style in error messages? (one option is to treat all error strings as Markdown, and format/escape interpolated values when inserting; may be best to leave this until native 'tagged' text interpolation is implemented, then allow that to be used when constructing error messages in both native and Swift code)
    if !(block is Block) { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found: \(block)") } // TO DO: long code needs elided for readability
    return Command(operatorName, leftOperand: expr, rightOperand: block)
}



func parseHandlerConstructorOperator(_ parser: Parser, operatorName: String, precedence: Int) throws -> Value {
    // TO DO: handler constructors should use dedicated parsefuncs to read handler signature (we need individual parsefuncs for argument, parameter, and interface signatures; once they're implemented we can call `parseCallableSignature` parsefunc here; for now just require a command)
    let expr = try parser.parseExpression(precedence)
    guard let signature = expr as? Command else { throw SyntaxError("Expected a handler signature after `\(operatorName)`, but found: \(expr)") } // TO DO: as above
    let block = try parser.parseExpression(precedence) // TO DO: as above
    if !(block is Block) { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found: \(block)") } // TO DO: ditto
    return Command(operatorName, [Text(signature.name), List(signature.arguments.map{Text(($0 as! Identifier).name)}), asAnything, block]) // kludge; TO DO
}
