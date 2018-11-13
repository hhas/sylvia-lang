//
//  environment.swift
//


// TO DO: what about hooks into abstract namespaces (e.g. modules, persistent store)

// note: this design prevents masking, so stdlib slots (which should always be read-only) can never be customized/subverted by overriding in a sub-scope; flipside of this is that once released, adding new slots to stdlib always risks breaking existing client code that uses the same names

class Env {
    
    typealias Slot = (readOnly: Bool, value: Value)
    
    internal var frame: [String: Slot] // TO DO: what about option to define slot type?
    private let parent: Env?
    
    init(parent: Env? = nil) { // TO DO: read-only flag; if true, child() returns a ReadOnlyEnv that always throws on set(name:value:) (note: this prevents all writes to a scope, e.g. global; might want to use per-slot locks only)
        self.frame = [:]
        self.parent = parent
    }
    
    func find(_ name: String) -> (slot: Slot, env: Env)? { // also used to look up handlers, identifiers
        if let slot = self.frame[name] { return (slot, self) }
        return self.parent?.find(name)
    }
    
    func get(_ name: String) throws -> Value {
        guard let value = self.find(name)?.slot.value else {
            throw ValueNotFoundException(name: name, env: self)
        }
        return value
    }
    
    func set(_ name: String, to value: Value, readOnly: Bool = true) throws {
        if let (slot, env) = self.find(name) {
            if slot.readOnly { throw ReadOnlyValueException(name: name, env: self) }
            env.frame[name] = (readOnly: readOnly, value: value)
        } else {
            self.frame[name] = (readOnly: readOnly, value: value)
        }
    }
    
    func add(handler: Callable) throws { // used by library loader
        if self.frame[handler.name] != nil { throw ReadOnlyValueException(name: handler.name, env: self) }
        self.frame[handler.name] = (readOnly: true, value: handler as! Value)
    }
    
    func child() -> Env { // TO DO: what about scope name, global/local, writable flag?
        return Env(parent: self)
    }
}


