//
//  stdlib_bridge
//

// wraps Swift functions in stdlib.swift as native handlers (this is generated code - do not edit directly)


// TO DO: once language is fully bootstrapped, LIBRARY_bridge.swift files should be 100% code-generated from native interface declarations; hopefully this can be done using existing syntax and operators/commands, the only difference is that when running IDC scripts, FFILib is loaded *instead of* (on top of?) stdlib, redefining the standard `define…Handler` and `store` commands to emit LIBNAME_bridge.swift code instead of modifying env

/*
 
 TO DO: primitive handler signatures should be defined using same syntax as for native handlers; only differences are that parameter+result coercions must be specified, and any 'external' resource requirements must be indicated so that bridging code generator can add the necessary parameters to the func call (all this info will also be used in auto-generated user documentation, and in [optimising] native-to-Swift cross-compilation of user 'scripts')
 
 */

// TO DO: consider supporting .nonMutating/.mutatesOnce/.mutating flags for indicating side effects ('mutatesOnce' = idempotent; once called, subsequent identical calls have no additional effect)

/* for FFI syntax, e.g. (assuming `NAME:VALUE` is assignment):

 
to '+' (a as primitive number, b as primitive number) returning primitive number {
 
    primitiveFunction:  add
    operatorParseFunc:  parseInfixOperator
    aliases:            [add]
    throws:             true
    commandEnv:         false
    handlerEnv:         false
    bodyEnv:            false

}
 
 Requirements may be declared as assignments within the block. (All requirement declarations should be optional; if omitted, defaults are used.)
 
 
 A further improvement would be to parse top-level function declarations of NAMElib.swift, allowing the bound name to be checked and eliminating need for explicit `primitive` operator, and `throws`, `commandEnv`/`handlerEnv`/`bodyEnv` requirements (as these can be determined from Swift func's signature).
 
 (Longer term, requirements section might include an option to extract the Swift function's body to code template suitable for cross-compiler to inline.)
 
*/


// TO DO: how should external entry point be named/declared?
// TO DO: consider using LibraryLoader protocol, as this will allow e.g. documentation generator to introspect the library without having to load everything into an actual environment

// TO DO: what about operator aliases? operator-sugared handlers must (currently?) be stored under operator's canonical name, which is not necessarily the same as primitive function's canonical name

// TO DO: catch and rethrow as ImportError?

// TO DO: this adds directly to supplied env rather than creating its own; Q. who should be responsible for creating module namespaces? (and who is responsible for adding modules to a global namespace where scripts can access them); Q. what is naming convention for 3rd-party modules? (e.g. reverse domain), and how will those modules appear in namespace (e.g. flat/custom name or hierarchical names [e.g. `com.foo.module[.handler]`])

// TO DO: loading should never fail (unless there's a module implementation bug, e.g. duplicate name); how practical to guarantee error-free module loading, in which case LIBNAME_load can be non-throwing?

// TO DO: how best to store & lazily load user documentation? (may be simplest just to include original bridge definition files in library bundle; if documentation is requested then read and parse/secure-eval those files)



// exponent(…)
let signature_exponent_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_exponent_a_b = CallableInterface(
    name: "exponent",
    parameters: [
        ("a", signature_exponent_a_b.paramType_0),
        ("b", signature_exponent_a_b.paramType_1),
        ],
    returnType: signature_exponent_a_b.returnType
)
func call_exponent_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_exponent_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_exponent_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try exponent(
        a: arg_0,
        b: arg_1
    )
    return try signature_exponent_a_b.returnType.box(value: result, env: handlerEnv)
}

// positive(…)
let signature_positive_a = (
    paramType_0: asDouble,
    returnType: asDouble
)
let interface_positive_a = CallableInterface(
    name: "positive",
    parameters: [
        ("a", signature_positive_a.paramType_0),
        ],
    returnType: signature_positive_a.returnType
)
func call_positive_a(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_positive_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let result = try positive(
        a: arg_0
    )
    return try signature_positive_a.returnType.box(value: result, env: handlerEnv)
}

