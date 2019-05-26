//
//  value protocols.swift
//


// values that expose properties, elements, and/or methods

typealias AttributedValue = Value & Attributed

// TO DO: should get/set take optional 'delegate'? (e.g. in `tell app NAME {…}` block, all names are looked up on app object first, then in parent scope; similarly, when storing values, `set(_:to:)` should delegate directly to tell block's parent scope)

protocol Attributed {
    
    // TO DO: slot lookup != get/set; rename fetch/assign?
    
    func set(_ key: String, to value: Value) throws // used to set (via `store` command/`IDENTIFIER:VALUE` assignment) [mutable] simple attributes and one-to-one relationships only (for one-to-many relationships, `get` an [all] elements specifier, e.g. `items`, then apply selector to that); TO DO: this needs more thought, as `set(REFERENCE,to:VALUE)` is also used particularly in aelib; it might be that we standardize on `set(_:to:)` for *all* assignment
    
    func get(_ key: String, delegate: Attributed?) throws -> Value // TO DO: return type?
    
    func handle(command: Command, commandEnv: Scope, coercion: Coercion) throws -> Value // used to look-up *and* invoke a handler for the specified command (the given arguments are passed along to `Handler.call()`, along with the handlerEnv argument)
    
    // TO DO: introspection
    
}

extension Attributed {
    func get(_ key: String) throws -> Value { // workaround for inability to indicate default value for `delegate` in `Attributed` protocol // TO DO: smells
        return try self.get(key, delegate: nil)
    }
}


extension Attributed { // TO DO: currently used by Reference and List, which rely on their own `get()` implementation to return closures each time; implementing `handle` on those will eliminate need for Closures, allowing their selector and other methods to be constructed as unbound primitive handlers
    
    func handle(command: Command, commandEnv: Scope, coercion: Coercion) throws -> Value {
        //print("Attributed EXTENSION \(self) handling \(command)")
        guard let handler = (try? self.get(command.key)) as? HandlerProtocol else {
            throw HandlerNotFoundError(name: command.key, env: self)
        }
        return try handler.call(command: command, commandEnv: commandEnv, handlerEnv: ScopeShim(self), coercion: coercion)
    }
    
}




// Value subclasses that contain an underlying Swift value in a public let/var named `swiftValue` can adopt this protocol to expose it other protocols and extensions, e.g. see SelfPackingReferenceWrapper in aelib

protocol SwiftWrapper {
    
    associatedtype SwiftType
    
    var swiftValue: SwiftType { get }
    
}


// record keys

// TO DO: define HashableValue as abstract subclass of Value and make Text and Tag concrete subclasses of that? (as usual, Swift's inability to declare methods 'abstract' makes that messier than it ought to be [lots of `fatalError("Subclass needs to override #function")` crap], but it'll be easier to follow than this)

// this is a bit convoluted, but ensures Record's internal Dictionary storage only allows hashable Values (Text and/or Tag) as keys, providing better type safety than using AnyHashable directly (which would allow Swift Strings, Ints, etc to sneak in as well) (in an ideal world we'd just say `typealias HashableValue = Value & Hashable`, but swiftc type checker doesn't allow that as any fule kno)

protocol RecordKeyConvertible: Hashable { } // Values that can be used as record keys (Text, Tag) must adopt this protocol [in addition to implementing the usual Hashable+Equatable methods]

extension RecordKeyConvertible where Self: Value {
    var recordKey: RecordKey { return RecordKey(self) } // TO DO: how/where do we perform normalizations (e.g. case-sensitivity) defined by Record's key Coercion
}


struct RecordKey: Hashable { // type-safe wrapper around AnyHashable that ensures non-Value types can't get into Record's internal storage by accident, while still allowing mixed-type keys (the alternative would be to use an enum, but that isn't extensible; Q. what was reasoning for not using RecordKeyConvertible as dictionary key type? [probably because we don't want to implement `==` directly on Values, nor recalculate keys on every use; TO DO: how can this decoupling facilitate records custom-normalizing hash keys, e.g. for case-sensitive vs case-insensitive storage])
    
    private let key: AnyHashable
    let value: Value
    
    public init<T: RecordKeyConvertible>(_ value: T) where T: Value {
        self.key = AnyHashable(value)
        self.value = value
    }
    
    public func hash(into hasher: inout Hasher) { self.key.hash(into: &hasher) }
    public static func == (lhs: RecordKey, rhs: RecordKey) -> Bool { return lhs.key == rhs.key }
}


