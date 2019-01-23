//
//  nothing.swift
//


class Nothing: Value {
    
    override var description: String { return "no_value" }
    
    override class var nominalType: Coercion { return asNoResult }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toTag(env: Scope, coercion: Coercion) throws -> Tag {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toList(env: Scope, coercion: AsList) throws -> List {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toArray<E, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        throw NullCoercionError(value: self, coercion: coercion)
    }
}



class DidNothing: Nothing { // temporary value returned by flow control operations (`if`, `while`) to indicate no action was performed; may be immediately intercepted by `else` clause to perform alternate action, otherwise should be replaced by standard `no_value` so it does not propagate any further
    
    override var description: String { return "did_nothing" }
    
}



// convenience constants


let noValue = Nothing()
let didNothing = DidNothing()


