//
//  record.swift
//

// TO DO: start thinking about implementing mutability via `editable` coercion modifier; also, when a value is immutable, what operations can still be performed (e.g. joining strings/lists/records using `&` always creates a new value, but appending would fail); Q. how to get to point where mutable values can support AEOM-style queries ((ELEMENTS where TEST) of VALUE) and commands (move, delete, etc). By default, new values are immutable, so need coerced to `editable` which performs copy operation [if it's an AST node or otherwise already shared] and marks it as editable so that subsequent coercions to editable do not copy again; Q. at what point should editable value coerce back to immutable? (e.g. when returning from handler that doesn't specify `editable` return type). Easiest way to implement editability might to wrap [copied] value in an Editable instance that implements `get()`/`set()` that tunnel all operations, including mutable ones, to underlying value. Editable would also implement `asTYPE` methods that return unwrapped copy of the underlying value when non-Editable coercion is applied; i.e. much like Thunk wrappers are explicitly created (`VALUE as lazy`) and only persist until next non-thunking coercion is applied.


// TO DO: split this into 2 implementations, one with [AnyHashable: Value] storage (for new, empty values and literal values where all keys are known) and one with [Pairs] storage (for literal values where one or more keys are Expressions so cannot be determined until runtime)


class Record: Value {
    
    
    enum Storage {
        
        typealias Dict = [AnyHashable: Value]
        
        case pairs([Pair])
        case dict(Dict) // keys are Text or Tag
        
        var description: String {
            switch self {
            case .pairs(let data): return data.count > 0 ? String(describing: data) : "[:]"
            case .dict (let data): return data.count > 0 ? "[\(data.map{ Pair($0.base as! Value, $1) })]" : "[:]"
            }
        }
    }
    
    
    override var description: String { return self.storage.description }
    
    // TO DO: pretty printer needs to support line wrapping and indentation of long lists
    
    override class var nominalType: Coercion { return asRecord }
    
    private var storage: Storage // any items with non-literal keys; these will be resolved at evaluation and transferred to dict of returned value
    
    override init() {
        self.storage = .dict([AnyHashable: Value]())
    }
    
    init(_ pairs: [Pair]) throws { // used by parser when (literal) record contains one or more unevaluated (Expression) keys
        self.storage = .pairs(pairs)
    }
    
    init(_ dict: [AnyHashable: Value]) throws { // use when record is empty/all keys are hashable Text/Tag
        self.storage = .dict(dict)
    }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        var result = Storage.Dict()
        switch self.storage {
        case .pairs(let data):
            ()
        case .dict(let data):
            ()
        }
        return self // TO DO
        /*
        return try List(self.swiftValue.map {
            do {
                return try $0.nativeEval(env: env, coercion: coercion)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion).from(error)
            }
        })
         */
    }
    
    override func toList(env: Scope, coercion: AsList) throws -> List {
        fatalError()
        /*
        return try List(self.swiftValue.map {
            do {
                return try $0.nativeEval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors, i.e. `[nothing] as list(optional) => [nothing]`, but `[nothing] as optional => CoercionError`
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)  // TO DO: more detailed error message indicating which list item couldn't be evaled
            }
        })*/
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        fatalError()
        /*
        return try self.swiftValue.map {
            do {
                return try $0.bridgingEval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)
            }
        }
         */
    }
    
    override func toRecord(env: Scope, coercion: AsRecord) throws -> Record {
        fatalError()
    }
}



// convenience constants

let emptyRecord = Record()
