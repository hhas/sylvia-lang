//
//  stdlib.swift
//

/*
 
 Note: primitive libraries are implemented as Swift funcs that follow standardized naming and parameter/return conventions; all bridging code is auto-generated. Clean separation of native/bridging/primitive logic has big advantages over Python/Ruby/etc-style modules where primitive functions must perform all their own bridging:
 
    - faster, simpler, less error-prone development of primitive libraries
 
    - free API documentation
 
    - free partial optimizing compilation (e.g. when composing two primitive functions that return/accept same Swift type, boxing/unboxing steps can be skipped)
 
 */



/******************************************************************************/
// math

// signature: add(a: primitive(double), b: primitive(double)) returning primitive(double)
// requirements: [throws]

func add(a: Double, b: Double) throws -> Double { // TO DO: math funcs should use Scalars (union of Int|UInt|Double) (e.g. pinch Scalar struct from entoli) allowing native language to have a single unified `number` type (numeric values might themselves be represented in runtime as Text value annotated with scalar info for efficiency, or as distinct Number values that can be coerced to/from Text) (note that while arithmetic/comparison library funcs will have to work with Scalars in order to handle both ints and floats, Swift code generation could reduce overheads when both arguments are known to be ints, in which case it'll output`a+b`, otherwise `Double(a)+Double(b)`)
    return a + b // TO DO: check how Double signals out-of-range
}

func subtract(a: Double, b: Double) throws -> Double { // for now, use Doubles; eventually there should be a generalized Number type/annotation that encapsulates Int|UInt|Double, and eventually BigInt, Decimal, Quantity, etc
    return a - b
}


/******************************************************************************/
// misc

// signature: show(value: anything)
// requirements: [stdout]

// TO DO: would it be better to pass explicitly required pipes as arguments? need to give some thought to read/write model; rather than accessing std/FS/network pipes directly, 'mount' them in local/global namespace as Values which can be manipulated via standard get/set operations (note: the value's 'type' should be inferred where practical, e.g. from filename extension/MIME type where available, or explicitly indicated in `attach` command, enabling appropriate transcoders to be automatically found and used)

func show(value: Value) { // primitive library function
    print(value)
}


/******************************************************************************/
// state

// signature: defineHandler(name: primitive(text), parameters: default([], parametersList), result: default(anything, type), body: primitive(expression)) returning handler
// requirements: [commandEnv] // any required env params are appended to bridging call in standard order (commandEnv,handlerEnv,bodyEnv)

// TO DO: need asParameterList coercion that knows how to parse user-defined parameters list (which may consist of label strings and/or (label,coercion) tuples, and may include optional description strings too)
func defineHandler(name: String, parameters: [Parameter], result: Coercion, body: Value, commandEnv: Env) throws -> Handler {
    let  h = Handler(name: name, parameters: parameters, result: result, body: body)
    try commandEnv.add(h)
    return h
}


// signature: store(name: primitive(text), value: anything, readOnly: default(true, boolean)) returning anything
// requirements: [commandEnv]

func store(name: String, value: Value, readOnly: Bool, commandEnv: Env) throws -> Value {
    try commandEnv.set(name, to: value, readOnly: readOnly)
    return value
}

