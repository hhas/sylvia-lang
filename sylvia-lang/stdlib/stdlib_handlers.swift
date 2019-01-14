
//
//  stdlib_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//


// exponent (left, right)
let signature_exponent_left_right = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_exponent_left_right = CallableInterface(
    name: "exponent",
    parameters: [
        ("left", signature_exponent_left_right.paramType_0),
        ("right", signature_exponent_left_right.paramType_1),
    ],
    returnType: signature_exponent_left_right.returnType
)
func function_exponent_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_exponent_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_exponent_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try exponent(
        left: arg_0,
        right: arg_1
    )
    return try signature_exponent_left_right.returnType.box(value: result, env: handlerEnv)
}


// positive (left)
let signature_positive_left = (
    paramType_0: asScalar,
    returnType: asScalar
)
let interface_positive_left = CallableInterface(
    name: "positive",
    parameters: [
        ("left", signature_positive_left.paramType_0),
    ],
    returnType: signature_positive_left.returnType
)
func function_positive_left(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_positive_left.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try positive(
        left: arg_0
    )
    return try signature_positive_left.returnType.box(value: result, env: handlerEnv)
}


// negative (left)
let signature_negative_left = (
    paramType_0: asScalar,
    returnType: asScalar
)
let interface_negative_left = CallableInterface(
    name: "negative",
    parameters: [
        ("left", signature_negative_left.paramType_0),
    ],
    returnType: signature_negative_left.returnType
)
func function_negative_left(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_negative_left.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try negative(
        left: arg_0
    )
    return try signature_negative_left.returnType.box(value: result, env: handlerEnv)
}


// + (left, right)
let signature_add_left_right = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_add_left_right = CallableInterface(
    name: "+",
    parameters: [
        ("left", signature_add_left_right.paramType_0),
        ("right", signature_add_left_right.paramType_1),
    ],
    returnType: signature_add_left_right.returnType
)
func function_add_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_add_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_add_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try add(
        left: arg_0,
        right: arg_1
    )
    return try signature_add_left_right.returnType.box(value: result, env: handlerEnv)
}


// - (left, right)
let signature_subtract_left_right = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_subtract_left_right = CallableInterface(
    name: "-",
    parameters: [
        ("left", signature_subtract_left_right.paramType_0),
        ("right", signature_subtract_left_right.paramType_1),
    ],
    returnType: signature_subtract_left_right.returnType
)
func function_subtract_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_subtract_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_subtract_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try subtract(
        left: arg_0,
        right: arg_1
    )
    return try signature_subtract_left_right.returnType.box(value: result, env: handlerEnv)
}


// * (left, right)
let signature_multiply_left_right = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_multiply_left_right = CallableInterface(
    name: "*",
    parameters: [
        ("left", signature_multiply_left_right.paramType_0),
        ("right", signature_multiply_left_right.paramType_1),
    ],
    returnType: signature_multiply_left_right.returnType
)
func function_multiply_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_multiply_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_multiply_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try multiply(
        left: arg_0,
        right: arg_1
    )
    return try signature_multiply_left_right.returnType.box(value: result, env: handlerEnv)
}


// / (left, right)
let signature_divide_left_right = (
    paramType_0: asScalar,
    paramType_1: asScalar,
    returnType: asScalar
)
let interface_divide_left_right = CallableInterface(
    name: "/",
    parameters: [
        ("left", signature_divide_left_right.paramType_0),
        ("right", signature_divide_left_right.paramType_1),
    ],
    returnType: signature_divide_left_right.returnType
)
func function_divide_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_divide_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_divide_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try divide(
        left: arg_0,
        right: arg_1
    )
    return try signature_divide_left_right.returnType.box(value: result, env: handlerEnv)
}


// div (left, right)
let signature_div_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_div_left_right = CallableInterface(
    name: "div",
    parameters: [
        ("left", signature_div_left_right.paramType_0),
        ("right", signature_div_left_right.paramType_1),
    ],
    returnType: signature_div_left_right.returnType
)
func function_div_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_div_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_div_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try div(
        left: arg_0,
        right: arg_1
    )
    return try signature_div_left_right.returnType.box(value: result, env: handlerEnv)
}


