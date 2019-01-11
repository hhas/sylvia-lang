//
//  selectors.swift
//

// while `at`, `named`, etc are currently defined as 'global' handlers in stdlib, they should really be defined solely as methods upon Values; e.g. in a 'tell TARGET {…}' block, the target Value is used as the block's scope, so is passed as commandEnv to handlers called within it while also providing first lookup (if first lookup fails, it should fall thru to second lookup in 'tell' block's own commandEnv scope; we'll need a new Scope subclass that supports this delegation)

// TO DO: how hard to use BoundHandler around existing `at`, `named`, etc handlers (this will pass the target object via handlerEnv: parameter) (note: each 'global' handler is an instance of stock PrimitiveHandler class parameterized with interface and Swift function, so wrapping that in BoundHandler isn't going to cost much more than rolling bespoke classes as below)

// TO DO: closure-like equivalent to indexSelector() in reference_handlers.swift, and their corresponding PrimitiveHandler glue classes

// TO DO:

class IndexSelectorMethod: CallableValue { // returns an 'at' handler (closure), used to construct `ELEMENT at INDEX [of LIST]`
    
    private let signature = signature_indexSelector_elementType_selectorData_commandEnv
    let interface = interface_indexSelector_elementType_selectorData_commandEnv
    
    private let parentObject: AttributedValue
    
    init(parentObject: AttributedValue) { // the value upon which the selection will be made
        self.parentObject = parentObject
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let arg_0 = try self.signature.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self) // e.g. `items`, `playlists`
        let arg_1 = try self.signature.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: self) // e.g. `3`, `2 thru -1`
        if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: self) }
        
        // TO DO: probably want to put next line in an extension method (right now it's copy-pasted in reference_handlers.)
        guard let target = try self.parentObject.get(arg_0).value as? Selectable else { // e.g. `items [of LIST]`
            throw NotYetImplementedError("needs to throw 'not elements' error")
        }
        let result = try target.byIndex(
                arg_1
        )
        return try self.signature.returnType.box(value: result, env: handlerEnv)
    }
    
    /*
    // this is the glue-generated wrapper for indexSelector(elementType:selectorData:commandEnv:)
    func function_indexSelector_elementType_selectorData_commandEnv(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let arg_0 = try signature_indexSelector_elementType_selectorData_commandEnv.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: handler)
        let arg_1 = try signature_indexSelector_elementType_selectorData_commandEnv.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: handler)
        if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: handler) }
        let result = try indexSelector(
            elementType: arg_0,
            selectorData: arg_1,
            commandEnv: commandEnv
        )
        return try signature_indexSelector_elementType_selectorData_commandEnv.returnType.box(value: result, env: handlerEnv)
    }
    
    // and this is the function it calls; big difference here to bound method is that the commandEnv is the target, not the handlerEnv
    func indexSelector(elementType: String, selectorData: Value, commandEnv parentObject: Scope) throws -> Value { // also implements by-range // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
        guard let elements = try parentObject.get(elementType).value as? Selectable else { // e.g. `items [of LIST]`
            throw ValueNotFoundError(name: elementType, env: parentObject) // TO DO: distinguish between 'not found' and 'not elements'
        }
        return try elements.byIndex(selectorData)
    }
    */
    
}



class NameSelectorMethod: CallableValue { // returns a 'named' handler (closure), used to construct `ELEMENT named TEXT [of KV_LIST]`
    
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


