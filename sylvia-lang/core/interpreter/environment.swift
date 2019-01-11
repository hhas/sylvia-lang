//
//  environment.swift
//


// TO DO: what about hooks into abstract namespaces (e.g. modules, persistent store)

// note: this design prevents masking, so stdlib slots (which should always be read-only) can never be customized/subverted by overriding in a sub-scope; flipside of this is that once released, adding new slots to stdlib always risks breaking existing client code that uses the same names; Q. add `local IDENTIFIER` operator/command which adds new slot to current frame without searching parent frames to see if that identifier already exists

// TO DO: really need to distinguish between Environment (stores local/global state) and other types of scope (e.g. values with their own attributes/methods which are referred to using `of` operator, 'tell' blocks [`tell TARGET BLOCK`] which creates a custom scope atop the current stack frame [unlike `of`, this scope handles all lookups, not just the initial command/attribute lookup])


// TO DO: all lookups need to use normalized (all-lowercase) name strings to ensure case-insensitive behavior

class Env: Scope {
    
    
    typealias Slot = (readOnly: Bool, value: Value)
    
    internal var frame: [String: Slot] // TO DO: what about option to define slot coercion?
    private let parent: Env?
    
    init(parent: Env? = nil) { // TO DO: read-only flag; if true, child() returns a ReadOnlyEnv that always throws on set(name:value:) (note: this prevents all writes to a scope, e.g. global; might want to use per-slot locks only)
        self.frame = [:]
        self.parent = parent
    }
    
    private func find(_ name: String) -> (slot: Slot, env: Env)? { // also used to look up handlers, identifiers
        if let slot = self.frame[name] { return (slot, self) }
        return self.parent?.find(name)
    }
    
    func get(_ name: String) throws -> (value: Value, scope: Scope) { // TO DO: returned scope should be read-only // caution: caller must normalize name
        guard let result = self.find(name) else { throw ValueNotFoundError(name: name, env: self) }
        return (result.slot.value, result.env)
    }
    
    func set(_ name: String, to value: Value, readOnly: Bool = true, thisFrameOnly: Bool = false) throws { // caution: caller must normalize name
        if !thisFrameOnly, let (slot, env) = self.find(name) {
            if slot.readOnly { throw ReadOnlyValueError(name: name, env: self) }
            env.frame[name] = (readOnly: readOnly, value: value)
        } else {
            self.frame[name] = (readOnly: readOnly, value: value)
        }
    }
    
    func child() -> Scope { // TO DO: what about scope name, global/local, writable flag?
        return Env(parent: self)
    }
}




extension Scope {
    
    func set(_ name: String, to value: Value) throws {
        try self.set(name, to: value, readOnly: true, thisFrameOnly: false)
    }
    
    func add(_ handler: CallableValue) throws { // used by library loader
        try self.set(handler.key, to: handler, readOnly: true, thisFrameOnly: true)
    }
    
    func add(_ interface: CallableInterface, _ call: @escaping PrimitiveCall) throws { // used to load primitive handler definitions
        try self.add(PrimitiveHandler(interface, call))
    }
    
    func add(_ coercion: Coercion) throws { // used by library loader
        try self.set(coercion.key, to: coercion, readOnly: true, thisFrameOnly: true)
    }
}