// negative(…)
let signature_negative_a = (
    paramType_0: asDouble,
    returnType: asDouble
)
let interface_negative_a = CallableInterface(
    name: "negative",
    parameters: [
        ("a", signature_negative_a.paramType_0),
        ],
    returnType: signature_negative_a.returnType
)
func call_negative_a(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_negative_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let result = try negative(
        a: arg_0
    )
    return try signature_negative_a.returnType.box(value: result, env: handlerEnv)
}

// add(…)
let signature_add_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_add_a_b = CallableInterface(
    name: "add",
    parameters: [
        ("a", signature_add_a_b.paramType_0),
        ("b", signature_add_a_b.paramType_1),
        ],
    returnType: signature_add_a_b.returnType
)
func call_add_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_add_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_add_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try add(
        a: arg_0,
        b: arg_1
    )
    return try signature_add_a_b.returnType.box(value: result, env: handlerEnv)
}

// subtract(…)
let signature_subtract_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_subtract_a_b = CallableInterface(
    name: "subtract",
    parameters: [
        ("a", signature_subtract_a_b.paramType_0),
        ("b", signature_subtract_a_b.paramType_1),
        ],
    returnType: signature_subtract_a_b.returnType
)
func call_subtract_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_subtract_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_subtract_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try subtract(
        a: arg_0,
        b: arg_1
    )
    return try signature_subtract_a_b.returnType.box(value: result, env: handlerEnv)
}

// multiply(…)
let signature_multiply_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_multiply_a_b = CallableInterface(
    name: "multiply",
    parameters: [
        ("a", signature_multiply_a_b.paramType_0),
        ("b", signature_multiply_a_b.paramType_1),
        ],
    returnType: signature_multiply_a_b.returnType
)
func call_multiply_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_multiply_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_multiply_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try multiply(
        a: arg_0,
        b: arg_1
    )
    return try signature_multiply_a_b.returnType.box(value: result, env: handlerEnv)
}

// divide(…)
let signature_divide_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_divide_a_b = CallableInterface(
    name: "divide",
    parameters: [
        ("a", signature_divide_a_b.paramType_0),
        ("b", signature_divide_a_b.paramType_1),
        ],
    returnType: signature_divide_a_b.returnType
)
func call_divide_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_divide_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_divide_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try divide(
        a: arg_0,
        b: arg_1
    )
    return try signature_divide_a_b.returnType.box(value: result, env: handlerEnv)
}

// div(…)
let signature_div_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_div_a_b = CallableInterface(
    name: "div",
    parameters: [
        ("a", signature_div_a_b.paramType_0),
        ("b", signature_div_a_b.paramType_1),
        ],
    returnType: signature_div_a_b.returnType
)
func call_div_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_div_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_div_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try div(
        a: arg_0,
        b: arg_1
    )
    return try signature_div_a_b.returnType.box(value: result, env: handlerEnv)
}

// mod(…)
let signature_mod_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_mod_a_b = CallableInterface(
    name: "mod",
    parameters: [
        ("a", signature_mod_a_b.paramType_0),
        ("b", signature_mod_a_b.paramType_1),
        ],
    returnType: signature_mod_a_b.returnType
)
func call_mod_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_mod_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_mod_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try mod(
        a: arg_0,
        b: arg_1
    )
    return try signature_mod_a_b.returnType.box(value: result, env: handlerEnv)
}

// isLessThan(…)
let signature_isLessThan_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isLessThan_a_b = CallableInterface(
    name: "isLessThan",
    parameters: [
        ("a", signature_isLessThan_a_b.paramType_0),
        ("b", signature_isLessThan_a_b.paramType_1),
        ],
    returnType: signature_isLessThan_a_b.returnType
)
func call_isLessThan_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_isLessThan_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isLessThan_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = isLessThan(
        a: arg_0,
        b: arg_1
    )
    return try signature_isLessThan_a_b.returnType.box(value: result, env: handlerEnv)
}

