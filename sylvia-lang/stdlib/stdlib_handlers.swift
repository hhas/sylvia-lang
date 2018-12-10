
//
//  stdlib_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//


// exponent(…)
let signature_exponent_a_b = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_exponent_a_b = CallableInterface(
    name: "exponent",
    parameters: [
        ("a", signature_exponent_a_b.paramType_0),
        ("b", signature_exponent_a_b.paramType_1),
    ],
    returnType: signature_exponent_a_b.returnType
)
func call_exponent_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_exponent_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_exponent_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try exponent(
        a: arg_0,
        b: arg_1
    )
    return try signature_exponent_a_b.returnType.box(value: result, env: handlerEnv)
}

// positive(…)
let signature_positive_a = (
    paramType_0: asScalar,
    returnType: asScalar
)
let interface_positive_a = CallableInterface(
    name: "positive",
    parameters: [
        ("a", signature_positive_a.paramType_0),
    ],
    returnType: signature_positive_a.returnType
)
func call_positive_a(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_positive_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try positive(
        a: arg_0
    )
    return try signature_positive_a.returnType.box(value: result, env: handlerEnv)
}

// negative(…)
let signature_negative_a = (
    paramType_0: asScalar,
    returnType: asScalar
)
let interface_negative_a = CallableInterface(
    name: "negative",
    parameters: [
        ("a", signature_negative_a.paramType_0),
    ],
    returnType: signature_negative_a.returnType
)
func call_negative_a(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_negative_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try negative(
        a: arg_0
    )
    return try signature_negative_a.returnType.box(value: result, env: handlerEnv)
}

// +(…)
let signature_add_a_b = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_add_a_b = CallableInterface(
    name: "+",
    parameters: [
        ("a", signature_add_a_b.paramType_0),
        ("b", signature_add_a_b.paramType_1),
    ],
    returnType: signature_add_a_b.returnType
)
func call_add_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_add_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_add_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try add(
        a: arg_0,
        b: arg_1
    )
    return try signature_add_a_b.returnType.box(value: result, env: handlerEnv)
}

// -(…)
let signature_subtract_a_b = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_subtract_a_b = CallableInterface(
    name: "-",
    parameters: [
        ("a", signature_subtract_a_b.paramType_0),
        ("b", signature_subtract_a_b.paramType_1),
    ],
    returnType: signature_subtract_a_b.returnType
)
func call_subtract_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_subtract_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_subtract_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try subtract(
        a: arg_0,
        b: arg_1
    )
    return try signature_subtract_a_b.returnType.box(value: result, env: handlerEnv)
}

// *(…)
let signature_multiply_a_b = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_multiply_a_b = CallableInterface(
    name: "*",
    parameters: [
        ("a", signature_multiply_a_b.paramType_0),
        ("b", signature_multiply_a_b.paramType_1),
    ],
    returnType: signature_multiply_a_b.returnType
)
func call_multiply_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_multiply_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_multiply_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try multiply(
        a: arg_0,
        b: arg_1
    )
    return try signature_multiply_a_b.returnType.box(value: result, env: handlerEnv)
}

// /(…)
let signature_divide_a_b = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_divide_a_b = CallableInterface(
    name: "/",
    parameters: [
        ("a", signature_divide_a_b.paramType_0),
        ("b", signature_divide_a_b.paramType_1),
    ],
    returnType: signature_divide_a_b.returnType
)
func call_divide_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_divide_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_divide_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_div_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_div_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_div_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_mod_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_mod_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_mod_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try mod(
        a: arg_0,
        b: arg_1
    )
    return try signature_mod_a_b.returnType.box(value: result, env: handlerEnv)
}

// <(…)
let signature_isLessThan_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isLessThan_a_b = CallableInterface(
    name: "<",
    parameters: [
        ("a", signature_isLessThan_a_b.paramType_0),
        ("b", signature_isLessThan_a_b.paramType_1),
    ],
    returnType: signature_isLessThan_a_b.returnType
)
func call_isLessThan_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isLessThan_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isLessThan_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isLessThan(
        a: arg_0,
        b: arg_1
    )
    return try signature_isLessThan_a_b.returnType.box(value: result, env: handlerEnv)
}

