//
//  stdlib/handlers/state.swift
//


// signature: defineCommandHandler(name: primitive(text), parameters: default([], parametersList), result: default(anything, coercion), body: primitive(expression)) returning handler
// requires: throws, commandEnv // any required env params are appended to bridging call in standard order (commandEnv,handlerEnv,bodyEnv)

// TO DO: need asParameterList coercion that knows how to parse user-defined parameters list (which may consist of label strings and/or (label,coercion) tuples, and may include optional description strings too)

// TO DO: what about varargs/arbitrary args? (that will presumably require a [Native/Primitive]RawArgumentHandler class, which assigns the entire argument tuple as an unprocessed list for the handler to process itself [note that such handlers will not support automatic introspection beyond providing handler name])

func defineHandler(name: String, parameters: [Parameter], returnType: Coercion, action: Value, isEventHandler: Bool, commandEnv: Scope) throws {
    let  h = NativeHandler(CallableInterface(name: name, parameters: parameters, returnType: returnType), action, isEventHandler)
    try commandEnv.add(h)
}

// TO DO: will need separate `to` and `when` (`upon`?) operators/commands for defining native (and primitive?) handlers; the `to ACTION` form (used to implement new commands) should throw on unknown arguments, the `when EVENT` form (used to declare event handlers) should ignore them (this allows event handlers to receive notifications while ignoring any arguments not of interest to them; this'll be of more use once labeled arguments/parameters are supported) (strictly speaking, the `when` form is redundant if handlers accept varargs, e.g. in Python: `def EVENT(*args,**kargs)` will accept and discard unwanted arguments silently; however, it's semantically clearer); Q. how should event handlers deal with return values (forbid? discard? return? notifications don't normally expect return values, with occasional exceptions, e.g. `shouldCloseDocument` returning true/false to permit/cancel document closing)

// signature: store(name: primitive(text), value: anything, readOnly: default(true, boolean)) returning anything
// requires: throws, commandEnv

func store(name: String, value: Value, readOnly: Bool, commandEnv: Scope) throws -> Value { // TO DO: take Identifier as `name`?
    try commandEnv.set(name.lowercased(), to: value, readOnly: readOnly, thisFrameOnly: false) // TO DO: optional args in protocol
    return value
}

