//
//  stdlib_coercions.swift
//

// TO DO: unlike primitive handlers, bridging coercions must be manually implemented in Swift; however, it may be possible to auto-generate the glue code that enables them to be added to stdlib's env and call()-ed from native code with additional constraints, e.g. `list(text,min:1,max:10)`. Currently, Coercion.init() requires constraints to be supplied as Swift values, but 'convenience' bridging initializers could be added via code-generated extensions that perform the requisite unboxing (ideally using extant Coercion classes assuming it doesn't all get ridiculously circular); conversely, Coercion objects should be able to emit their own construction code as both native commands and Swift code, for use in pretty printing and Swift code generation respectively.


/******************************************************************************/
// COERCIONS
/******************************************************************************/

// TO DO: check if/where this is still needed? (may be best to use asTagKey in commands such as `store` and `at`)

class AsAttributeName: BridgingCoercion { // TO DO: unboxing here may be problematic
    
    var coercionName: String { return "identifier" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = String
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try asIdentifierLiteral.coerce(value: value, env: env)
    }
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let result = (value as? Identifier)?.key else { throw CoercionError(value: value, coercion: self) }
        return result
    }
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Identifier(value)
    }
}

let asAttributeName = AsAttributeName()


/******************************************************************************/

    
func stdlib_loadCoercions(env: Environment) throws {
    try env.add(coercion: asValue)
    try env.add(coercion: asText)
    try env.add(coercion: asBool)   // TO DO: need to decide if native Boolean representation should be `true`/`false` constants or non-empty/empty values
    try env.add(coercion: asDouble) // TO DO: really want `asNumber` and `asWholeNumber`
    try env.add(coercion: asList)
    try env.add(coercion: asRecord)
    
    try env.add(coercion: asCoercion)
    
    try env.add(coercion: asAnything)
    try env.add(coercion: asNoResult) // by default, a native handler will return the result of the last expression evaluated; use `…returning no_result` to suppress that so that it always returns `nothing` (note that while using `return nothing` would give same the runtime result, declaring it via signature makes it clear and informs introspection and documentation tools as well)
    
    try env.add(coercion: AsDefault(asAnything, noValue)) // note: AsDefault requires constraint args (coercion and defaultValue) to instantiate; native language will call() it to create new instances with appropriate constraints
}

