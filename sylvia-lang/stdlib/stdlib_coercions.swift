//
//  stdlib_coercions.swift
//

// TO DO: unlike primitive handlers, bridging coercions must be manually implemented in Swift; however, it may be possible to auto-generate the glue code that enables them to be added to stdlib's env and call()-ed from native code with additional constraints, e.g. `list(text,min:1,max:10)`. Currently, Coercion.init() requires constraints to be supplied as Swift values, but 'convenience' bridging initializers could be added via code-generated extensions that perform the requisite unboxing (ideally using extant Coercion classes assuming it doesn't all get ridiculously circular); conversely, Coercion objects should be able to emit their own construction code as both native commands and Swift code, for use in pretty printing and Swift code generation respectively.


/******************************************************************************/
// COERCIONS
/******************************************************************************/

// used in `at`, `named`, etc commands/operator, where left operand is an Identifier

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

    
func stdlib_loadCoercions(env: Env) throws {
    try env.add(asValue)
    try env.add(asText)
    try env.add(asBool)
    try env.add(asDouble)
    try env.add(asList)
    
    try env.add(asCoercion)
    
    try env.add(asAnything)
    try env.add(asNoResult)
    
    try env.add(asAnything)
    try env.add(AsDefault(asAnything, noValue) as Coercion) // note: AsDefault requires constraint args (coercion and defaultValue) to instantiate; native language will call() it to create new instances with appropriate constraints
}