// isLessThanOrEqualTo(…)
let signature_isLessThanOrEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isLessThanOrEqualTo_a_b = CallableInterface(
    name: "isLessThanOrEqualTo",
    parameters: [
        ("a", signature_isLessThanOrEqualTo_a_b.paramType_0),
        ("b", signature_isLessThanOrEqualTo_a_b.paramType_1),
        ],
    returnType: signature_isLessThanOrEqualTo_a_b.returnType
)
func call_isLessThanOrEqualTo_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_isLessThanOrEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isLessThanOrEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = isLessThanOrEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isLessThanOrEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// isEqualTo(…)
let signature_isEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isEqualTo_a_b = CallableInterface(
    name: "isEqualTo",
    parameters: [
        ("a", signature_isEqualTo_a_b.paramType_0),
        ("b", signature_isEqualTo_a_b.paramType_1),
        ],
    returnType: signature_isEqualTo_a_b.returnType
)
func call_isEqualTo_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_isEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = isEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// isNotEqualTo(…)
let signature_isNotEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isNotEqualTo_a_b = CallableInterface(
    name: "isNotEqualTo",
    parameters: [
        ("a", signature_isNotEqualTo_a_b.paramType_0),
        ("b", signature_isNotEqualTo_a_b.paramType_1),
        ],
    returnType: signature_isNotEqualTo_a_b.returnType
)
func call_isNotEqualTo_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_isNotEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isNotEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = isNotEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isNotEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// isGreaterThan(…)
let signature_isGreaterThan_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isGreaterThan_a_b = CallableInterface(
    name: "isGreaterThan",
    parameters: [
        ("a", signature_isGreaterThan_a_b.paramType_0),
        ("b", signature_isGreaterThan_a_b.paramType_1),
        ],
    returnType: signature_isGreaterThan_a_b.returnType
)
func call_isGreaterThan_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_isGreaterThan_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isGreaterThan_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = isGreaterThan(
        a: arg_0,
        b: arg_1
    )
    return try signature_isGreaterThan_a_b.returnType.box(value: result, env: handlerEnv)
}

// isGreaterThanOrEqualTo(…)
let signature_isGreaterThanOrEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isGreaterThanOrEqualTo_a_b = CallableInterface(
    name: "isGreaterThanOrEqualTo",
    parameters: [
        ("a", signature_isGreaterThanOrEqualTo_a_b.paramType_0),
        ("b", signature_isGreaterThanOrEqualTo_a_b.paramType_1),
        ],
    returnType: signature_isGreaterThanOrEqualTo_a_b.returnType
)
func call_isGreaterThanOrEqualTo_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_isGreaterThanOrEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isGreaterThanOrEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = isGreaterThanOrEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isGreaterThanOrEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// NOT(…)
let signature_NOT_a = (
    paramType_0: asBool,
    returnType: asBool
)
let interface_NOT_a = CallableInterface(
    name: "NOT",
    parameters: [
        ("a", signature_NOT_a.paramType_0),
        ],
    returnType: signature_NOT_a.returnType
)
func call_NOT_a(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_NOT_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let result = NOT(
        a: arg_0
    )
    return try signature_NOT_a.returnType.box(value: result, env: handlerEnv)
}

// AND(…)
let signature_AND_a_b = (
    paramType_0: asBool,
    paramType_1: asBool,
    returnType: asBool
)
let interface_AND_a_b = CallableInterface(
    name: "AND",
    parameters: [
        ("a", signature_AND_a_b.paramType_0),
        ("b", signature_AND_a_b.paramType_1),
        ],
    returnType: signature_AND_a_b.returnType
)
func call_AND_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_AND_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_AND_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = AND(
        a: arg_0,
        b: arg_1
    )
    return try signature_AND_a_b.returnType.box(value: result, env: handlerEnv)
}

// OR(…)
let signature_OR_a_b = (
    paramType_0: asBool,
    paramType_1: asBool,
    returnType: asBool
)
let interface_OR_a_b = CallableInterface(
    name: "OR",
    parameters: [
        ("a", signature_OR_a_b.paramType_0),
        ("b", signature_OR_a_b.paramType_1),
        ],
    returnType: signature_OR_a_b.returnType
)
func call_OR_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_OR_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_OR_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = OR(
        a: arg_0,
        b: arg_1
    )
    return try signature_OR_a_b.returnType.box(value: result, env: handlerEnv)
}

