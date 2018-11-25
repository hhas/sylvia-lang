//
//  stdlib_coercions.swift
//

import Foundation


/******************************************************************************/
// COERCIONS
/******************************************************************************/

// TO DO: unlike primitive handlers, bridging coercions must be manually implemented in Swift; however, it may be possible to auto-generate the glue code that enables them to be added to stdlib's env and call()-ed from native code with additional constraints, e.g. `list(text,min:1,max:10)`. Currently, Coercion.init() requires constraints to be supplied as Swift values, but 'convenience' bridging initializers could be added via code-generated extensions that perform the requisite unboxing (ideally using extant Coercion classes assuming it doesn't all get ridiculously circular); conversely, Coercion objects should be able to emit their own construction code as both native commands and Swift code, for use in pretty printing and Swift code generation respectively.


func stdlib_loadCoercions(env: Env) throws {
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

func stdlib_loadConstants(env: Env) throws {
    try env.set("nothing", to: noValue) // TO DO: should `nothing` be both Value and TYPE? e.g. `foo() returning errorOr(nothing)`? (note: primitive handlers use `asNothing` as signature's return type to indicate no return value, in which case bridge code generator changes return statement to `return noValue`)
    try env.set("π", to: piValue) // Q. should `π` slot always evaluate to `π` symbol (with asTYPE methods converting it to Double when required)? (Swift, Python, AppleScript, etc define `pi` constant as numeric [64-bit float] value, 3.1415…, which is technically correct [enough], but aesthetically less helpful when displayed; Q. what other values might have different symbolic Text vs raw data representations? [currently true/false constants, though those will probably go away])
    
    // not sure if defining true/false constants is a good idea; if using 'emptiness' to signify true/false, having `true`/`false` constants that evaluate to anything other than `true`/`false` is liable to create far more confusion than convenience (one option is to define a formal Boolean value class and use that, but that raises questions on how to coerce it to text - it can't go to "true"/"false", as "false" is non-empty text, so would have to go to "ok"/"" which is unintuitive; another option is to copy Swift's approach where *only* true/false can be used in Boolean contexts, but that doesn't fit well with weak typing behavior; last alternative is to do away with true/false constants below and never speak of them again; note that only empty text and lists should be treated as Boolean false; 1 and 0 would both be true since both are represented as non-empty text, whereas strongly typed languages such as Python can treat 0 as false; the whole point of weak typing being to roundtrip data without changing its meaning even as its representation changes)
    try env.set("true", to: trueValue)
    try env.set("false", to: falseValue)
}
