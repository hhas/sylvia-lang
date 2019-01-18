//
//  stdlib/handlers/state.swift
//


// signature: defineCommandHandler(name as unboxed(text), parameters as default([], parametersList), result as default(anything, coercion), body as expression) returning handler
// requires: throws, commandEnv // any required env params are appended to bridging call in standard order (commandEnv,handlerEnv,bodyEnv)

// TO DO: need asParameterList coercion that knows how to parse user-defined parameters list (which may consist of label strings and/or (label,coercion) tuples, and may include optional description strings too)

// TO DO: what about varargs/arbitrary args? (that will presumably require a [Native/Primitive]RawArgumentHandler class, which assigns the entire argument tuple as an unprocessed list for the handler to process itself [note that such handlers will not support automatic introspection beyond providing handler name])

// TO DO: update parameters to support

func defineHandler(name: String, parameters: [Parameter], returnType: Coercion, action: Value, isEventHandler: Bool, commandEnv: Scope) throws {
    let  h = NativeHandler(CallableInterface(name: name, parameters: parameters, returnType: returnType), action, isEventHandler)
    try commandEnv.add(h)
}

// TO DO: will need separate `to` and `when` (`upon`?) operators/commands for defining native (and primitive?) handlers; the `to ACTION` form (used to implement new commands) should throw on unknown arguments, the `when EVENT` form (used to declare event handlers) should ignore them (this allows event handlers to receive notifications while ignoring any arguments not of interest to them; this'll be of more use once labeled arguments/parameters are supported) (strictly speaking, the `when` form is redundant if handlers accept varargs, e.g. in Python: `def EVENT(*args,**kargs)` will accept and discard unwanted arguments silently; however, it's semantically clearer); Q. how should event handlers deal with return values (forbid? discard? return? notifications don't normally expect return values, with occasional exceptions, e.g. `shouldCloseDocument` returning true/false to permit/cancel document closing)

// signature: store(name as unboxed(text), value as anything, readOnly as unboxed(default(true, boolean))) returning anything
// requires: throws, commandEnv

func store(key: String, value: Value, readOnly: Bool, commandEnv: Scope) throws -> Value {
    try commandEnv.set(key, to: value, readOnly: readOnly, thisFrameOnly: false) // TO DO: one drawback of passing String key rather than Symbol here is that slot name will appear in error messages as all-lowercase, rather than preserving original case
    return value
}



func coerce(value: Value, coercion: Coercion, commandEnv: Scope) throws -> Value {
    return try value.nativeEval(env: commandEnv, coercion: coercion) // TO DO: check this
}


func tell(target: AttributedValue, action: Value, commandEnv: Scope) throws -> Value {
    let env = TargetScope(target, parent: commandEnv)
    return try action.nativeEval(env: env, coercion: asAnything) // TO DO: how to get coercion info?
}


