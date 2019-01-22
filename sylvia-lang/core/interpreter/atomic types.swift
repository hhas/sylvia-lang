//
//  atomic types.swift
//

// TO DO: how best to indicate which coercions are exposed in stdlib slots, and which are only exposed in FFI_lib slots? (thinking that `primitive()` modifier should provide access to all BridgingCoercions, including those that are solely for boxing/unboxing specialized Swift types - asFloat, asUInt, asInt64, etc - whereas stdlib would expose only those that make sense to language users - e.g. asText, asNumber, asInteger, etc - and have obvious Swift equivalents)

// Q. how to bridge Swift enum, tuple types? (tuple BridgingCoercions might be implemented as generics, where implementor supplies their own box/unbox functions to init(); enum coercion constructor might take an array/dict of (STRING,CASE) pairs and build runtime mapping tables from that)



class AsValue: BridgingCoercion { // any value *except* `nothing`
    
    var coercionName: String { return "value" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toAny(env: env, coercion: self)
    }
}


class AsString: BridgingCoercion { // Q. what about constraints?
    
    var coercionName: String { return "string" }
    
    override var description: String { return self.coercionName } // TO DO: all coercion descriptions should be coercionName + any constraints (probably simplest to implement HandlerProtocol and asCommandLiteral() first, then generate description string from Command)
    
    typealias SwiftType = String
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toText(env: env, coercion: self)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toText(env: env, coercion: self).swiftValue // TO DO: worth implementing Value.toString()->String?
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(value)
    }
}


class AsScalar: BridgingCoercion {
    
    var coercionName: String { return "number" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Scalar
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let result = try value.toText(env: env, coercion: self)
        let _ = try result.toScalar()
        return result
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toText(env: env, coercion: self).toScalar()
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(value.literalRepresentation(), scalar: value)
    }
}


class AsInt: BridgingCoercion {
    
    var coercionName: String { return "whole_number" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Int
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let result = try value.toText(env: env, coercion: self)
        if Int(result.swiftValue) == nil { throw CoercionError(value: value, coercion: self) } // note: this only validates; it doesn't rewrite (Q. should it return `Text(String(n))`?) // TO DO: FIX: use toScalar().toInt(); see AsDouble below
        return result
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let n = try Int(value.toText(env: env, coercion: self).swiftValue) else { throw CoercionError(value: value, coercion: self) } // TO DO: FIX: ditto
        return n
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(String(value))
    }
}


class AsDouble: BridgingCoercion {
    
    var coercionName: String { return "number" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Double
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let result = try value.toText(env: env, coercion: self)
        do {
            let _ = try result.toScalar().toDouble() // TO DO: should toScalar be non-throwing (in which case just have lazy-initializing `scalar` ivar), and rely on toDouble() to do all throwing [since 'scalar' ivar should be .invalid after first use]
        } catch {
            throw CoercionError(value: value, coercion: self)
        }
        // TO DO: implement `Value.toScalar()` method? or do all text-to-number/date/whatever conversion work in Coercion methods (Q. what about quantities, dates, URLs, and other data nominally represented as text?)
//        guard let number = Double(result.swiftValue) else {  } // note: this only validates; it doesn't rewrite (Q. should it return `Text(String(n))`?)
        return result
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        //guard let n = try Double(value.toText(env: env, coercion: self).swiftValue) else { throw CoercionError(value: value, coercion: self) }
        let result = try value.toText(env: env, coercion: self)
        let n: Double
        do {
            n = try result.toScalar().toDouble()
        } catch {
            throw CoercionError(value: value, coercion: self)
        }
        return n
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(String(value), scalar: Scalar(value))
    }
}


class AsBool: BridgingCoercion {
    
    var coercionName: String { return "boolean" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Bool
    
    // TO DO: implement `Value.toBool()` and use that (right now this implementation only accepts text/nothing and errors on lists)
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try value.toText(env: env, coercion: self).swiftValue != "" ? trueValue : falseValue
        } catch is NullCoercionError {
            return falseValue
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try value.toText(env: env, coercion: self).swiftValue != ""
        } catch is NullCoercionError {
            return false
        }
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value ? trueValue : falseValue
    }
}



// TO DO: Variant should be separate Coercion class (Q. how will Variant support Swift types? needs to use enum)


// native coercions; these may be used as bridging coercions where a Swift function works with native values

class AsText: BridgingCoercion { // Q. what about constraints? // TO DO: would be nice to share common constraint-checking code, though not sure how best to do that
    
    var coercionName: String { return "string" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Text
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toText(env: env, coercion: self)
    }
}


class AsTag: BridgingCoercion {
    
    var coercionName: String { return "tag" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Tag
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toTag(env: env, coercion: self)
    }
}


class AsTagKey: BridgingCoercion { // returns normalized String, suitable for case-insensitive comparison // TO DO: rename AsKey?
    
    var coercionName: String { return "tag" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = String
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toTag(env: env, coercion: self)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toTag(env: env, coercion: self).key
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Tag(value)
    }
}


class AsRecordKey: BridgingCoercion {

    var coercionName: String { return "record_key" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = RecordKey
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env).value // kludgy
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toRecordKey(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value.value
    }
}

