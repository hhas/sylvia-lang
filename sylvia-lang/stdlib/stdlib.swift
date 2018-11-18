//
//  stdlib.swift
//

/*
 
 Primitive libraries are implemented as Swift funcs that follow standardized naming and parameter/return conventions; all bridging code is auto-generated. Clean separation of native/bridging/primitive logic has big advantages over Python/Ruby/etc-style modules where primitive functions must perform all their own bridging:
 
    - faster, simpler, less error-prone development of primitive libraries
 
    - auto-generated API documentation
 
    - optimizing cross-compilation to Swift (e.g. when composing two primitive functions that return/accept same Swift type, boxing/unboxing steps can be skipped)
 
 */


// TO DO: to what extent can/should primitive funcs be declared public, allowing optimizing cross-compiler to discard native<->Swift conversions and bypass PrimitiveHandler implementation whenever practical? e.g. `Command("add",[Text("1"),Text("2")])` should cross-compile to `try stdlib.add(a:1,b:2)` (note that even when full reductions can't be done due to insufficient detail/partial type matches, lesser reductions can still be achieved using coercion info from PrimitiveHandler's introspection APIs, e.g. `try asDouble.box(stdlib.add(a:asDouble.unbox(…),b:asDouble.unbox(…)),…)` would save an Env lookup and some function calls, at cost of less precise error messages when a non-numeric value is passed as argument); the final optimization step would be to eliminate the library call entirely and insert templated Swift code directly (this is mostly useful for standard arithmetic and conditional operators, and conditional, loop, and error handling blocks, which are both simple and frequent enough to warrant the extra code generation logic, at least in stdlib)


/******************************************************************************/
// HANDLERS
/******************************************************************************/
// math

// signature: add(a: primitive(double), b: primitive(double)) returning primitive(double)
// requires: throws

func add(a: Double, b: Double) throws -> Double { // TO DO: math funcs should use Scalars (union of Int|UInt|Double) (e.g. pinch Scalar struct from entoli) allowing native language to have a single unified `number` type (numeric values might themselves be represented in runtime as Text value annotated with scalar info for efficiency, or as distinct Number values that can be coerced to/from Text) (note that while arithmetic/comparison library funcs will have to work with Scalars in order to handle both ints and floats, Swift code generation could reduce overheads when both arguments are known to be ints, in which case it'll output`a+b`, otherwise `Double(a)+Double(b)`)
    return a + b // TO DO: check how Double signals out-of-range
}

func subtract(a: Double, b: Double) throws -> Double { // for now, use Doubles; eventually there should be a generalized Number type/annotation that encapsulates Int|UInt|Double, and eventually BigInt, Decimal, Quantity, etc
    return a - b
}

func multiply(a: Double, b: Double) throws -> Double {
    return a * b
}

func divide(a: Double, b: Double) throws -> Double {
    return a / b
}


/******************************************************************************/
// I/O

// TO DO: when working with streams, would it be better for bridging code to pass required pipes to call_NAME functions as explicit arguments? need to give some thought to read/write model: e.g. rather than implicitly accessing stdin/stdout/stderr/FS/network/etc pipes directly (as `print` does here), 'mount' them in local/global namespace as Values which can be manipulated via standard get/set operations (note: the value's 'type' should be inferred where practical, e.g. from filename extension/MIME type where available, or explicitly indicated in `attach` command, enabling appropriate transcoders to be automatically found and used) (TO DO: Q. could coercions be used to attach transcoders, avoiding need for special-purpose command? e.g. `let mountPoint = someURL as atomFeed`; i.e. closer we can keep to AEOM/REST semantics of standard verbs + arbitrary resource types, more consistent, composable, and learnable the whole system will be)

// signature: show(value: anything)
// requires: stdout

func show(value: Value) { // primitive library function
    // TO DO: this should eventually be replaced with a native handler: `show(value){write(code(value),to:system.stdout)}`
    print(value)
}


/******************************************************************************/
// state

// signature: defineHandler(name: primitive(text), parameters: default([], parametersList), result: default(anything, type), body: primitive(expression)) returning handler
// requires: throws, commandEnv // any required env params are appended to bridging call in standard order (commandEnv,handlerEnv,bodyEnv)

// TO DO: need asParameterList coercion that knows how to parse user-defined parameters list (which may consist of label strings and/or (label,coercion) tuples, and may include optional description strings too)
func defineHandler(name: String, parameters: [Parameter], returnType: Coercion, body: Value, commandEnv: Env) throws -> Handler {
    let  h = Handler(CallableInterface(name: name, parameters: parameters, returnType: returnType), body)
    try commandEnv.add(h)
    return h
}

// TO DO: will need separate `to` and `when` (`upon`?) operators/commands for defining native (and primitive?) handlers; the `to ACTION` form (used to implement new commands) should throw on unknown arguments, the `when EVENT` form (used to declare event handlers) should ignore them (this allows event handlers to receive notifications while ignoring any arguments not of interest to them; this'll be of more use once labeled arguments/parameters are supported) (strictly speaking, the `when` form is redundant if handlers accept varargs, e.g. in Python: `def EVENT(*args,**kargs)` will accept and discard unwanted arguments silently; however, it's semantically clearer)

// signature: store(name: primitive(text), value: anything, readOnly: default(true, boolean)) returning anything
// requires: throws, commandEnv

func store(name: String, value: Value, readOnly: Bool, commandEnv: Env) throws -> Value {
    try commandEnv.set(name, to: value, readOnly: readOnly)
    return value
}


/******************************************************************************/
// control flow

// TO DO: consider using Icon-style evaluation, where there is only `test` + `ifTrue` parameters, and `didNothing` ('fail') is returned when test is false; that result can then be captured by an `else` operator, or coerced to `nothing` otherwise (advantage of this approach is more granular, composable code; e.g. `else` could also be applied to a `repeatWhile()` command to execute alternative branch if zero iterations are performed)

// note: while primitive functions can use Thunks for lazily evaluated arguments, it's cheaper just to pass the command's arguments as-is plus the command's environment and evaluate directly

func testIf(value: Bool, ifTrue: Value, ifFalse: Value, commandEnv: Env) throws -> Value {
    return try asAnything.coerce(value: (value ? ifTrue : ifFalse), env: commandEnv)
}

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
