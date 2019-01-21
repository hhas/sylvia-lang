//
//  interface.swift
//


protocol RecordKey: Hashable { } // TO DO: currently unused; see also AsRecordKey/toRecordKey

extension RecordKey {
    var recordKey: AnyHashable { return AnyHashable(self) }
}



// HandlerProtocol Values (handlers, constrainable coercions)

typealias Argument = (label: Identifier?, value: Value)

typealias Parameter = (label: String, binding: String, coercion: Coercion)

// TO DO: parameters also need env keys


struct HandlerInterface: CustomDebugStringConvertible {
    // describes a handler interface; used for introspection, and also for argument/result coercions in NativeHandler
    
    // note: for simplicity, parameters are positional only; ideally they should also support labelling (but requires more complex unpacking algorithm to match labeled/unlabeled command arguments to labeled parameters, particularly when args are omitted from anywhere other than end of arg list)
    
    let name: String
    let key: String
    let parameters: [Parameter]
    let returnType: Coercion
    
    init(name: String, parameters: [Parameter], returnType: Coercion) {
        self.name = name
        self.key = name.lowercased()
        self.parameters = parameters
        self.returnType = returnType
    }
    
    var debugDescription: String { return "<HandlerInterface: \(self.signature)>" }
    
    var signature: String { return "\(self.name)\(self.parameters) returning \(self.returnType)" } // quick-n-dirty; TO DO: format as native syntax
    
    // TO DO: how should handlers' Value.description appear? (showing signature alone is ambiguous as it's indistinguishable from a command; what about "SIGNATURE{…}"? or "«handler SIGNATURE»"? [i.e. annotation syntax could be used to represent opaque/external values as well as attached metadata])
    
    // TO DO: what about documentation?
    // TO DO: what about meta-info (categories, hashtags, module location, dependencies, etc)?
}



typealias Handler = Value & HandlerProtocol

protocol HandlerProtocol {
    
    var interface: HandlerInterface { get }
    
    var name: String { get }
    var key: String { get }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value
    
}

extension HandlerProtocol {
    
    var name: String { return self.interface.name }
    var key: String { return self.interface.key }
}