// XOR(…)
let signature_XOR_a_b = (
    paramType_0: asBool,
    paramType_1: asBool,
    returnType: asBool
)
let interface_XOR_a_b = CallableInterface(
    name: "XOR",
    parameters: [
        ("a", signature_XOR_a_b.paramType_0),
        ("b", signature_XOR_a_b.paramType_1),
        ],
    returnType: signature_XOR_a_b.returnType
)
func call_XOR_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_XOR_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_XOR_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = XOR(
        a: arg_0,
        b: arg_1
    )
    return try signature_XOR_a_b.returnType.box(value: result, env: handlerEnv)
}

// lt(…)
let signature_lt_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_lt_a_b = CallableInterface(
    name: "lt",
    parameters: [
        ("a", signature_lt_a_b.paramType_0),
        ("b", signature_lt_a_b.paramType_1),
        ],
    returnType: signature_lt_a_b.returnType
)
func call_lt_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_lt_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_lt_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try lt(
        a: arg_0,
        b: arg_1
    )
    return try signature_lt_a_b.returnType.box(value: result, env: handlerEnv)
}

// le(…)
let signature_le_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_le_a_b = CallableInterface(
    name: "le",
    parameters: [
        ("a", signature_le_a_b.paramType_0),
        ("b", signature_le_a_b.paramType_1),
        ],
    returnType: signature_le_a_b.returnType
)
func call_le_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_le_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_le_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try le(
        a: arg_0,
        b: arg_1
    )
    return try signature_le_a_b.returnType.box(value: result, env: handlerEnv)
}

// eq(…)
let signature_eq_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_eq_a_b = CallableInterface(
    name: "eq",
    parameters: [
        ("a", signature_eq_a_b.paramType_0),
        ("b", signature_eq_a_b.paramType_1),
        ],
    returnType: signature_eq_a_b.returnType
)
func call_eq_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_eq_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_eq_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try eq(
        a: arg_0,
        b: arg_1
    )
    return try signature_eq_a_b.returnType.box(value: result, env: handlerEnv)
}

// ne(…)
let signature_ne_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_ne_a_b = CallableInterface(
    name: "ne",
    parameters: [
        ("a", signature_ne_a_b.paramType_0),
        ("b", signature_ne_a_b.paramType_1),
        ],
    returnType: signature_ne_a_b.returnType
)
func call_ne_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_ne_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ne_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try ne(
        a: arg_0,
        b: arg_1
    )
    return try signature_ne_a_b.returnType.box(value: result, env: handlerEnv)
}

// gt(…)
let signature_gt_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_gt_a_b = CallableInterface(
    name: "gt",
    parameters: [
        ("a", signature_gt_a_b.paramType_0),
        ("b", signature_gt_a_b.paramType_1),
        ],
    returnType: signature_gt_a_b.returnType
)
func call_gt_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_gt_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_gt_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try gt(
        a: arg_0,
        b: arg_1
    )
    return try signature_gt_a_b.returnType.box(value: result, env: handlerEnv)
}

// ge(…)
let signature_ge_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_ge_a_b = CallableInterface(
    name: "ge",
    parameters: [
        ("a", signature_ge_a_b.paramType_0),
        ("b", signature_ge_a_b.paramType_1),
        ],
    returnType: signature_ge_a_b.returnType
)
func call_ge_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_ge_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ge_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try ge(
        a: arg_0,
        b: arg_1
    )
    return try signature_ge_a_b.returnType.box(value: result, env: handlerEnv)
}

// joinValues(…)
let signature_joinValues_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asString
)
let interface_joinValues_a_b = CallableInterface(
    name: "joinValues",
    parameters: [
        ("a", signature_joinValues_a_b.paramType_0),
        ("b", signature_joinValues_a_b.paramType_1),
        ],
    returnType: signature_joinValues_a_b.returnType
)
func call_joinValues_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_joinValues_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_joinValues_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try joinValues(
        a: arg_0,
        b: arg_1
    )
    return try signature_joinValues_a_b.returnType.box(value: result, env: handlerEnv)
}

// uppercase(…)
let signature_uppercase_a = (
    paramType_0: asString,
    returnType: asString
)
let interface_uppercase_a = CallableInterface(
    name: "uppercase",
    parameters: [
        ("a", signature_uppercase_a.paramType_0),
        ],
    returnType: signature_uppercase_a.returnType
)
func call_uppercase_a(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_uppercase_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let result = uppercase(
        a: arg_0
    )
    return try signature_uppercase_a.returnType.box(value: result, env: handlerEnv)
}

