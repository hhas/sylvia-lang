//
//  list.swift
//



class List: Value, SwiftWrapper {
    
    override var description: String { // TO DO: pretty printer needs to support line wrapping and indentation of long lists
        return "[\(self.swiftValue.map{ $0 is Pair ? "(\($0))" : "\($0)" }.joined(separator:", "))]"
    }
    
    override class var nominalType: Coercion { return asList }
    
    private(set) var swiftValue: [Value]
    
    init(_ swiftValue: [Value]) {
        self.swiftValue = swiftValue
    }
    
    override convenience init() {
        self.init([])
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
    
    override func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        return self.swiftValue.count == 0 ? falseValue : trueValue
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
