//
//  collection types.swift
//


// List

class AsArray<ElementCoercion: BridgingCoercion>: BridgingCoercion {
    
    var coercionName: String { return "list" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }
    
    typealias SwiftType = [ElementCoercion.SwiftType]
    
    let elementType: ElementCoercion
    
    init(_ elementType: ElementCoercion) { // TO DO: optional min/max length constraints
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toList(env: env, coercion: AsList(self.elementType)) // TO DO: reboxing AsArray coercion as AsList is smelly; the problem is that toList() requires coercion parameter to be AsList (which allows it to get coercion.elementType); Q. can Value.toList()'s coercion parameter use AsListProtocol instead of AsList?
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toArray(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return try List(value.map { try self.elementType.box(value: $0, env: env) })
    }
}



// native-only coercion // TO DO: worth making this BridgingCoercion to Array<Value>?

class AsList: CallableCoercion {
    
    var coercionName: String { return "list" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }

    let elementType: Coercion
    
    init(_ elementType: Coercion) {
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toList(env: env, coercion: self)
    }
    
    // TO DO: simplify the following and [partially?] move to extension; should some/all of it be code-generated?
    
    let signature = (
        paramType_0: asCoercion,
        _na: asNoResult // TO DO: Swift 4/5 breaks on single-item tuples; probably simplest to use separate var for each parameter
    )
    
    lazy private(set) var interface = HandlerInterface(
        name: self.coercionName,
        parameters: [
            ("item_type", "parameterType", signature.paramType_0)
        ],
        returnType: asCoercion)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let arg_0 = try self.signature.paramType_0.unboxArgument("item_type", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return AsList(arg_0)
    }
}



// Record

class AsDictionary<KeyCoercion: BridgingCoercion, ValueCoercion: BridgingCoercion>: BridgingCoercion where KeyCoercion.SwiftType: Hashable {
    
    var coercionName: String { return "record" }
    
    override var description: String { return "\(self.coercionName)(\(self.valueType),\(self.keyType))" }
    
    typealias SwiftType = [KeyCoercion.SwiftType: ValueCoercion.SwiftType]
    
    let keyType: KeyCoercion
    let valueType: ValueCoercion
    
    init(_ keyType: KeyCoercion, _ valueType: ValueCoercion) {
        self.keyType = keyType
        self.valueType = valueType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        fatalError() // TO DO: see AsArray.coerce()
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toDictionary(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        fatalError()
        //return try Record(value.map { try self.elementType.box(value: $0, env: env) })
    }
}

// TO DO: AsStruct // Q. how best to pack/unpack?



class AsRecord: CallableCoercion {
    
    // a record may contain arbitrary keys of [usually] single type (dictionary-style usage), or fixed keys of arbitrary type (struct-style)
    
    var coercionName: String { return "record" }
    
    override var description: String { return "\(self.coercionName)(\(self.valueType))" }
    
    var key: String { return self.coercionName } // kludge as both Coercion and HandlerProtocol implement this via extension
    
    let signature = (
        paramType_0: asCoercion, // TO DO: make this Variant(COERCION,RECORD(COERCION)) to describe either value type[s] with no restriction on keys or a fixed structure of required keys (argument is a record of form `[KEY:COERCION]`, where each KEY is required)
        _na: asNoResult
    )
    
    lazy private(set) var interface = HandlerInterface(
        name: self.coercionName,
        parameters: [
            ("structure", "parameterType", signature.paramType_0)
        ],
        returnType: asCoercion)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let arg_0 = try self.signature.paramType_0.unboxArgument("structure", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return AsRecord(arg_0)
    }
    
    
    // TO DO: what about being able to restrict keyType to asText/asTag? (currently native record coercion always allows mixed Text and/or Tag keys)
    let valueType: Coercion
    
    init(_ valueType: Coercion) {
        self.valueType = valueType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toRecord(env: env, coercion: self)
    }
}