// lowercase(…)
let signature_lowercase_a = (
    paramType_0: asString,
    returnType: asString
)
let interface_lowercase_a = CallableInterface(
    name: "lowercase",
    parameters: [
        ("a", signature_lowercase_a.paramType_0),
        ],
    returnType: signature_lowercase_a.returnType
)
func call_lowercase_a(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_lowercase_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let result = lowercase(
        a: arg_0
    )
    return try signature_lowercase_a.returnType.box(value: result, env: handlerEnv)
}

// show(…)
let signature_show_value = (
    paramType_0: asIs,
    returnType: asNothing
)
let interface_show_value = CallableInterface(
    name: "show",
    parameters: [
        ("value", signature_show_value.paramType_0),
        ],
    returnType: signature_show_value.returnType
)
func call_show_value(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_show_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    show(
        value: arg_0
    )
    return noValue
}

// defineCommandHandler(…)
let signature_defineCommandHandler_name_parameters_returnType_body_commandEnv = (
    paramType_0: asString,
    paramType_1: AsArray(asParameter),
    paramType_2: asCoercion,
    paramType_3: asIs,
    returnType: asNothing
)
let interface_defineCommandHandler_name_parameters_returnType_body_commandEnv = CallableInterface(
    name: "defineCommandHandler",
    parameters: [
        ("name", signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_0),
        ("parameters", signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_1),
        ("returnType", signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_2),
        ("body", signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_3),
        ],
    returnType: signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.returnType
)
func call_defineCommandHandler_name_parameters_returnType_body_commandEnv(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let arg_2 = try signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_2.unboxArgument(at: 2, command: command, commandEnv: commandEnv, handler: handler)
    let arg_3 = try signature_defineCommandHandler_name_parameters_returnType_body_commandEnv.paramType_3.unboxArgument(at: 3, command: command, commandEnv: commandEnv, handler: handler)
    try defineCommandHandler(
        name: arg_0,
        parameters: arg_1,
        returnType: arg_2,
        body: arg_3,
        commandEnv: commandEnv
    )
    return noValue
}

