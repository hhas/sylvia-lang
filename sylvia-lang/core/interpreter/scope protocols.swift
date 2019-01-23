//
//  state protocols.swift
//

// Attributed Values, Environment


//


// TO DO: pass entire identifier/command to attributed value, env, etc for combined lookup + evaluation operation; this should simplify calling, avoid need for `get` to return scope, and allow alternate env implementations to process commands differently, e.g. an ObjC bridge would look up methods using combined command name + argument labels (current arrangement would require a custom callable that captures target + name, then appends arg labels to name in order to construct full ObjC name); where `get` returns a handler, it would always wrap it as a closure


// TO DO: put all user-only metadata (e.g. documentation annotations) in a separate structure/module which is lazily loaded/instantiated only when needed


protocol Scope: Attributed { // TO DO: `Identifier`, `Command` use Environment.find() to retrieve the slot's value AND its lexical scope so that it can eval the value in its original context when coercing it to the requested return type (one option is for `get` to return both, although the scope needs to be protocol based and restricted to read-only [note: a read-only protocol will discourage, but won't prevent, upcasting of a returned Environment; a safer option is to wrap the env in a shim, or maybe ask the env for a read-only version of itself which prevents any fiddling]) //
    
    // TO DO: make sure that value's attributes are fully introspectable (i.e. don't just implement everything as an opaque `switch` block in `get()`, but instead define the value's interface and let the glue generator build the get()/set() implementation automatically; in the case of aelib, interface definitions will be defined dynamically by terminology parser)
    
    func set(_ key: String, to value: Value, readOnly: Bool, thisFrameOnly: Bool) throws
    
    func add(unboundHandler: Handler) throws
    
    func child() -> Scope // TO DO: what about scope name, global/local, writable flag?
    
}



extension Scope { // TO DO: sort this out
    
    func set(_ name: String, to value: Value) throws {
        try self.set(name, to: value, readOnly: true, thisFrameOnly: false)
    }
    
    func add(_ coercion: Coercion) throws { // used by library loader
        try self.set(coercion.key, to: coercion, readOnly: true, thisFrameOnly: true)
    }
    
    func add(unboundHandler: Handler) throws { // used by library loader; also used in defineHandler
        throw ReadOnlyValueError(name: unboundHandler.name, env: self)
    }
}



