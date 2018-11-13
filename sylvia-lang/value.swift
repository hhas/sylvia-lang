//
//  value.swift
//
//  native datatypes; these should have literal representations
//



// abstract base class

class Value: CustomStringConvertible { // base class for all native values
    
    var description: String { return "<Value>" }
    
    // double-dispatch methods
    
    func toAny(env: Env, type: Coercion) throws -> Value { // collection subclasses override this to recursively evaluate items
        return self
    }
    
    // concrete subclasses must override the following as appropriate
    
    func toText(env: Env, type: Coercion) throws -> Text { // re. type parameter: Coercion is assumed to be AsText, but may be AsString or other type as long as its coerce() method returns Text (would be good to get this strongly typed, but need to decide inheritance hierarchy for Coercion types)
        throw CoercionError(value: self, type: type)
    }
    
    // List subclass overrides the following; other values coerce to single-item list/array (V->[V]):
    
    func toList(env: Env, type: AsList) throws -> List {
        return try List([type.elementType.coerce(value: self, env: env)])
    }
    
    func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try [type.elementType.unbox(value: self, env: env)]
    }
    
}


// concrete classes


class Nothing: Value {
    
    override var description: String { return "nothing" }
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        throw NullCoercionError(value: self, type: type)
    }
    override func toText(env: Env, type: Coercion) throws -> Text {
        throw NullCoercionError(value: self, type: type)
    }
    override func toList(env: Env, type: AsList) throws -> List {
        throw NullCoercionError(value: self, type: type)
    }
    override func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        throw NullCoercionError(value: self, type: type)
    }
}



class Text: Value { // TO DO: Scalar?
    
    override var description: String { return "“\(self.swiftValue)”" } // TO DO: pretty printing
    
    private(set) var swiftValue: String // TO DO: restricted mutability; e.g. perform appends in-place only if refcount==1, else copy self and append to that
    
    init(_ swiftValue: String) {
        self.swiftValue = swiftValue
    }
    
    override func toText(env: Env, type: Coercion) throws -> Text {
        return self
    }
}


class List: Value {
    
    override var description: String { return "\(self.swiftValue)" }
    
    private(set) var swiftValue: [Value]
    
    init(_ swiftValue: [Value]) {
        self.swiftValue = swiftValue
    }
    
    override func toList(env: Env, type: AsList) throws -> List {
        return try List(self.swiftValue.map { try type.elementType.coerce(value: $0, env: env) })
    }
    
    override func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try self.swiftValue.map { try type.elementType.unbox(value: $0, env: env) }
    }
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return try List(self.swiftValue.map { try type.coerce(value: $0, env: env) })
    }
}


// other native values might include Nothing, Number (if distinct from Text), Symbol, Table, Expression, Call, Thunk, etc.; downside is each new native type requires another `toType()` method added to Value and to each subclass that supports that coercion (though these can at least be organized into class extensions so don't clog up the main class implementations)





// convenience constants


let noValue = Nothing()
let emptyText = Text("")
let emptyList = List([])
