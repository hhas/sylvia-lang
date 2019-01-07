//
//  selectors.swift
//




class UnsupportedSelectorError: GeneralError {
    let name: String
    let value: Value
    
    init(name: String, value: Value) {
        self.name = name
        self.value = value
    }
    
    override var message: String {
        return "The following \(self.value.nominalType) value doesn’t support the “\(self.name)” selector: \(self.value)"
    }
}

class OutOfRangeError: GeneralError {
    let value: Value
    let selector: Value
    
    init(value: Value, selector: Value) {
        self.value = value
        self.selector = selector
    }
    
    override var message: String {
        return "Can’t select \(self.selector) of the following value as it is out of range: \(self.value)"
    }
}





class ByIndexSelectorConstructor: CallableValue { // returns an 'at' handler (closure), used to construct `ELEMENT at INDEX [of LIST]`
    
    let signature = (
        paramType_0: asAttributeName,
        paramType_1: asAnything,
        returnType: asIs
    )
    
    private let parentObject: AttributedValue
    
    init(parentObject: AttributedValue) { // the value upon which the selection will be made
        self.parentObject = parentObject
    }
    
    lazy var interface = CallableInterface(
        name: "at",
        parameters: [
            ("element_type", self.signature.paramType_0),
            ("selector_data", self.signature.paramType_1)], // TO DO: for native lists, selector_data is Int or Int...Int; for AE specifiers, it may be anything (it's up to receiving value/app to decide what to do with given selector)
        returnType: self.signature.returnType)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let elementName = try self.signature.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        let index = try self.signature.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: self)
        if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: self) }
        guard let elements = try self.parentObject.get(elementName).value as? Selectable else { throw NotYetImplementedError() } // e.g. `items [of LIST]`
        return try elements.byIndex(index)
    }
}



class ByNameSelectorConstructor: CallableValue { // returns a 'named' handler (closure), used to construct `ELEMENT named TEXT [of KV_LIST]`
    
    let signature = (
        paramType_0: asAttributeName,
        paramType_1: asAnything, // TO DO: Text [or Symbol, if KV-list]
        returnType: asIs
    )
    
    private let parentObject: AttributedValue
    
    init(parentObject: AttributedValue) { // the value upon which the selection will be made
        self.parentObject = parentObject
    }
    
    lazy var interface = CallableInterface(
        name: "named",
        parameters: [
            ("element_type", self.signature.paramType_0),
            ("selector_data", self.signature.paramType_1)], // TO DO: for native key-value lists, selector is text or symbol
        returnType: self.signature.returnType)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let elementName = try self.signature.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        let selector = try self.signature.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: self)
        if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: self) }
        guard let elements = try self.parentObject.get(elementName).value as? Selectable else { throw NotYetImplementedError() } // e.g. `items [of LIST]`
        return try elements.byName(selector)
    }
}


