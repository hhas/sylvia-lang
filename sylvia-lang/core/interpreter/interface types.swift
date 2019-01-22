//
//  interface types.swift
//


/******************************************************************************/
// coercions


class AsCoercion: BridgingCoercion {
    
    var coercionName: String { return "coercion" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Coercion
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let result = try value.toAny(env: env, coercion: self) as? Coercion else { throw CoercionError(value: value, coercion: self) }
        return result
    }
}



/******************************************************************************/
// value attributes


class AsAttributedValue: BridgingCoercion { // a value that implements the `get()` (slot lookup) protocol
    
    var coercionName: String { return "attributed_value" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = AttributedValue
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        let result = try value.toAny(env: env, coercion: self)
        guard let value = result as? AttributedValue else { throw CoercionError(value: result, coercion: self) }
        return value
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}



class AsAttribute: BridgingCoercion { // an identifier/command (i.e. a value whose name can be used in get() protocol)
    
    var coercionName: String { return "attribute" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        switch value {
        case is Identifier, is Command:
            return value
        case is Tag: // also accept Tag as shorthand, e.g. `#FOO of KV_LIST` is converted to `item #FOO of KV_LIST`
            return Command("item", [value])
        default:
            throw CoercionError(value: value, coercion: self)
        }
    }
}


/******************************************************************************/
// handler signatures


class AsParameter: BridgingCoercion {
    
    var coercionName: String { return "parameter" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Parameter
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toAny(env: env, coercion: self) // TO DO: FIX
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        // `to`/`when` operator expects each parameter to be declared as `IDENTIFIER` or `IDENTIFIER as COERCION` and decomposes it automatically to `[IDENTIFIER]` or `[IDENTIFIER, COERCION]` (TO DO: eventually these should be KV-list or record [assuming we implement a first-class tuple/record datatype to maintain homoiconicity])
        let fields: [Value]
        if let list = value as? List { fields = list.swiftValue } else { fields = [value] } // kludge; we don't want to expand Identifier
        let coercion: Coercion
        switch fields.count {
        case 1: // name only
            coercion = asValue // any value except `nothing` (as that is used for optional params)
        case 2: // name + coercion
            coercion = try asCoercion.unbox(value: fields[1], env: env)
        // TO DO: support optional label
        default:
            throw CoercionError(value: value, coercion: self)
        }
        guard let label = (fields[0] as? Text)?.swiftValue else { throw CoercionError(value: value, coercion: self) }
        let binding = label // TO DO: FIX; use binding name if given, else use label
        return (label: label, binding: binding, coercion: coercion)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return List([Text(value.label), value.coercion])
    }
}


class AsNoResult: Coercion { // value is evaluated and its result discarded; noValue is returned (used in primitive handler coercion sigs when handler returns no result)
    
    var coercionName: String { return "no_value" } // TO DO: can/should this be merged with Nothing value class, allowing `nothing` to describe both 'no value' and 'no [return] coercion'? (A. this would be problematic, as `defineHandler`'s `returnType` parameter should be able to distinguish omitted argument [indicating it should use `asValue`] from 'returns nothing')
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        let _ = try asAnything.coerce(value: value, env: env)
        return noValue
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return noValue
    }
}