// mod (left, right)
let signature_mod_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_mod_left_right = CallableInterface(
    name: "mod",
    parameters: [
        ("left", signature_mod_left_right.paramType_0),
        ("right", signature_mod_left_right.paramType_1),
    ],
    returnType: signature_mod_left_right.returnType
)
func function_mod_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_mod_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_mod_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try mod(
        left: arg_0,
        right: arg_1
    )
    return try signature_mod_left_right.returnType.box(value: result, env: handlerEnv)
}


// < (left, right)
let signature_isLessThan_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isLessThan_left_right = CallableInterface(
    name: "<",
    parameters: [
        ("left", signature_isLessThan_left_right.paramType_0),
        ("right", signature_isLessThan_left_right.paramType_1),
    ],
    returnType: signature_isLessThan_left_right.returnType
)
func function_isLessThan_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isLessThan_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isLessThan_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isLessThan(
        left: arg_0,
        right: arg_1
    )
    return try signature_isLessThan_left_right.returnType.box(value: result, env: handlerEnv)
}


// <= (left, right)
let signature_isLessThanOrEqualTo_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isLessThanOrEqualTo_left_right = CallableInterface(
    name: "<=",
    parameters: [
        ("left", signature_isLessThanOrEqualTo_left_right.paramType_0),
        ("right", signature_isLessThanOrEqualTo_left_right.paramType_1),
    ],
    returnType: signature_isLessThanOrEqualTo_left_right.returnType
)
func function_isLessThanOrEqualTo_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isLessThanOrEqualTo_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isLessThanOrEqualTo_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isLessThanOrEqualTo(
        left: arg_0,
        right: arg_1
    )
    return try signature_isLessThanOrEqualTo_left_right.returnType.box(value: result, env: handlerEnv)
}


// == (left, right)
let signature_isEqualTo_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isEqualTo_left_right = CallableInterface(
    name: "==",
    parameters: [
        ("left", signature_isEqualTo_left_right.paramType_0),
        ("right", signature_isEqualTo_left_right.paramType_1),
    ],
    returnType: signature_isEqualTo_left_right.returnType
)
func function_isEqualTo_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isEqualTo_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isEqualTo_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isEqualTo(
        left: arg_0,
        right: arg_1
    )
    return try signature_isEqualTo_left_right.returnType.box(value: result, env: handlerEnv)
}


// != (left, right)
let signature_isNotEqualTo_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isNotEqualTo_left_right = CallableInterface(
    name: "!=",
    parameters: [
        ("left", signature_isNotEqualTo_left_right.paramType_0),
        ("right", signature_isNotEqualTo_left_right.paramType_1),
    ],
    returnType: signature_isNotEqualTo_left_right.returnType
)
func function_isNotEqualTo_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isNotEqualTo_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isNotEqualTo_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isNotEqualTo(
        left: arg_0,
        right: arg_1
    )
    return try signature_isNotEqualTo_left_right.returnType.box(value: result, env: handlerEnv)
}


// > (left, right)
let signature_isGreaterThan_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isGreaterThan_left_right = CallableInterface(
    name: ">",
    parameters: [
        ("left", signature_isGreaterThan_left_right.paramType_0),
        ("right", signature_isGreaterThan_left_right.paramType_1),
    ],
    returnType: signature_isGreaterThan_left_right.returnType
)
func function_isGreaterThan_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isGreaterThan_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isGreaterThan_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isGreaterThan(
        left: arg_0,
        right: arg_1
    )
    return try signature_isGreaterThan_left_right.returnType.box(value: result, env: handlerEnv)
}


// >= (left, right)
let signature_isGreaterThanOrEqualTo_left_right = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asBool
)
let interface_isGreaterThanOrEqualTo_left_right = CallableInterface(
    name: ">=",
    parameters: [
        ("left", signature_isGreaterThanOrEqualTo_left_right.paramType_0),
        ("right", signature_isGreaterThanOrEqualTo_left_right.paramType_1),
    ],
    returnType: signature_isGreaterThanOrEqualTo_left_right.returnType
)
func function_isGreaterThanOrEqualTo_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isGreaterThanOrEqualTo_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isGreaterThanOrEqualTo_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isGreaterThanOrEqualTo(
        left: arg_0,
        right: arg_1
    )
    return try signature_isGreaterThanOrEqualTo_left_right.returnType.box(value: result, env: handlerEnv)
}


// NOT (right)
let signature_NOT_right = (
    paramType_0: asBool,
    returnType: asBool
)
let interface_NOT_right = CallableInterface(
    name: "NOT",
    parameters: [
        ("right", signature_NOT_right.paramType_0),
    ],
    returnType: signature_NOT_right.returnType
)
func function_NOT_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_NOT_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = NOT(
        right: arg_0
    )
    return try signature_NOT_right.returnType.box(value: result, env: handlerEnv)
}