// <=(…)
let signature_isLessThanOrEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isLessThanOrEqualTo_a_b = CallableInterface(
    name: "<=",
    parameters: [
        ("a", signature_isLessThanOrEqualTo_a_b.paramType_0),
        ("b", signature_isLessThanOrEqualTo_a_b.paramType_1),
    ],
    returnType: signature_isLessThanOrEqualTo_a_b.returnType
)
func call_isLessThanOrEqualTo_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isLessThanOrEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isLessThanOrEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isLessThanOrEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isLessThanOrEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// ==(…)
let signature_isEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isEqualTo_a_b = CallableInterface(
    name: "==",
    parameters: [
        ("a", signature_isEqualTo_a_b.paramType_0),
        ("b", signature_isEqualTo_a_b.paramType_1),
    ],
    returnType: signature_isEqualTo_a_b.returnType
)
func call_isEqualTo_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// !=(…)
let signature_isNotEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isNotEqualTo_a_b = CallableInterface(
    name: "!=",
    parameters: [
        ("a", signature_isNotEqualTo_a_b.paramType_0),
        ("b", signature_isNotEqualTo_a_b.paramType_1),
    ],
    returnType: signature_isNotEqualTo_a_b.returnType
)
func call_isNotEqualTo_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isNotEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isNotEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isNotEqualTo(
        a: arg_0,
        b: arg_1
    )
    return try signature_isNotEqualTo_a_b.returnType.box(value: result, env: handlerEnv)
}

// >(…)
let signature_isGreaterThan_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isGreaterThan_a_b = CallableInterface(
    name: ">",
    parameters: [
        ("a", signature_isGreaterThan_a_b.paramType_0),
        ("b", signature_isGreaterThan_a_b.paramType_1),
    ],
    returnType: signature_isGreaterThan_a_b.returnType
)
func call_isGreaterThan_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isGreaterThan_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isGreaterThan_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isGreaterThan(
        a: arg_0,
        b: arg_1
    )
    return try signature_isGreaterThan_a_b.returnType.box(value: result, env: handlerEnv)
}

// >=(…)
let signature_isGreaterThanOrEqualTo_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isGreaterThanOrEqualTo_a_b = CallableInterface(
    name: ">=",
    parameters: [
        ("a", signature_isGreaterThanOrEqualTo_a_b.paramType_0),
        ("b", signature_isGreaterThanOrEqualTo_a_b.paramType_1),
    ],
    returnType: signature_isGreaterThanOrEqualTo_a_b.returnType
)
func call_isGreaterThanOrEqualTo_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isGreaterThanOrEqualTo_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isGreaterThanOrEqualTo_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_NOT_a(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_NOT_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_AND_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_AND_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_AND_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_OR_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_OR_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_OR_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_XOR_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_XOR_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_XOR_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_lt_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_lt_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_lt_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_le_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_le_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_le_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_eq_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_eq_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_eq_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_ne_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_ne_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ne_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_gt_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_gt_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_gt_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_ge_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_ge_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ge_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try ge(
        a: arg_0,
        b: arg_1
    )
    return try signature_ge_a_b.returnType.box(value: result, env: handlerEnv)
}

