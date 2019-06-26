//
//  coercion modifiers.swift
//

// TO DO: AsVariant, AsPrecis (Q. how will Variant support Swift types? needs to use enum)


// optionals


class AsDefault: Coercion, HandlerProtocol {
        
    let signature = (
        paramType_0: asAnything,
        paramType_1: asCoercion,
        returnType: asIs
    )
    
    lazy private(set) var interface = HandlerInterface(
        name: self.coercionName,
        parameters: [
            ("value", "defaultValue", signature.paramType_0),
            ("of_type", "parameterType", signature.paramType_1)
        ],
        returnType: asCoercion)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let defaultValue = try self.signature.paramType_0.unboxArgument("value", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        let ofType = try self.signature.paramType_1.unboxArgument("of_type", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return AsDefault(ofType, defaultValue)
    }
    
    // native only; TO DO: what about bridging? (remember, we want to avoid primitive library developers hardcoding default values in func implementation)
    
    var coercionName: String { return "default" }
    
    var key: String { return self.interface.key } // TO DO: currently need this as both HandlerProtocol and Coercion implement `key` via extensions
    
    override var description: String { return "\(self.coercionName)(\(self.defaultValue), \(self.coercion))" }
    
    let coercion: Coercion
    let defaultValue: Value
    
    init(_ coercion: Coercion, _ defaultValue: Value) { // TO DO: make defaultValue param optional, and provide `standardDefaultValue` var on Coercion classes? (Q. what to do for coercions that don't have meaningful defaults? would be better to use a DefaultCoercible protocol and have alternate initializer; Q. what about constraints?)
        self.coercion = coercion
        self.defaultValue = defaultValue
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch is NullCoercionError {
            return self.defaultValue
        }
    }
}


class AsOptionalValue: BridgingCoercion { // native optional
    
    var coercionName: String { return "optional" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    typealias SwiftType = Value
    
    let coercion: Coercion
    
    init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch let error as NullCoercionError {
            return error.value
        } catch {
            //print("\(self) caught error: \(error)")
            throw error
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch is NullCoercionError {
            return noValue
        }
    }
}


class AsOptional<T: BridgingCoercion>: BridgingCoercion { // Swift `Optional` enum; `nothing` → `Optional<T>.none`
    
    var coercionName: String { return "optional" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    typealias SwiftType = T.SwiftType?
    
    let coercion: T
    
    init(_ coercion: T) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch let error as NullCoercionError {
            return error.value
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, env: env)
        } catch is NullCoercionError {
            return nil
        }
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        if let v = value {
            return try self.coercion.box(value: v, env: env)
        } else {
            return noValue
        }
    }
}


// lazy evaluation

class AsThunk<T: BridgingCoercion>: BridgingCoercion {
    
    var coercionName: String { return "lazy" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    typealias SwiftType = Thunk
    
    let coercion: T
    
    init(_ coercion: T) {
        self.coercion = coercion
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return Thunk(value, env: env, coercion: self.coercion)
    }
}


class AsLazy: Coercion { // native only; TO DO: what about bridging?
    
    var coercionName: String { return "lazy" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    let coercion: Coercion
    
    init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return Thunk(value, env: env, coercion: self.coercion)
    }
}


class AsIs: BridgingCoercion { // the value is passed thru as-is, without evaluation; unlike AsThunk, its context (env) is not captured
    
    var coercionName: String { return "anything" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    // TO DO: add initializer that takes a Coercion object for display purposes only (i.e. the primitive implementation is known to return a value of that type which it doesn't want evaluated again for whatever reason); glue generator may want to use that 'true' coercion in interface signature, but ignore it when returning value; alternatively make this a `return_as_is` option on glue generator, avoiding need for this class entirely

    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return value
    }
}


class AsAnything: BridgingCoercion { // any value including `nothing`; used to evaluate expressions
    
    var coercionName: String { return "anything" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try value.toAny(env: env, coercion: self)
        } catch let error as NullCoercionError {
            return error.value // TO DO: how far should `didNothing` result propagate before being converted to `nothing`/permanent coercion error? it probably shouldn't go beyond an immediate `else` clause, e.g. `(if x action) else (y)` but not `(moreStuff(if x action)) else (y)`; might need to define an additional return type for handlers that can return `didNothing`, and have AsAnything/AsOptional catch and return noValue
        }
    }
}


// nominal type checks

class AsLiteral<T: Value>: BridgingCoercion { // if the input Value is an instance of T [sub]class, it is passed thru as-is without evaluation, otherwise an error is thrown;
    
    var coercionName: String { fatalError("Missing implementation: \(type(of:self)).\(#function)") }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = T
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let result = value as? SwiftType else { throw CoercionError(value: value, coercion: self) }
        return result
    }
}

class AsTypeChecked<T: Value>: AsLiteral<T> {
    
    override func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let result = try value.nativeEval(env: env, coercion: asAnything) as? SwiftType else {
            throw CoercionError(value: value, coercion: self)
        }
        return result
    }
}

//

class AsIdentifierLiteral: AsLiteral<Identifier> {
    override var coercionName: String { return "identifier" }
}

class AsCommandLiteral: AsLiteral<Command> {
    override var coercionName: String { return "command" }
}

/*
class AsReference: AsTypeChecked<Reference> {
    override var coercionName: String { return "reference" }
}
*/