// store(…)
let signature_store_name_value_readOnly_commandEnv = (
    paramType_0: asString,
    paramType_1: asAnything,
    paramType_2: asBool,
    returnType: asIs
)
let interface_store_name_value_readOnly_commandEnv = CallableInterface(
    name: "store",
    parameters: [
        ("name", signature_store_name_value_readOnly_commandEnv.paramType_0),
        ("value", signature_store_name_value_readOnly_commandEnv.paramType_1),
        ("readOnly", signature_store_name_value_readOnly_commandEnv.paramType_2),
        ],
    returnType: signature_store_name_value_readOnly_commandEnv.returnType
)
func call_store_name_value_readOnly_commandEnv(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_store_name_value_readOnly_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_store_name_value_readOnly_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let arg_2 = try signature_store_name_value_readOnly_commandEnv.paramType_2.unboxArgument(at: 2, command: command, commandEnv: commandEnv, handler: handler)
    let result = try store(
        name: arg_0,
        value: arg_1,
        readOnly: arg_2,
        commandEnv: commandEnv
    )
    return try signature_store_name_value_readOnly_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// testIf(…)
let signature_testIf_condition_action_commandEnv = (
    paramType_0: asBool,
    paramType_1: asBlock,
    returnType: asIs
)
let interface_testIf_condition_action_commandEnv = CallableInterface(
    name: "testIf",
    parameters: [
        ("condition", signature_testIf_condition_action_commandEnv.paramType_0),
        ("action", signature_testIf_condition_action_commandEnv.paramType_1),
        ],
    returnType: signature_testIf_condition_action_commandEnv.returnType
)
func call_testIf_condition_action_commandEnv(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_testIf_condition_action_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_testIf_condition_action_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try testIf(
        condition: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return try signature_testIf_condition_action_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// repeatTimes(…)
let signature_repeatTimes_count_action_commandEnv = (
    paramType_0: asInt,
    paramType_1: asBlock,
    returnType: asIs
)
let interface_repeatTimes_count_action_commandEnv = CallableInterface(
    name: "repeatTimes",
    parameters: [
        ("count", signature_repeatTimes_count_action_commandEnv.paramType_0),
        ("action", signature_repeatTimes_count_action_commandEnv.paramType_1),
        ],
    returnType: signature_repeatTimes_count_action_commandEnv.returnType
)
func call_repeatTimes_count_action_commandEnv(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_repeatTimes_count_action_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_repeatTimes_count_action_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try repeatTimes(
        count: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return try signature_repeatTimes_count_action_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// repeatWhile(…)
let signature_repeatWhile_condition_action_commandEnv = (
    paramType_0: asAnything,
    paramType_1: asBlock,
    returnType: asIs
)
let interface_repeatWhile_condition_action_commandEnv = CallableInterface(
    name: "repeatWhile",
    parameters: [
        ("condition", signature_repeatWhile_condition_action_commandEnv.paramType_0),
        ("action", signature_repeatWhile_condition_action_commandEnv.paramType_1),
        ],
    returnType: signature_repeatWhile_condition_action_commandEnv.returnType
)
func call_repeatWhile_condition_action_commandEnv(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_repeatWhile_condition_action_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_repeatWhile_condition_action_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try repeatWhile(
        condition: arg_0,
        action: arg_1,
        commandEnv: commandEnv
    )
    return try signature_repeatWhile_condition_action_commandEnv.returnType.box(value: result, env: handlerEnv)
}


// auto-generated module load function

func stdlib_load(env: Env) throws {
    try loadConstants(env: env)
    try loadCoercions(env: env)
    
    try env.add(interface_exponent_a_b, call_exponent_a_b)
    try env.add(interface_positive_a, call_positive_a)
    try env.add(interface_negative_a, call_negative_a)
    try env.add(interface_add_a_b, call_add_a_b)
    try env.add(interface_subtract_a_b, call_subtract_a_b)
    try env.add(interface_multiply_a_b, call_multiply_a_b)
    try env.add(interface_divide_a_b, call_divide_a_b)
    try env.add(interface_div_a_b, call_div_a_b)
    try env.add(interface_mod_a_b, call_mod_a_b)
    try env.add(interface_isLessThan_a_b, call_isLessThan_a_b)
    try env.add(interface_isLessThanOrEqualTo_a_b, call_isLessThanOrEqualTo_a_b)
    try env.add(interface_isEqualTo_a_b, call_isEqualTo_a_b)
    try env.add(interface_isNotEqualTo_a_b, call_isNotEqualTo_a_b)
    try env.add(interface_isGreaterThan_a_b, call_isGreaterThan_a_b)
    try env.add(interface_isGreaterThanOrEqualTo_a_b, call_isGreaterThanOrEqualTo_a_b)
    try env.add(interface_NOT_a, call_NOT_a)
    try env.add(interface_AND_a_b, call_AND_a_b)
    try env.add(interface_OR_a_b, call_OR_a_b)
    try env.add(interface_XOR_a_b, call_XOR_a_b)
    try env.add(interface_lt_a_b, call_lt_a_b)
    try env.add(interface_le_a_b, call_le_a_b)
    try env.add(interface_eq_a_b, call_eq_a_b)
    try env.add(interface_ne_a_b, call_ne_a_b)
    try env.add(interface_gt_a_b, call_gt_a_b)
    try env.add(interface_ge_a_b, call_ge_a_b)
    try env.add(interface_joinValues_a_b, call_joinValues_a_b)
    try env.add(interface_uppercase_a, call_uppercase_a)
    try env.add(interface_lowercase_a, call_lowercase_a)
    try env.add(interface_show_value, call_show_value)
    try env.add(interface_defineCommandHandler_name_parameters_returnType_body_commandEnv, call_defineCommandHandler_name_parameters_returnType_body_commandEnv)
    try env.add(interface_store_name_value_readOnly_commandEnv, call_store_name_value_readOnly_commandEnv)
    try env.add(interface_testIf_condition_action_commandEnv, call_testIf_condition_action_commandEnv)
    try env.add(interface_repeatTimes_count_action_commandEnv, call_repeatTimes_count_action_commandEnv)
    try env.add(interface_repeatWhile_condition_action_commandEnv, call_repeatWhile_condition_action_commandEnv)
}