// AND (left, right)
let signature_AND_left_right = (
    paramType_0: asBool,
    paramType_1: asBool,
    returnType: asBool
)
let interface_AND_left_right = CallableInterface(
    name: "AND",
    parameters: [
        ("left", signature_AND_left_right.paramType_0),
        ("right", signature_AND_left_right.paramType_1),
    ],
    returnType: signature_AND_left_right.returnType
)
func function_AND_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_AND_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_AND_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = AND(
        left: arg_0,
        right: arg_1
    )
    return try signature_AND_left_right.returnType.box(value: result, env: handlerEnv)
}


// OR (left, right)
let signature_OR_left_right = (
    paramType_0: asBool,
    paramType_1: asBool,
    returnType: asBool
)
let interface_OR_left_right = CallableInterface(
    name: "OR",
    parameters: [
        ("left", signature_OR_left_right.paramType_0),
        ("right", signature_OR_left_right.paramType_1),
    ],
    returnType: signature_OR_left_right.returnType
)
func function_OR_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_OR_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_OR_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = OR(
        left: arg_0,
        right: arg_1
    )
    return try signature_OR_left_right.returnType.box(value: result, env: handlerEnv)
}


// XOR (left, right)
let signature_XOR_left_right = (
    paramType_0: asBool,
    paramType_1: asBool,
    returnType: asBool
)
let interface_XOR_left_right = CallableInterface(
    name: "XOR",
    parameters: [
        ("left", signature_XOR_left_right.paramType_0),
        ("right", signature_XOR_left_right.paramType_1),
    ],
    returnType: signature_XOR_left_right.returnType
)
func function_XOR_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_XOR_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_XOR_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = XOR(
        left: arg_0,
        right: arg_1
    )
    return try signature_XOR_left_right.returnType.box(value: result, env: handlerEnv)
}


// lt (left, right)
let signature_lt_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_lt_left_right = CallableInterface(
    name: "lt",
    parameters: [
        ("left", signature_lt_left_right.paramType_0),
        ("right", signature_lt_left_right.paramType_1),
    ],
    returnType: signature_lt_left_right.returnType
)
func function_lt_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_lt_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_lt_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try lt(
        left: arg_0,
        right: arg_1
    )
    return try signature_lt_left_right.returnType.box(value: result, env: handlerEnv)
}


// le (left, right)
let signature_le_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_le_left_right = CallableInterface(
    name: "le",
    parameters: [
        ("left", signature_le_left_right.paramType_0),
        ("right", signature_le_left_right.paramType_1),
    ],
    returnType: signature_le_left_right.returnType
)
func function_le_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_le_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_le_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try le(
        left: arg_0,
        right: arg_1
    )
    return try signature_le_left_right.returnType.box(value: result, env: handlerEnv)
}


// eq (left, right)
let signature_eq_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_eq_left_right = CallableInterface(
    name: "eq",
    parameters: [
        ("left", signature_eq_left_right.paramType_0),
        ("right", signature_eq_left_right.paramType_1),
    ],
    returnType: signature_eq_left_right.returnType
)
func function_eq_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_eq_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_eq_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try eq(
        left: arg_0,
        right: arg_1
    )
    return try signature_eq_left_right.returnType.box(value: result, env: handlerEnv)
}


// ne (left, right)
let signature_ne_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_ne_left_right = CallableInterface(
    name: "ne",
    parameters: [
        ("left", signature_ne_left_right.paramType_0),
        ("right", signature_ne_left_right.paramType_1),
    ],
    returnType: signature_ne_left_right.returnType
)
func function_ne_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_ne_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ne_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try ne(
        left: arg_0,
        right: arg_1
    )
    return try signature_ne_left_right.returnType.box(value: result, env: handlerEnv)
}


// gt (left, right)
let signature_gt_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_gt_left_right = CallableInterface(
    name: "gt",
    parameters: [
        ("left", signature_gt_left_right.paramType_0),
        ("right", signature_gt_left_right.paramType_1),
    ],
    returnType: signature_gt_left_right.returnType
)
func function_gt_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_gt_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_gt_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try gt(
        left: arg_0,
        right: arg_1
    )
    return try signature_gt_left_right.returnType.box(value: result, env: handlerEnv)
}


