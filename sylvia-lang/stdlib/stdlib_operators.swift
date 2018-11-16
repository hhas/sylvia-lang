//
//  stdlib_operators.swift
//

// note: all operators are just syntactic sugar over existing commands, e.g. `1+2` -> `add(1,2)`; this simplifies implementation, integrates with existing documentation generators, and enables easy metaprogramming (a parsed program [AST] is just lots of nested/sequential Commands and other Values, which parser and pretty printer can trivally convert between operator+command syntax and command-only syntax)



// how best to define/auto-generate operator tables? (custom parse funcs will need to be written in Swift, but everything else can be done natively via FFILib; it just needs a suitable command/operator syntax for declaring new operators [e.g. compare how Swift does it])


//  (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName]) // note: higher precedence binds more tightly than lower

let stdlib_operators: [OperatorDefinition] = [
    
    // TO DO: for each definition consider using the first word-based name found as the corresponding command/handler name (in the case of symbol-based operator names where the symbol is the canonical name, the word-based name would appear first in the alias list)
    
    ("^", 500, .infix(parseRightInfixOperator), ["exp"]),

    ("+", 490, .prefix(parsePrefixOperator), []),
    ("-", 490, .prefix(parsePrefixOperator), []),
    ("×", 480, .infix(parseInfixOperator),   ["*"]),
    ("÷", 480, .infix(parseInfixOperator),   ["/"]),
    ("+", 470, .infix(parseInfixOperator),   []),
    ("-", 470, .infix(parseInfixOperator),   []),
    
    ("div", 480, .infix(parseInfixOperator), ["//"]), // "//" = Python div operator
    ("mod", 480, .infix(parseInfixOperator), ["%"]), // note: if using `%` as a quantity unit (e.g. "100%"), need to make sure it won't be confused for modulus operator (one option is to define it as a postfix operator, which is one way to implement general quantity support [although this approach could get hairy when defining lots of postfix ops with common names like `meters`, `mm`; as a syntactic rule of thumb, it's safer to use coercions to convert to/from/between quantities, as that only has to define one type handler for each unit category: `length(units,min,max)`, `weight(…)`, `volume(…)`, etc])
    
    // math comparison
    ("<",  400, .infix(parseInfixOperator), []),
    ("<=", 400, .infix(parseInfixOperator), ["≤"]),
    ("==", 400, .infix(parseInfixOperator), []),    // TO DO: for this exercise we'll stick to traditional C/Python-style syntax, but need to explore using `=` for equality tests (c.f. AppleScript)
    ("!=", 400, .infix(parseInfixOperator), ["≠"]),
    (">",  400, .infix(parseInfixOperator), []),
    (">=", 400, .infix(parseInfixOperator), ["≥"]),
    
    // text/list comparison (c.f. Perl scalar operators)
    ("lt", 400, .infix(parseInfixOperator), ["isBefore"]),
    ("le", 400, .infix(parseInfixOperator), ["isNotBefore"]),
    ("eq", 400, .infix(parseInfixOperator), ["isEqualTo"]),
    ("ne", 400, .infix(parseInfixOperator), ["isNotEqualTo"]),
    ("gt", 400, .infix(parseInfixOperator), ["isAfter"]),
    ("ge", 400, .infix(parseInfixOperator), ["isNotAfter"]),
    
    // identity comparison
    ("is",      400, .infix(parseInfixOperator), []), // compare object IDs
    ("hasType", 400, .infix(parseInfixOperator), []), // try coercing value to specified type and return 'true' if it succeeds or 'false' if it fails (an extra trick is to cache successful Coercions within the value, allowing subsequent tests to compare coercion objects instead of coercing the value itself, though of course this cache will be invalidated if the value is mutated)
    
    // assignment
    // TO DO: if using NAME:VALUE for general assignment, we'll have to rely on coercions to specify read/write, e.g. `foo: 1 as editable(number)`, or else use `[let|var] NAME:VALUE`
    
    ("=", 400, .infix(parseInfixOperator), []), // assignment (Q. how best to distinguish read-only vs read-write? could probably use colons for constants and `=` for variables, but will need to confirm that colons will still work okay when used in key-value lists and labeled arguments/parameters); another option is to avoid `=` completely (as mistyping `a==b` as `a=b` is a common cause of bugs, especially when it's also legal as an expression) and use e.g. `:=` for assignment and `==` for comparison
    
    ("&", 450, .infix(parseInfixOperator), []), // TO DO: should this accept optional `as` clause for specifying which type to force both operands to before joining (e.g. `A & B as list(text)`); and, if so, how should constraints be applied? (ditto for text/list comparison operators)

    
    // Boolean // TO DO: best to uppercase these operator names to avoid misuse by novices who use them as English conjunctions instead of logic operators?
    ("NOT", 100, .prefix(parsePrefixOperator), []),
    ("AND",  98, .infix(parseInfixOperator),   []),
    ("XOR",  96, .infix(parseInfixOperator),   []),
    ("OR",   94, .infix(parseInfixOperator),   []),
    
    
]

