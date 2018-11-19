//
//  stdlib_bridge
//

// TO DO: once language is fully bootstrapped, LIBRARY_bridge.swift files should be 100% code-generated from native interface declarations; hopefully this can be done using existing syntax and operators/commands, the only difference is that when running IDC scripts, FFILib is loaded *instead of* (on top of?) stdlib, redefining the standard `define…Handler` and `store` commands to emit LIBNAME_bridge.swift code instead of modifying env

/*
 
 TO DO: primitive handler signatures should be defined using same syntax as for native handlers; only differences are that parameter+result coercions must be specified, and any 'external' resource requirements must be indicated so that bridging code generator can add the necessary parameters to the func call (all this info will also be used in auto-generated user documentation, and in [optimising] native-to-Swift cross-compilation of user 'scripts')
 
 */

// TO DO: consider supporting .nonMutating/.mutatesOnce/.mutating flags for indicating side effects ('mutatesOnce' = idempotent; once called, subsequent identical calls have no additional effect)


// auto-generated primitive handler bridging code

// add(a,b)
let signature_add_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_add_a_b = CallableInterface( // TO DO: include all documentation, metainfo
    name: "+",
    parameters: [
        ("a", signature_add_a_b.paramType_0),
        ("b", signature_add_a_b.paramType_1)
    ],
    returnType: signature_add_a_b.returnType
)
func call_add_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_add_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_add_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try add(a: arg_0, b: arg_1)
    return try signature_add_a_b.returnType.box(value: result, env: handlerEnv)
    // TO DO: how best to auto-annotate the returned Text value with the Swift result value (in this case Double)?
}


// subtract(a,b)
let signature_subtract_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_subtract_a_b = CallableInterface(
    name: "-",
    parameters: [
        ("a", signature_subtract_a_b.paramType_0),
        ("b", signature_subtract_a_b.paramType_1)
    ],
    returnType: signature_subtract_a_b.returnType
)
func call_subtract_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_subtract_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_subtract_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try subtract(a: arg_0, b: arg_1)
    return try signature_subtract_a_b.returnType.box(value: result, env: handlerEnv)
}


// multiply(a,b)
let signature_multiply_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_multiply_a_b = CallableInterface(
    name: "×",
    parameters: [
        ("a", signature_multiply_a_b.paramType_0),
        ("b", signature_multiply_a_b.paramType_1)
    ],
    returnType: signature_multiply_a_b.returnType
)
func call_multiply_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_multiply_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_multiply_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try multiply(a: arg_0, b: arg_1)
    return try signature_multiply_a_b.returnType.box(value: result, env: handlerEnv)
}


// divide(a,b)
let signature_divide_a_b = (
    paramType_0: asDouble,
    paramType_1: asDouble,
    returnType: asDouble
)
let interface_divide_a_b = CallableInterface(
    name: "÷",
    parameters: [
        ("a", signature_divide_a_b.paramType_0),
        ("b", signature_divide_a_b.paramType_1)
    ],
    returnType: signature_divide_a_b.returnType
)
func call_divide_a_b(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_divide_a_b.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_divide_a_b.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try divide(a: arg_0, b: arg_1)
    return try signature_divide_a_b.returnType.box(value: result, env: handlerEnv)
}


// show(value)
let signature_show_value = (
    paramType_0: asAnything,
    returnType: asNothing
)
let interface_show_value = CallableInterface(
    name: "show",
    parameters: [("value", signature_show_value.paramType_0)],
    returnType: signature_show_value.returnType
)
func call_show_value(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_show_value.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    show(value: arg_0)
    return noValue
}


// store(name,value,readOnly)
let signature_store_name_value_readOnly = (
    paramType_0: asString,
    paramType_1: asValue,
    paramType_2: asBool, // TO DO: use enum? (while not relevant to Env itself, .writeOnly could be used for e.g. a `password` property on an external resource)
    returnType: asValue
)
let interface_store_name_value_readOnly = CallableInterface(
    name: "store", // TO DO: what name?
    parameters: [("value", signature_store_name_value_readOnly.paramType_0)],
    returnType: signature_store_name_value_readOnly.returnType
)
func call_store_name_value_readOnly(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_store_name_value_readOnly.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_store_name_value_readOnly.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let arg_2 = try signature_store_name_value_readOnly.paramType_2.unboxArgument(at: 2, command: command, commandEnv: commandEnv, handler: handler)
    let result = try store(name: arg_0, value: arg_1, readOnly: arg_2, commandEnv: commandEnv)
    return try signature_store_name_value_readOnly.returnType.box(value: result, env: handlerEnv)
}


