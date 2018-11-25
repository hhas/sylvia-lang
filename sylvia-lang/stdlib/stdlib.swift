//
//  stdlib.swift
//

/*
 Primitive libraries are implemented as Swift funcs that follow standardized naming and parameter/return conventions; all bridging code is auto-generated. Clean separation of native/bridging/primitive logic has big advantages over Python/Ruby/etc-style modules where primitive functions must perform all their own bridging:
 
 - faster, simpler, less error-prone development of primitive libraries
 
 - auto-generated API documentation
 
 - optimizing cross-compilation to Swift (e.g. when composing two primitive functions that return/accept same Swift type, boxing/unboxing steps can be skipped)
 */


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

// TO DO: use Icon-style behavior for comparison operators? this'd allow comparison operations to be chained, e.g. `0 < x <= 10` (on success, returns right-hand operand as-is [this includes empty values]; on failure, returns 'noComparison' flag which causes subequent comparisons to return noComparison as well)


// signature: add(a: primitive(double), b: primitive(double)) returning primitive(double)
// requirements: throws // TO DO: should `throws` be declared as part of return type: `errorOr(RETURNTYPE)`? (optionally including list of error type[s] where known?)

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

// signature: isEqualTo(a: primitive(double), b: primitive(double)) returning primitive(boolean)

func isLessThan(a: Double, b: Double) -> Bool { return a < b }
func isLessThanOrEqualTo(a: Double, b: Double) -> Bool { return a <= b }
func isEqualTo(a: Double, b: Double) -> Bool { return a == b }
func isNotEqualTo(a: Double, b: Double) -> Bool { return a != b }
func isGreaterThan(a: Double, b: Double) -> Bool { return a > b }
func isGreaterThanOrEqualTo(a: Double, b: Double) -> Bool { return a >= b }

// Boolean logic
func NOT(a: Bool) -> Bool { return !a }
func AND(a: Bool, b: Bool) -> Bool { return a && b }
func  OR(a: Bool, b: Bool) -> Bool { return a || b }
func XOR(a: Bool, b: Bool) -> Bool { return a && !b || !a && b }


/******************************************************************************/
// general

// for now, implement for string only; longer term, these should accept optional type:Coercion parameter (e.g. `A eq B as list of caseSensitiveText`) to standardize argument types before comparison, and call type-specific comparison methods on Values (ideally a default type would be inferred where practical, e.g. if it is known that two lists of text are being compared, the default type would be `list(text)`); the goal is to avoid inconsistent behavior during comparisons, particularly lt/le/gt/ge; a typical example would be in sorting a mixed list where comparison behavior changes from item to item according to operand type(s)

// comparison
func lt(a: String, b: String) throws -> Bool { return a.lowercased() <  b.lowercased() }
func le(a: String, b: String) throws -> Bool { return a.lowercased() <= b.lowercased() }
func eq(a: String, b: String) throws -> Bool { return a.lowercased() == b.lowercased() }
func ne(a: String, b: String) throws -> Bool { return a.lowercased() != b.lowercased() }
func gt(a: String, b: String) throws -> Bool { return a.lowercased() >  b.lowercased() }
func ge(a: String, b: String) throws -> Bool { return a.lowercased() >= b.lowercased() }

// concatenation (currently text only but should support collections too)
func joinValues(a: String, b: String) throws -> String { return a + b }


/******************************************************************************/
// text manipulation

func uppercase(a: String) -> String { return a.uppercased() }
func lowercase(a: String) -> String { return a.lowercased() }


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
// TO DO: rename `defineHandler` and take extra `options:.command/.event` parameter
func defineHandler(name: String, parameters: [Parameter], returnType: Coercion, action: Value, isEventHandler: Bool, commandEnv: Env) throws {
    let  h = Handler(CallableInterface(name: name, parameters: parameters, returnType: returnType), action, isEventHandler)
    try commandEnv.add(h)
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

// TO DO: implement Icon-like evaluation, where there is only `test` + `action` parameters, and `didNothing` ('fail') is returned when test is false; that result can then be captured by an `else` operator, or coerced to `nothing` otherwise (advantage of this approach is more granular, composable code; e.g. `else` could also be applied to a `repeatWhile()` command to execute alternative branch if zero iterations are performed)

// note: while primitive functions can use Thunks for lazily evaluated arguments, it's cheaper just to pass the command's arguments as-is plus the command's environment and evaluate directly

func testIf(condition: Bool, action: Value, commandEnv: Env) throws -> Value {
    return try condition ? asAnything.coerce(value: action, env: commandEnv) : didNothing
}

func repeatTimes(count: Int, action: Value, commandEnv: Env) throws -> Value {
    var count = count
    var result: Value = didNothing
    while count > 0 {
        result = try asAnything.coerce(value: action, env: commandEnv)
        count -= 1
    }
    return result
}

func repeatWhile(condition: Value, action: Value, commandEnv: Env) throws -> Value {
    var result: Value = didNothing // TO DO: returning `didNothing` (implemented as subclass of NoValue?) will allow composition with infix `else` operator (ditto for `if`, etc); need to figure out precise semantics for this (as will NullCoercionErrors, the extent to which such a value can propagate must be strictly limited, with the value converting to noValue if not caught and handled immediately; one option is to define an `AsDidNothing(TYPE)` coercion which can unbox/coerce the nothing as a special case, e.g. returning a 2-case enum/returning didNothing rather than coercing it to noValue [which asAnything/asOptional/asDefault should do])
    while try asBool.unbox(value: condition, env: commandEnv) {
        result = try asAnything.coerce(value: action, env: commandEnv)
    }
    return result
}