// &(…)
let signature_joinValues_a_b = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asString
)
let interface_joinValues_a_b = CallableInterface(
    name: "&",
    parameters: [
        ("a", signature_joinValues_a_b.paramType_0),
        ("b", signature_joinValues_a_b.paramType_1),
    ],
    returnType: signature_joinValues_a_b.returnType
)
func call_joinValues_a_b(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_joinValues_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_joinValues_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_uppercase_a(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_uppercase_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
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
func call_lowercase_a(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_lowercase_a.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = lowercase(
        a: arg_0
    )
    return try signature_lowercase_a.returnType.box(value: result, env: handlerEnv)
}

// show(…)
let signature_show_value = (
    paramType_0: asAnything,
    returnType: asNoResult
)
let interface_show_value = CallableInterface(
    name: "show",
    parameters: [
        ("value", signature_show_value.paramType_0),
    ],
    returnType: signature_show_value.returnType
)
func call_show_value(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_show_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    show(
        value: arg_0
    )
    return noValue
}

// format_code(…)
let signature_formatCode_value = (
    paramType_0: asOptionalValue,
    returnType: asString
)
let interface_formatCode_value = CallableInterface(
    name: "format_code",
    parameters: [
        ("value", signature_formatCode_value.paramType_0),
    ],
    returnType: signature_formatCode_value.returnType
)
func call_formatCode_value(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_formatCode_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = formatCode(
        value: arg_0
    )
    return try signature_formatCode_value.returnType.box(value: result, env: handlerEnv)
}

// define_handler(…)
let signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv = (
    paramType_0: asString,
    paramType_1: AsArray(asParameter),
    paramType_2: asCoercion,
    paramType_3: asIs,
    paramType_4: asBool,
    returnType: asNoResult
)
let interface_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv = CallableInterface(
    name: "define_handler",
    parameters: [
        ("name", signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_0),
        ("parameters", signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_1),
        ("return_type", signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_2),
        ("action", signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_3),
        ("is_event_handler", signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_4),
    ],
    returnType: signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.returnType
)
func call_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let arg_2 = try signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_2.unboxArgument(at: 2, command: command, commandEnv: commandEnv, handler: handler)
    let arg_3 = try signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_3.unboxArgument(at: 3, command: command, commandEnv: commandEnv, handler: handler)
    let arg_4 = try signature_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv.paramType_4.unboxArgument(at: 4, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 5 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    try defineHandler(
        name: arg_0,
        parameters: arg_1,
        returnType: arg_2,
        action: arg_3,
        isEventHandler: arg_4,
		commandEnv: commandEnv
    )
    return noValue
}

// store(…)
let signature_store_name_value_readOnly_commandEnv = (
    paramType_0: asString,
    paramType_1: asOptionalValue,
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
func call_store_name_value_readOnly_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_store_name_value_readOnly_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_store_name_value_readOnly_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let arg_2 = try signature_store_name_value_readOnly_commandEnv.paramType_2.unboxArgument(at: 2, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 3 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try store(
        name: arg_0,
        value: arg_1,
        readOnly: arg_2,
		commandEnv: commandEnv
    )
    return try signature_store_name_value_readOnly_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// if(…)
let signature_testIf_condition_action_commandEnv = (
    paramType_0: asBool,
    paramType_1: asBlock,
    returnType: asIs
)
let interface_testIf_condition_action_commandEnv = CallableInterface(
    name: "if",
    parameters: [
        ("condition", signature_testIf_condition_action_commandEnv.paramType_0),
        ("action", signature_testIf_condition_action_commandEnv.paramType_1),
    ],
    returnType: signature_testIf_condition_action_commandEnv.returnType
)
func call_testIf_condition_action_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_testIf_condition_action_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_testIf_condition_action_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try testIf(
        condition: arg_0,
        action: arg_1,
		commandEnv: commandEnv
    )
    return try signature_testIf_condition_action_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// repeat(…)
let signature_repeatTimes_count_action_commandEnv = (
    paramType_0: asInt,
    paramType_1: asBlock,
    returnType: asIs
)
let interface_repeatTimes_count_action_commandEnv = CallableInterface(
    name: "repeat",
    parameters: [
        ("count", signature_repeatTimes_count_action_commandEnv.paramType_0),
        ("action", signature_repeatTimes_count_action_commandEnv.paramType_1),
    ],
    returnType: signature_repeatTimes_count_action_commandEnv.returnType
)
func call_repeatTimes_count_action_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_repeatTimes_count_action_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_repeatTimes_count_action_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try repeatTimes(
        count: arg_0,
        action: arg_1,
		commandEnv: commandEnv
    )
    return try signature_repeatTimes_count_action_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// while(…)
let signature_repeatWhile_condition_action_commandEnv = (
    paramType_0: asOptionalValue,
    paramType_1: asBlock,
    returnType: asIs
)
let interface_repeatWhile_condition_action_commandEnv = CallableInterface(
    name: "while",
    parameters: [
        ("condition", signature_repeatWhile_condition_action_commandEnv.paramType_0),
        ("action", signature_repeatWhile_condition_action_commandEnv.paramType_1),
    ],
    returnType: signature_repeatWhile_condition_action_commandEnv.returnType
)
func call_repeatWhile_condition_action_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_repeatWhile_condition_action_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_repeatWhile_condition_action_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try repeatWhile(
        condition: arg_0,
        action: arg_1,
		commandEnv: commandEnv
    )
    return try signature_repeatWhile_condition_action_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// else(…)
let signature_elseClause_action_elseAction_commandEnv = (
    paramType_0: asAnything,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_elseClause_action_elseAction_commandEnv = CallableInterface(
    name: "else",
    parameters: [
        ("action", signature_elseClause_action_elseAction_commandEnv.paramType_0),
        ("elseAction", signature_elseClause_action_elseAction_commandEnv.paramType_1),
    ],
    returnType: signature_elseClause_action_elseAction_commandEnv.returnType
)
func call_elseClause_action_elseAction_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_elseClause_action_elseAction_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_elseClause_action_elseAction_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try elseClause(
        action: arg_0,
        elseAction: arg_1,
		commandEnv: commandEnv
    )
    return try signature_elseClause_action_elseAction_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// of(…)
let signature_ofClause_attribute_value_commandEnv = (
    paramType_0: asAttributedValue,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_ofClause_attribute_value_commandEnv = CallableInterface(
    name: "of",
    parameters: [
        ("attribute", signature_ofClause_attribute_value_commandEnv.paramType_0),
        ("value", signature_ofClause_attribute_value_commandEnv.paramType_1),
    ],
    returnType: signature_ofClause_attribute_value_commandEnv.returnType
)
func call_ofClause_attribute_value_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_ofClause_attribute_value_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ofClause_attribute_value_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try ofClause(
        attribute: arg_0,
        value: arg_1,
		commandEnv: commandEnv
    )
    return try signature_ofClause_attribute_value_commandEnv.returnType.box(value: result, env: handlerEnv)
}

// at(…)
let signature_atClause_attribute_value = (
    paramType_0: asAttributedValue,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_atClause_attribute_value = CallableInterface(
    name: "at",
    parameters: [
        ("attribute", signature_atClause_attribute_value.paramType_0),
        ("value", signature_atClause_attribute_value.paramType_1),
    ],
    returnType: signature_atClause_attribute_value.returnType
)
func call_atClause_attribute_value(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_atClause_attribute_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_atClause_attribute_value.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try atClause(
        attribute: arg_0,
        value: arg_1
    )
    return try signature_atClause_attribute_value.returnType.box(value: result, env: handlerEnv)
}


func stdlib_loadHandlers(env: Env) throws {
    
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
    try env.add(interface_formatCode_value, call_formatCode_value)
    try env.add(interface_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv, call_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv)
    try env.add(interface_store_name_value_readOnly_commandEnv, call_store_name_value_readOnly_commandEnv)
    try env.add(interface_testIf_condition_action_commandEnv, call_testIf_condition_action_commandEnv)
    try env.add(interface_repeatTimes_count_action_commandEnv, call_repeatTimes_count_action_commandEnv)
    try env.add(interface_repeatWhile_condition_action_commandEnv, call_repeatWhile_condition_action_commandEnv)
    try env.add(interface_elseClause_action_elseAction_commandEnv, call_elseClause_action_elseAction_commandEnv)
    try env.add(interface_ofClause_attribute_value_commandEnv, call_ofClause_attribute_value_commandEnv)
    try env.add(interface_atClause_attribute_value, call_atClause_attribute_value)
}
