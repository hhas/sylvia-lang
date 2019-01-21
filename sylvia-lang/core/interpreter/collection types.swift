//
//  collection types.swift
//



class AsArray<ElementCoercion: BridgingCoercion>: BridgingCoercion {
    
    var coercionName: String { return "list" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }
    
    typealias SwiftType = [ElementCoercion.SwiftType]
    
    let elementType: ElementCoercion
    
    init(_ elementType: ElementCoercion) { // TO DO: optional min/max length constraints
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        fatalError()//return try value.toList(env: env, coercion: AsList(self.elementType)) // TO DO: reboxing AsArray coercion as AsList is smelly; the problem is that toList() expects coercion:AsList (which allows it to get coercion.elementType); one option might be for AsArray to subclass AsList (although that may require some ugly casting to get AsList.elementType from Coercion back to ElementCoercion for use in box/unbox)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toArray(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return try List(value.map { try self.elementType.box(value: $0, env: env) })
    }
}


// native-only coercions // TO DO: this smells; it should be able to bridge as long as items are coerced, not unboxed

class AsList: CallableCoercion {
    
    var coercionName: String { return "list" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }
    
    var key: String { return self.coercionName } // kludge as both Coercion and HandlerProtocol implement this via extension
    
    let signature = (
        paramType_0: asCoercion,
        returnType: asIs
    )
    
    lazy private(set) var interface = HandlerInterface(
        name: self.coercionName,
        parameters: [
            ("item_type", "parameterType", signature.paramType_0)
        ],
        returnType: asCoercion)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let ofType = try self.signature.paramType_0.unboxArgument("item_type", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return AsList(ofType)
    }
    
    
    
    let elementType: Coercion
    
    init(_ elementType: Coercion) {
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toList(env: env, coercion: self)
    }
}



class AsRecord: CallableCoercion {
    
    // a record may contain arbitrary keys of [usually] single type (dictionary-style usage), or fixed keys of arbitrary type (struct-style)
    
    var coercionName: String { return "record" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }
    
    var key: String { return self.coercionName } // kludge as both Coercion and HandlerProtocol implement this via extension
    
    let signature = (
        paramType_0: asCoercion, // TO DO: make this Variant(COERCION,RECORD(COERCION)) to describe either value type[s] with no restriction on keys or a fixed structure of required keys (argument is a record of form `[KEY:COERCION]`, where each KEY is required)
        returnType: asIs
    )
    
    lazy private(set) var interface = HandlerInterface(
        name: self.coercionName,
        parameters: [
            ("structure", "parameterType", signature.paramType_0)
        ],
        returnType: asCoercion)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let ofType = try self.signature.paramType_0.unboxArgument("structure", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return AsList(ofType)
    }
    
    
    
    let elementType: Coercion
    
    init(_ elementType: Coercion) {
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toRecord(env: env, coercion: self)
    }
}


