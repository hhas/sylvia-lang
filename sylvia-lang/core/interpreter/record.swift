//
//  record.swift
//

// TO DO: start thinking about implementing mutability via `editable` coercion modifier; also, when a value is immutable, what operations can still be performed (e.g. joining strings/lists/records using `&` always creates a new value, but appending would fail); Q. how to get to point where mutable values can support AEOM-style queries ((ELEMENTS where TEST) of VALUE) and commands (move, delete, etc). By default, new values are immutable, so need coerced to `editable` which performs copy operation [if it's an AST node or otherwise already shared] and marks it as editable so that subsequent coercions to editable do not copy again; Q. at what point should editable value coerce back to immutable? (e.g. when returning from handler that doesn't specify `editable` return type). Easiest way to implement editability might to wrap [copied] value in an Editable instance that implements `get()`/`set()` that tunnel all operations, including mutable ones, to underlying value. Editable would also implement `asTYPE` methods that return unwrapped copy of the underlying value when non-Editable coercion is applied; i.e. much like Thunk wrappers are explicitly created (`VALUE as lazy`) and only persist until next non-thunking coercion is applied.


// TO DO: consider simplifying Record to disallow Expressions as keys; while `[foo:1, bar():2]` is a valid dictionary literal in Swift (and in Python, etc), it's unlikely to appear in real-world use (standard idiom for populating a dict with parameterized keys would be `dict[keyVar]=valueVar`, often in a loop); in fact, deliberately rejecting `[foo:1]` as invalid syntax is likely to catch many more problems than it causes, as it's most likely a typo for `[#foo:1]`

// TO DO: AsDictionary<> bridging coercions will want option to specify key type (Text/Tag/String/Key/TagKey/mixed) as well as value type

// TO DO: should AsKey [normalized String] be modifier around AsText/AsTag? (and probably AsIdentifier/AsCommand)



class Record: Value {
    
    enum Storage { // internal storage allows keys to be unevaluated expressions, prior to the record being used
        
        typealias Dict = [RecordKey: Value]
        
        case pairs([Pair])
        case dict(Dict) // keys are Text or Tag
        
        var description: String { // caution: this assumes Record syntax is identical to Swift dictionary syntax
            switch self {
            case .pairs(let data): return data.count == 0 ? "[:]" : String(describing: data)
            case .dict (let data): return data.count == 0 ? "[:]" : String(describing: data.map{ Pair($0.value, $1) })
            }
        }
    }
    
    override var description: String { return self.storage.description }
    
    // TO DO: pretty printer needs to support line wrapping and indentation of long lists
    
    override class var nominalType: Coercion { return asRecord }
    
    private var storage: Storage // any items with non-literal keys; these will be resolved at evaluation and transferred to dict of returned value
    
    override init() {
        self.storage = .dict([RecordKey: Value]())
    }
    
    init(_ pairs: [Pair]) { // used by parser when (literal) record contains one or more unevaluated (Expression) keys
        self.storage = .pairs(pairs)
    }
    
    init(_ dict: [RecordKey: Value]) { // use when record is empty/all keys are hashable (Text/Tag)
        self.storage = .dict(dict)
    }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        switch self.storage {
        case .pairs(let data):
            return Record(Dictionary(uniqueKeysWithValues: try data.map({ (pair: Pair) -> (RecordKey, Value) in
                    try (pair.swiftValue.name.bridgingEval(env: env, coercion: asRecordKey),
                         pair.swiftValue.value.nativeEval(env: env, coercion: asAnything)) }))) as Value // TO DO: what should coercion arg be here?
        case .dict(let data):
            return Record(try data.mapValues({ try $0.nativeEval(env: env, coercion: asAnything) })) // TO DO: what should coercion arg be here?
        }
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
        do {
            switch self.storage {
            case .pairs(let data):
                return try List(data.map { (pair: Pair) throws -> Value in
                    do {
                        return try pair.nativeEval(env: env, coercion: coercion.elementType)
                    } catch { // note: NullCoercionErrors thrown by individual items must be rethrown as permanent errors
                        throw CoercionError(value: pair, coercion: coercion.elementType).from(error)
                    }
                })
            case .dict(let data):
                return try List(data.map { (key: RecordKey, value: Value) throws -> Value in
                    let pair = Pair(key.value, value)
                    do {
                        return try pair.nativeEval(env: env, coercion: coercion.elementType)
                    } catch {
                        throw CoercionError(value: pair, coercion: coercion.elementType).from(error)
                    }
                })
            }
        } catch {
            throw CoercionError(value: self, coercion: coercion).from(error)
        }
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
        do {
            switch self.storage {
            case .pairs(let data):
                return try Record(Dictionary(uniqueKeysWithValues: data.map{ (pair: Pair) throws -> (RecordKey, Value) in
                    do {
                        return try (pair.key.bridgingEval(env: env, coercion: asRecordKey),
                                    pair.value.nativeEval(env: env, coercion: coercion.valueType))
                    } catch { // note: NullCoercionErrors thrown by individual items must be rethrown as permanent errors
                        throw CoercionError(value: pair, coercion: coercion.valueType).from(error)
                    }
                }))
            case .dict(let data):
                return try Record(Dictionary(uniqueKeysWithValues: data.map{ (key: RecordKey, value: Value) throws -> (RecordKey, Value) in
                    do {
                        return try (key.value.bridgingEval(env: env, coercion: asRecordKey),
                                    value.nativeEval(env: env, coercion: coercion.valueType))
                    } catch {
                        throw CoercionError(value: Pair(key.value, value), coercion: coercion.valueType).from(error)
                    }
                }))
            }
        } catch {
            throw CoercionError(value: self, coercion: coercion).from(error)
        }

    }
    
    override func toDictionary<K: BridgingCoercion, V: BridgingCoercion, T: AsDictionary<K,V>>(env: Scope, coercion: T) throws -> [K.SwiftType:V.SwiftType] {
        fatalError()
    }
}



// convenience constants

let emptyRecord = Record()