// ge (left, right)
let signature_ge_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asBool
)
let interface_ge_left_right = CallableInterface(
    name: "ge",
    parameters: [
        ("left", signature_ge_left_right.paramType_0),
        ("right", signature_ge_left_right.paramType_1),
    ],
    returnType: signature_ge_left_right.returnType
)
func function_ge_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_ge_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_ge_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try ge(
        left: arg_0,
        right: arg_1
    )
    return try signature_ge_left_right.returnType.box(value: result, env: handlerEnv)
}


// is_a (value, of_type)
let signature_isA_value_ofType = (
    paramType_0: asAnything,
    paramType_1: asCoercion,
    returnType: asBool
)
let interface_isA_value_ofType = CallableInterface(
    name: "is_a",
    parameters: [
        ("value", signature_isA_value_ofType.paramType_0),
        ("of_type", signature_isA_value_ofType.paramType_1),
    ],
    returnType: signature_isA_value_ofType.returnType
)
func function_isA_value_ofType(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_isA_value_ofType.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_isA_value_ofType.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = isA(
        value: arg_0,
        ofType: arg_1
    )
    return try signature_isA_value_ofType.returnType.box(value: result, env: handlerEnv)
}


// & (left, right)
let signature_joinValues_left_right = (
    paramType_0: asString,
    paramType_1: asString,
    returnType: asString
)
let interface_joinValues_left_right = CallableInterface(
    name: "&",
    parameters: [
        ("left", signature_joinValues_left_right.paramType_0),
        ("right", signature_joinValues_left_right.paramType_1),
    ],
    returnType: signature_joinValues_left_right.returnType
)
func function_joinValues_left_right(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_joinValues_left_right.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_joinValues_left_right.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try joinValues(
        left: arg_0,
        right: arg_1
    )
    return try signature_joinValues_left_right.returnType.box(value: result, env: handlerEnv)
}


// uppercase (text)
let signature_uppercase_text = (
    paramType_0: asString,
    returnType: asString
)
let interface_uppercase_text = CallableInterface(
    name: "uppercase",
    parameters: [
        ("text", signature_uppercase_text.paramType_0),
    ],
    returnType: signature_uppercase_text.returnType
)
func function_uppercase_text(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_uppercase_text.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = uppercase(
        text: arg_0
    )
    return try signature_uppercase_text.returnType.box(value: result, env: handlerEnv)
}


// lowercase (text)
let signature_lowercase_text = (
    paramType_0: asString,
    returnType: asString
)
let interface_lowercase_text = CallableInterface(
    name: "lowercase",
    parameters: [
        ("text", signature_lowercase_text.paramType_0),
    ],
    returnType: signature_lowercase_text.returnType
)
func function_lowercase_text(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_lowercase_text.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = lowercase(
        text: arg_0
    )
    return try signature_lowercase_text.returnType.box(value: result, env: handlerEnv)
}


// show (value)
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
func function_show_value(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_show_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    show(
        value: arg_0
    )
    return noValue
}


// format_code (value)
let signature_formatCode_value = (
    paramType_0: asAnything,
    returnType: asString
)
let interface_formatCode_value = CallableInterface(
    name: "format_code",
    parameters: [
        ("value", signature_formatCode_value.paramType_0),
    ],
    returnType: signature_formatCode_value.returnType
)
func function_formatCode_value(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_formatCode_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = formatCode(
        value: arg_0
    )
    return try signature_formatCode_value.returnType.box(value: result, env: handlerEnv)
}


// define_handler (name, parameters, return_type, action, is_event_handler)
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
func function_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
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


