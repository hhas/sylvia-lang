//
//  selector methods.swift
//

// while `at`, `named`, etc are currently defined as 'global' handlers in stdlib, they should really be defined solely as methods upon Values; e.g. in a 'tell TARGET {…}' block, the target Value is used as the block's scope, so is passed as commandEnv to handlers called within it while also providing first lookup (if first lookup fails, it should fall thru to second lookup in 'tell' block's own commandEnv scope; we'll need a new Scope subclass that supports this delegation)

// TO DO: how hard to use Closure around existing `at`, `named`, etc handlers (this will pass the target object via handlerEnv: parameter) (note: each 'global' handler is an instance of stock PrimitiveHandler class parameterized with interface and Swift function, so wrapping that in Closure isn't going to cost much more than rolling bespoke classes as below)

// TO DO: closure-like equivalent to indexSelector() in reference_handlers.swift, and their corresponding PrimitiveHandler glue classes

// TO DO:


typealias InstanceMethod = MethodBase & HandlerProtocol



class MethodBase: Value {
    
    let parent: Scope // TO DO: should be AttributedValue, but for now need to kludge it to keep Handler.function_*s happy
    
    init(for parent: AttributedValue) { // the value upon which the method is called
        self.parent = ScopeShim(parent) // kludge
    }
}



// TO DO: should parent be passed to Swift func as distinct argument? (need to give more thought to command vs handler scopes, and how `tell` blocks interact with this)


class IndexSelector: InstanceMethod { // returns an 'at' handler (closure), used to construct `ELEMENT at INDEX [of LIST]`
    
    let interface = interface_indexSelector_elementType_selectorData_commandEnv
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        return try function_indexSelector_elementType_selectorData_commandEnv(
            command: command, commandEnv: self.parent, handler: self, handlerEnv: handlerEnv, coercion: coercion) // TO DO: passing owner as commandEnv, not handlerEnv, smells
    }
}

class NameSelector: InstanceMethod { // returns a 'named' handler (closure), used to construct `ELEMENT named TEXT [of KV_LIST]`
    
    let interface = interface_nameSelector_elementType_selectorData_commandEnv
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        return try function_nameSelector_elementType_selectorData_commandEnv(
            command: command, commandEnv: self.parent, handler: self, handlerEnv: handlerEnv, coercion: coercion)
    }
}

class IDSelector: InstanceMethod { // returns a 'for_id' handler (closure), used to construct `ELEMENT for_id UID [of COLLECTION]`
    
    let interface = interface_idSelector_elementType_selectorData_commandEnv
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        return try function_idSelector_elementType_selectorData_commandEnv(
            command: command, commandEnv: self.parent, handler: self, handlerEnv: handlerEnv, coercion: coercion)
    }
}

class TestSelector: InstanceMethod { // returns a 'where' handler (closure), used to construct `ELEMENT where TEST [of COLLECTION]`
    
    let interface = interface_testSelector_elementType_selectorData_commandEnv
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        return try function_testSelector_elementType_selectorData_commandEnv(
            command: command, commandEnv: self.parent, handler: self, handlerEnv: handlerEnv, coercion: coercion)
    }
}






class OrdinalSelector: InstanceMethod { // returns a 'first'/'middle'/'last'/'any'/'every' closure
    
    enum Ordinal {
        case first
        case middle
        case last
        case any
        case all
    
        var description: String {
            switch self {
            case .first: return "first"
            case .middle: return "middle"
            case .last: return "last"
            case .any: return "any"
            case .all: return "every"
            }
        }
    }
    
    let selector: Ordinal
    
    private(set) lazy var interface = {
        return HandlerInterface(
            name: self.selector.description,
            parameters: [
                ("element_type", "", asTagKey),
                ],
            returnType: asReference
        )
    }()
    
    init(_ selector: Ordinal, for parent: AttributedValue) {
        self.selector = selector
        super.init(for: parent)
    }
    
    
    func call(command: Command, commandEnv: Scope, handlerEnv parentObject: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let arg_0 = try asTagKey.unboxArgument("element_type", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        let target = try elements(ofType: arg_0, from: parentObject)
        switch self.selector {
        case .first: return try target.first()
        case .middle: return try target.middle()
        case .last: return try target.last()
        case .any: return try target.any()
        case .all: return try target.all()
        }
    }
}



// relative: previous(SYMBOL)/next(SYMBOL)

// attributes

// by-ordinal: first/middle/last/any (TO DO: support `every` as special case: on an elements specifier it's a no-op; on a property specifier it changes it to elements specifier)

// insertion
