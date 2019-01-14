//
//  list.swift
//



class List: Value { // TO DO: how best to represent ordered (Array) vs key-value (Dictionary) vs unique (Set) lists? subclasses? internal enum?
    
    override var description: String { return "\(self.swiftValue)" } // note: this assumes native `[…,…]` list syntax is same as Swift Array syntax; if that changes then use "[\(self.swiftValue.map{$0.description}.joined(separator:","))]" // TO DO: pretty printer needs to support line wrapping and indentation of long lists
    
    override class var nominalType: Coercion { return asList }
    
    private(set) var swiftValue: [Value]
    
    init(_ swiftValue: [Value]) {
        self.swiftValue = swiftValue
    }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        return try List(self.swiftValue.map {
            do {
                return try $0.nativeEval(env: env, coercion: coercion)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion).from(error)
            }
        })
    }
    
    override func toList(env: Scope, coercion: AsList) throws -> List {
        return try List(self.swiftValue.map {
            do {
                return try $0.nativeEval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors, i.e. `[nothing] as list(optional) => [nothing]`, but `[nothing] as optional => CoercionError`
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)  // TO DO: more detailed error message indicating which list item couldn't be evaled
            }
        })
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        return try self.swiftValue.map {
            do {
                return try $0.bridgingEval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)
            }
        }
    }
}


// convenience constants

let emptyList = List([])
