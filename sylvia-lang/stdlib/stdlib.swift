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
// HANDLERS
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
// I/O

// TO DO: when working with streams, would it be better for bridging code to pass required pipes to call_NAME functions as explicit arguments? need to give some thought to read/write model: e.g. rather than implicitly accessing stdin/stdout/stderr/FS/network/etc pipes directly (as `print` does here), 'mount' them in local/global namespace as Values which can be manipulated via standard get/set operations (note: the value's 'type' should be inferred where practical, e.g. from filename extension/MIME type where available, or explicitly indicated in `attach` command, enabling appropriate transcoders to be automatically found and used) (TO DO: Q. could coercions be used to attach transcoders, avoiding need for special-purpose command? e.g. `let mountPoint = someURL as atomFeed`; i.e. closer we can keep to AEOM/REST semantics of standard verbs + arbitrary resource types, more consistent, composable, and learnable the whole system will be)

// signature: show(value: anything)
// requirements: [stdout]

func show(value: Value) { // primitive library function
    // TO DO: this should eventually be replaced with a native handler: `show(value){write(code(value),to:system.stdout)}`
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


/******************************************************************************/
// control flow


// asBool, AsThunk()

func testIf(value: Bool, ifTrue: Thunk, ifFalse: Thunk) throws -> Value {
    return try (value ? ifTrue : ifFalse).force() // TO DO: it'll be cheaper to use asIs + commandEnv + asAnything.coerce() rather than thunking (Thunks are really only needed to capture lazily evaluated parameters in native handlers), but let's test them here for now
} // TO DO: consider using Icon-style evaluation, where there is only `test` + `ifTrue` parameters, and `didNothing` ('fail') is returned when test is false; that result can then be captured by an `else` operator, or coerced to `nothing` otherwise (advantage of this approach is more granular, composable code; e.g. `else` could also be applied to a `repeatWhile()` command to execute alternative branch if zero iterations are performed)


/******************************************************************************/
// COERCIONS
/******************************************************************************/

// TO DO: unlike primitive handlers, bridging coercions must be manually implemented in Swift; however, it may be possible to auto-generate the glue code that enables them to be added to stdlib's env and call()-ed from native code with additional constraints, e.g. `list(text,min:1,max:10)`. Currently, Coercion.init() requires constraints to be supplied as Swift values, but 'convenience' bridging initializers could be added via code-generated extensions that perform the requisite unboxing (ideally using extant Coercion classes assuming it doesn't all get ridiculously circular); conversely, Coercion objects should be able to emit their own construction code as both native commands and Swift code, for use in pretty printing and Swift code generation respectively.


func loadCoercions(env: Env) throws {

    try env.add(asAnything)
    try env.add(asValue)
    
    try env.add(asText)
    try env.add(asBool)
    try env.add(asDouble)
    
    try env.add(asList)
    
    try env.add(AsDefault(asAnything, noValue)) // note: AsDefault requires constraint args (type and defaultValue) to instantiate; native language will call() it to create new instances with appropriate constraints
}


/******************************************************************************/
// CONSTANTS
/******************************************************************************/

// TO DO: what constants should stdlib define?

func loadConstants(env: Env) throws {
    try env.set("nothing", to: noValue)
    try env.set("π", to: piValue)
    
    // not sure if defining true/false constants is a good idea; if using 'emptiness' to signify true/false, having `true`/`false` constants that evaluate to anything other than `true`/`false` is liable to create far more confusion than convenience (one option is to define a formal Boolean value class and use that, but that raises questions on how to coerce it to text - it can't go to "true"/"false", as "false" is non-empty text, so would have to go to "ok"/"" which is unintuitive; another option is to copy Swift's approach where *only* true/false can be used in Boolean contexts, but that doesn't fit well with weak typing behavior; last alternative is to do away with true/false constants below and never speak of them again; note that only empty text and lists should be treated as Boolean false; 1 and 0 would both be true since both are represented as non-empty text, whereas strongly typed languages such as Python can treat 0 as false; the whole point of weak typing being to roundtrip data without changing its meaning even as its representation changes)
    try env.set("true", to: trueValue)
    try env.set("false", to: falseValue)
}