// store (name, value, readOnly)
let signature_store_name_value_readOnly_commandEnv = (
    paramType_0: asSymbolKey,
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
func function_store_name_value_readOnly_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
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


// if (condition, action)
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
func function_testIf_condition_action_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
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


// repeat (count, action)
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
func function_repeatTimes_count_action_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
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


// while (condition, action)
let signature_repeatWhile_condition_action_commandEnv = (
    paramType_0: asAnything,
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
func function_repeatWhile_condition_action_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
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


// else (action, alternative_action)
let signature_elseClause_action_alternativeAction_commandEnv = (
    paramType_0: asAnything,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_elseClause_action_alternativeAction_commandEnv = CallableInterface(
    name: "else",
    parameters: [
        ("action", signature_elseClause_action_alternativeAction_commandEnv.paramType_0),
        ("alternative_action", signature_elseClause_action_alternativeAction_commandEnv.paramType_1),
    ],
    returnType: signature_elseClause_action_alternativeAction_commandEnv.returnType
)
func function_elseClause_action_alternativeAction_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_elseClause_action_alternativeAction_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_elseClause_action_alternativeAction_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try elseClause(
        action: arg_0,
        alternativeAction: arg_1,
		commandEnv: commandEnv
    )
    return try signature_elseClause_action_alternativeAction_commandEnv.returnType.box(value: result, env: handlerEnv)
}


// of (attribute, value)
let signature_ofClause_attribute_value_commandEnv = (
    paramType_0: asAttribute,
    paramType_1: asAttributedValue,
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
func function_ofClause_attribute_value_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
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


// at (element_type, selector_data)
let signature_indexSelector_elementType_selectorData_commandEnv = (
    paramType_0: asSymbolKey,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_indexSelector_elementType_selectorData_commandEnv = CallableInterface(
    name: "at",
    parameters: [
        ("element_type", signature_indexSelector_elementType_selectorData_commandEnv.paramType_0),
        ("selector_data", signature_indexSelector_elementType_selectorData_commandEnv.paramType_1),
    ],
    returnType: signature_indexSelector_elementType_selectorData_commandEnv.returnType
)
func function_indexSelector_elementType_selectorData_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_indexSelector_elementType_selectorData_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_indexSelector_elementType_selectorData_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try indexSelector(
        elementType: arg_0,
        selectorData: arg_1,
		commandEnv: commandEnv
    )
    return try signature_indexSelector_elementType_selectorData_commandEnv.returnType.box(value: result, env: handlerEnv)
}


// named (element_type, selector_data)
let signature_nameSelector_elementType_selectorData_commandEnv = (
    paramType_0: asSymbolKey,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_nameSelector_elementType_selectorData_commandEnv = CallableInterface(
    name: "named",
    parameters: [
        ("element_type", signature_nameSelector_elementType_selectorData_commandEnv.paramType_0),
        ("selector_data", signature_nameSelector_elementType_selectorData_commandEnv.paramType_1),
    ],
    returnType: signature_nameSelector_elementType_selectorData_commandEnv.returnType
)
func function_nameSelector_elementType_selectorData_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_nameSelector_elementType_selectorData_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_nameSelector_elementType_selectorData_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try nameSelector(
        elementType: arg_0,
        selectorData: arg_1,
		commandEnv: commandEnv
    )
    return try signature_nameSelector_elementType_selectorData_commandEnv.returnType.box(value: result, env: handlerEnv)
}


// with_id (element_type, selector_data)
let signature_idSelector_elementType_selectorData_commandEnv = (
    paramType_0: asSymbolKey,
    paramType_1: asAnything,
    returnType: asIs
)
let interface_idSelector_elementType_selectorData_commandEnv = CallableInterface(
    name: "with_id",
    parameters: [
        ("element_type", signature_idSelector_elementType_selectorData_commandEnv.paramType_0),
        ("selector_data", signature_idSelector_elementType_selectorData_commandEnv.paramType_1),
    ],
    returnType: signature_idSelector_elementType_selectorData_commandEnv.returnType
)
func function_idSelector_elementType_selectorData_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_idSelector_elementType_selectorData_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_idSelector_elementType_selectorData_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try idSelector(
        elementType: arg_0,
        selectorData: arg_1,
		commandEnv: commandEnv
    )
    return try signature_idSelector_elementType_selectorData_commandEnv.returnType.box(value: result, env: handlerEnv)
}


// where (element_type, selector_data)
let signature_testSelector_elementType_selectorData_commandEnv = (
    paramType_0: asSymbolKey,
    paramType_1: asReference,
    returnType: asIs
)
let interface_testSelector_elementType_selectorData_commandEnv = CallableInterface(
    name: "where",
    parameters: [
        ("element_type", signature_testSelector_elementType_selectorData_commandEnv.paramType_0),
        ("selector_data", signature_testSelector_elementType_selectorData_commandEnv.paramType_1),
    ],
    returnType: signature_testSelector_elementType_selectorData_commandEnv.returnType
)
func function_testSelector_elementType_selectorData_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_testSelector_elementType_selectorData_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_testSelector_elementType_selectorData_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    let result = try testSelector(
        elementType: arg_0,
        selectorData: arg_1,
		commandEnv: commandEnv
    )
    return try signature_testSelector_elementType_selectorData_commandEnv.returnType.box(value: result, env: handlerEnv)
}


// thru (from, to)
let signature_Range_from_to = (
    paramType_0: asValue,
    paramType_1: asValue,
    returnType: asIs
)
let interface_Range_from_to = CallableInterface(
    name: "thru",
    parameters: [
        ("from", signature_Range_from_to.paramType_0),
        ("to", signature_Range_from_to.paramType_1),
    ],
    returnType: signature_Range_from_to.returnType
)
func function_Range_from_to(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    let arg_0 = try signature_Range_from_to.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_Range_from_to.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
    return Range(
        from: arg_0,
        to: arg_1
    )
}


func stdlib_loadHandlers(env: Env) throws {
    
    try env.add(interface_exponent_left_right, function_exponent_left_right)
    try env.add(interface_positive_left, function_positive_left)
    try env.add(interface_negative_left, function_negative_left)
    try env.add(interface_add_left_right, function_add_left_right)
    try env.add(interface_subtract_left_right, function_subtract_left_right)
    try env.add(interface_multiply_left_right, function_multiply_left_right)
    try env.add(interface_divide_left_right, function_divide_left_right)
    try env.add(interface_div_left_right, function_div_left_right)
    try env.add(interface_mod_left_right, function_mod_left_right)
    try env.add(interface_isLessThan_left_right, function_isLessThan_left_right)
    try env.add(interface_isLessThanOrEqualTo_left_right, function_isLessThanOrEqualTo_left_right)
    try env.add(interface_isEqualTo_left_right, function_isEqualTo_left_right)
    try env.add(interface_isNotEqualTo_left_right, function_isNotEqualTo_left_right)
    try env.add(interface_isGreaterThan_left_right, function_isGreaterThan_left_right)
    try env.add(interface_isGreaterThanOrEqualTo_left_right, function_isGreaterThanOrEqualTo_left_right)
    try env.add(interface_NOT_right, function_NOT_right)
    try env.add(interface_AND_left_right, function_AND_left_right)
    try env.add(interface_OR_left_right, function_OR_left_right)
    try env.add(interface_XOR_left_right, function_XOR_left_right)
    try env.add(interface_lt_left_right, function_lt_left_right)
    try env.add(interface_le_left_right, function_le_left_right)
    try env.add(interface_eq_left_right, function_eq_left_right)
    try env.add(interface_ne_left_right, function_ne_left_right)
    try env.add(interface_gt_left_right, function_gt_left_right)
    try env.add(interface_ge_left_right, function_ge_left_right)
    try env.add(interface_isA_value_ofType, function_isA_value_ofType)
    try env.add(interface_joinValues_left_right, function_joinValues_left_right)
    try env.add(interface_uppercase_text, function_uppercase_text)
    try env.add(interface_lowercase_text, function_lowercase_text)
    try env.add(interface_show_value, function_show_value)
    try env.add(interface_formatCode_value, function_formatCode_value)
    try env.add(interface_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv, function_defineHandler_name_parameters_returnType_action_isEventHandler_commandEnv)
    try env.add(interface_store_name_value_readOnly_commandEnv, function_store_name_value_readOnly_commandEnv)
    try env.add(interface_testIf_condition_action_commandEnv, function_testIf_condition_action_commandEnv)
    try env.add(interface_repeatTimes_count_action_commandEnv, function_repeatTimes_count_action_commandEnv)
    try env.add(interface_repeatWhile_condition_action_commandEnv, function_repeatWhile_condition_action_commandEnv)
    try env.add(interface_elseClause_action_alternativeAction_commandEnv, function_elseClause_action_alternativeAction_commandEnv)
    try env.add(interface_ofClause_attribute_value_commandEnv, function_ofClause_attribute_value_commandEnv)
    try env.add(interface_indexSelector_elementType_selectorData_commandEnv, function_indexSelector_elementType_selectorData_commandEnv)
    try env.add(interface_nameSelector_elementType_selectorData_commandEnv, function_nameSelector_elementType_selectorData_commandEnv)
    try env.add(interface_idSelector_elementType_selectorData_commandEnv, function_idSelector_elementType_selectorData_commandEnv)
    try env.add(interface_testSelector_elementType_selectorData_commandEnv, function_testSelector_elementType_selectorData_commandEnv)
    try env.add(interface_Range_from_to, function_Range_from_to)
}
