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


import Darwin


/******************************************************************************/
// HANDLERS
/******************************************************************************/
// math

// TO DO: math funcs should use Scalars (union of Int|UInt|Double) (e.g. pinch Scalar struct from entoli) allowing native language to have a single unified `number` type (numeric values might themselves be represented in runtime as Text value annotated with scalar info for efficiency, or as distinct Number values that can be coerced to/from Text) (note that while arithmetic/comparison library funcs will have to work with Scalars in order to handle both ints and floats, Swift code generation could reduce overheads when both arguments are known to be ints, in which case it'll output`a+b`, otherwise `Double(a)+Double(b)`) // for now, use Doubles; eventually there should be a generalized Number type/annotation that encapsulates Int|UInt|Double, and eventually BigInt, Decimal, Quantity, etc
//
// TO DO: should math funcs ever throw, or should outOfRange/divideByZero be captured by Scalar?
//
// TO DO: check how Int/Double signals out-of-range


// signature: exponent(a: primitive(double), b: primitive(double)) returning primitive(double)
// requires: throws

func exponent(a: Double, b: Double) throws -> Double { return pow(a, b) }
func positive(a: Double) throws -> Double { return +a }
func negative(a: Double) throws -> Double { return -a }
func add(a: Double, b: Double) throws -> Double { return a + b }
func subtract(a: Double, b: Double) throws -> Double { return a - b }
func multiply(a: Double, b: Double) throws -> Double { return a * b }
func divide(a: Double, b: Double) throws -> Double { return a / b }
func div(a: Double, b: Double) throws -> Double { return Double(Int(a / b)) }
func mod(a: Double, b: Double) throws -> Double { return a.truncatingRemainder(dividingBy: b) }

// math comparison
func isLessThan(a: Double, b: Double) throws -> Bool { return a < b }
func isLessThanOrEqualTo(a: Double, b: Double) throws -> Bool { return a <= b }
func isEqualTo(a: Double, b: Double) throws -> Bool { return a == b }
func isNotEqualTo(a: Double, b: Double) throws -> Bool { return a != b }
func isGreaterThan(a: Double, b: Double) throws -> Bool { return a > b }
func isGreaterThanOrEqualTo(a: Double, b: Double) throws -> Bool { return a >= b }


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

// signature: defineCommandHandler(name: primitive(text), parameters: default([], parametersList), result: default(anything, type), body: primitive(expression)) returning handler
// requires: throws, commandEnv // any required env params are appended to bridging call in standard order (commandEnv,handlerEnv,bodyEnv)

// TO DO: need asParameterList coercion that knows how to parse user-defined parameters list (which may consist of label strings and/or (label,coercion) tuples, and may include optional description strings too)
func defineCommandHandler(name: String, parameters: [Parameter], returnType: Coercion, body: Value, commandEnv: Env) throws -> Handler {
    let  h = Handler(CallableInterface(name: name, parameters: parameters, returnType: returnType), body)
    try commandEnv.add(h)
    return h
}

// TO DO: will need separate `to` and `when` (`upon`?) operators/commands for defining native (and primitive?) handlers; the `to ACTION` form (used to implement new commands) should throw on unknown arguments, the `when EVENT` form (used to declare event handlers) should ignore them (this allows event handlers to receive notifications while ignoring any arguments not of interest to them; this'll be of more use once labeled arguments/parameters are supported) (strictly speaking, the `when` form is redundant if handlers accept varargs, e.g. in Python: `def EVENT(*args,**kargs)` will accept and discard unwanted arguments silently; however, it's semantically clearer); Q. how should event handlers deal with return values (forbid? discard? return? notifications don't normally expect return values, with occasional exceptions, e.g. `shouldCloseDocument` returning true/false to permit/cancel document closing)

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

func testIf(value: Bool, ifTrue: Value, ifFalse: Value, commandEnv: Env) throws -> Value { // TO DO: eliminate `ifFalse` parameter and return `didNothing` (`noAction`?) if value is false; this allows `if` to be defined as standard `if EXPR BLOCK` operator, which can be arbitrarily chained using `A else B` operator
    return try asAnything.coerce(value: (value ? ifTrue : ifFalse), env: commandEnv)
}

func repeatTimes(count: Int, expr: Value, commandEnv: Env) throws -> Value {
    var count = count
    var result: Value = noValue
    while count > 0 {
        result = try asAnything.coerce(value: expr, env: commandEnv)
        count -= 1
    }
    return result
}

func repeatWhile(condition: Value, expr: Value, commandEnv: Env) throws -> Value {
    var result: Value = noValue // TO DO: returning `didNothing` (implemented as subclass of NoValue?) will allow composition with infix `else` operator (ditto for `if`, etc); need to figure out precise semantics for this (as will NullCoercionErrors, the extent to which such a value can propagate must be strictly limited, with the value converting to noValue if not caught and handled immediately; one option is to define an `AsDidNothing(TYPE)` coercion which can unbox/coerce the nothing as a special case, e.g. returning a 2-case enum/returning didNothing rather than coercing it to noValue [which asAnything/asOptional/asDefault should do])
    while try asBool.unbox(value: condition, env: commandEnv) {
        result = try asAnything.coerce(value: expr, env: commandEnv)
    }
    return result
}

