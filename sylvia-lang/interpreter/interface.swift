//
//  interface.swift
//

// get/set/call


// Value Attributes // TBC: naming (Accessor, Scope, Gettable/Settable; what else?) from callers' POV, it's a scope


protocol ReadOnlyScope {
    
    func get(_ name: String) throws -> (value: Value, scope: Scope)
    
}

protocol Scope: ReadOnlyScope { // TO DO: `Identifier`, `Command` use Env.find() to retrieve the slot's value AND its lexical scope so that it can eval the value in its original context when coercing it to the requested return type (one option is for `get` to return both, although the scope needs to be protocol based and restricted to read-only [note: a read-only protocol will discourage, but won't prevent, upcasting of a returned Env; a safer option is to wrap the env in a shim, or maybe ask the env for a read-only version of itself which prevents any fiddling]) //
    
    // TO DO: make sure that value's attributes are fully introspectable (i.e. don't just implement everything as an opaque `switch` block in `get()`, but instead define the value's interface and let the glue generator build the get()/set() implementation automatically; in the case of aelib, interface definitions will be defined dynamically by terminology parser)
    
    
    func set(_ name: String, to value: Value, readOnly: Bool, thisFrameOnly: Bool) throws

    // TO DO: rest of these are really only applicable to Env (add methods are shortcuts for `set`, and could be implemented as extension)
    
    func add(_ handler: CallableValue) throws // used by library loader
    
    func add(_ interface: CallableInterface, _ call: @escaping PrimitiveCall) throws // used to load primitive handler definitions
    
    func add(_ coercion: Coercion) throws // used by library loader // TO DO: delete this method once coercions implement Callable
    
    func child() -> Env // TO DO: what about scope name, global/local, writable flag?
    
}



// Callable Values (handlers, constrainable coercions)

typealias Parameter = (name: String, coercion: Coercion) // TO DO: include description here? (to reduce startup overheads, probably best to put all user-only metadata in a separate structure/module which is lazily loaded/instantiated only when needed; e.g. consider SDEFs, which require the AE bridge's parser to wade through large amounts of user documentation and Cocoa Scripting mappings at runtime to extract the keywordtype+name+code data it needs to instantiate the AE glue)


struct CallableInterface: CustomDebugStringConvertible {
    // describes a handler interface; used for introspection, and also for argument/result coercions in NativeHandler
    
    // note: for simplicity, parameters are positional only; ideally they should also support labelling (but requires more complex unpacking algorithm to match labeled/unlabeled command arguments to labeled parameters, particularly when args are omitted from anywhere other than end of arg list)
    
    let name: String
    let normalizedName: String
    let parameters: [Parameter]
    let returnType: Coercion
    
    init(name: String, parameters: [Parameter], returnType: Coercion) {
        self.name = name
        self.normalizedName = name.lowercased()
        self.parameters = parameters
        self.returnType = returnType
    }
    
    var debugDescription: String { return "<CallableInterface: \(self.signature)>" }
    
    var signature: String { return "\(self.name)\(self.parameters) returning \(self.returnType)" } // quick-n-dirty; TO DO: format as native syntax
    
    // TO DO: how should handlers' Value.description appear? (showing signature alone is ambiguous as it's indistinguishable from a command; what about "SIGNATURE{…}"? or "«handler SIGNATURE»"? [i.e. annotation syntax could be used to represent opaque/external values as well as attached metadata])
    
    // TO DO: what about documentation?
    // TO DO: what about meta-info (categories, hashtags, module location, dependencies, etc)?
}



typealias CallableValue = Value & Callable

protocol Callable {
    
    var interface: CallableInterface { get }
    
    var name: String { get }
    var normalizedName: String { get }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value
    
}

extension Callable {
    
    var name: String { return self.interface.name }
    var normalizedName: String { return self.interface.normalizedName }
}


//

typealias AttributedValue = Value & Attributed

protocol Attributed { // ReadOnlyScope? (challenge is that some Callables require write access)
    
}