// defineCommandHandler(name,parameters,result,body)
let signature_defineCommandHandler_name_parameters_returnType_body = (
    paramType_0: asString,
    paramType_1: AsArray(asString), // TO DO: currently doesn't support coercions
    paramType_2: asValue, // coercion object
    paramType_3: asIs,
    returnType: asValue // TO DO: returning Handler may be a bad idea as it won't be bound to its current context
)
let interface_defineCommandHandler_name_parameters_returnType_body = CallableInterface(
    name: "to", // TO DO: what name?
    parameters: [("value", signature_defineCommandHandler_name_parameters_returnType_body.paramType_0)],
    returnType: signature_defineCommandHandler_name_parameters_returnType_body.returnType
)
func call_defineCommandHandler_name_parameters_returnType_body(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_defineCommandHandler_name_parameters_returnType_body.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_defineCommandHandler_name_parameters_returnType_body.paramType_1.unbox(value: command.argument(1), env: commandEnv) .map{return(name:$0,type:asValue as Coercion)} // KLUDGE; TO DO: define AsParameter coercion
    let arg_2 = try signature_defineCommandHandler_name_parameters_returnType_body.paramType_2.unbox(value: command.argument(2), env: commandEnv) as! Coercion // KLUDGE; TO DO: define AsCoercion coercion
    let arg_3 = try signature_defineCommandHandler_name_parameters_returnType_body.paramType_3.unboxArgument(at: 3, command: command, commandEnv: commandEnv, handler: handler)
    let result = try defineCommandHandler(name: arg_0, parameters: arg_1, returnType: arg_2, body: arg_3, commandEnv: commandEnv)
    return try signature_defineCommandHandler_name_parameters_returnType_body.returnType.box(value: result, env: handlerEnv)
}


// testIf(value,ifTrue,ifFalse)
let signature_testIf_value_ifTrue_ifFalse = (
    paramType_0: asBool,
    paramType_1: asThunk,
    paramType_2: asThunk,
    returnType: asIs // should check this
)
let interface_testIf_value_ifTrue_ifFalse = CallableInterface(
    name: "if", // TO DO: what name?
    parameters: [
        ("value", signature_testIf_value_ifTrue_ifFalse.paramType_0),
        ("ifTrue", signature_testIf_value_ifTrue_ifFalse.paramType_1),
        ("ifFalse", signature_testIf_value_ifTrue_ifFalse.paramType_2)
    ],
    returnType: signature_testIf_value_ifTrue_ifFalse.returnType
)
func call_testIf_value_ifTrue_ifFalse(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_testIf_value_ifTrue_ifFalse.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_testIf_value_ifTrue_ifFalse.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let arg_2 = try signature_testIf_value_ifTrue_ifFalse.paramType_2.unboxArgument(at: 2, command: command, commandEnv: commandEnv, handler: handler)
    let result = try testIf(value: arg_0, ifTrue: arg_1, ifFalse: arg_2, commandEnv: commandEnv)
    return try signature_testIf_value_ifTrue_ifFalse.returnType.box(value: result, env: handlerEnv)
}


// repeatTimes(count,expr)
let signature_repeatTimes_count_expr = (
    paramType_0: asInt,
    paramType_1: asIs,
    returnType: asIs // should check this
)
let interface_repeatTimes_count_expr = CallableInterface(
    name: "repeat", // TO DO: what name?
    parameters: [
        ("count", signature_repeatTimes_count_expr.paramType_0),
        ("expr", signature_repeatTimes_count_expr.paramType_1),
        ],
    returnType: signature_repeatTimes_count_expr.returnType
)
func call_repeatTimes_count_expr(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {
    let arg_0 = try signature_repeatTimes_count_expr.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
    let arg_1 = try signature_repeatTimes_count_expr.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
    let result = try repeatTimes(count: arg_0, expr: arg_1, commandEnv: commandEnv)
    return try signature_repeatTimes_count_expr.returnType.box(value: result, env: handlerEnv)
}


// auto-generated module load function

// TO DO: how should external entry point be named/declared?

func stdlib_load(env: Env) throws {
    
    // TO DO: what about operator aliases? operator-sugared handlers must (currently?) be stored under operator's canonical name, which is not necessarily the same as primitive function's canonical name
    
    // TO DO: catch and rethrow as ImportError?
    
    // TO DO: this adds directly to supplied env rather than creating its own; Q. who should be responsible for creating module namespaces? (and who is responsible for adding modules to a global namespace where scripts can access them); Q. what is naming convention for 3rd-party modules? (e.g. reverse domain), and how will those modules appear in namespace (e.g. flat/custom name or hierarchical names [e.g. `com.foo.module[.handler]`])
    
    // TO DO: loading should never fail (unless there's a module implementation bug, e.g. duplicate name); how practical to guarantee error-free module loading, in which case LIBNAME_load can be non-throwing?
    
    // TO DO: ideally these load calls would only
    try loadConstants(env: env)
    try loadCoercions(env: env)
    
    try env.add(interface_add_a_b, call_add_a_b)
    try env.add(interface_subtract_a_b, call_subtract_a_b)
    try env.add(interface_multiply_a_b, call_multiply_a_b)
    try env.add(interface_divide_a_b, call_divide_a_b)
    try env.add(interface_show_value, call_show_value)
    try env.add(interface_store_name_value_readOnly, call_store_name_value_readOnly)
    try env.add(interface_defineCommandHandler_name_parameters_returnType_body, call_defineCommandHandler_name_parameters_returnType_body)
    try env.add(interface_testIf_value_ifTrue_ifFalse, call_testIf_value_ifTrue_ifFalse)
    try env.add(interface_repeatTimes_count_expr, call_repeatTimes_count_expr)
    
}


