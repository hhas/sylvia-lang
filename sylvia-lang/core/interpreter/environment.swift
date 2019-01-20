//
//  environment.swift
//


// TO DO: what about hooks into abstract namespaces (e.g. modules, persistent store)

// note: this design prevents masking, so stdlib slots (which should always be read-only) can never be customized/subverted by overriding in a sub-scope; flipside of this is that once released, adding new slots to stdlib always risks breaking existing client code that uses the same names; Q. add `local IDENTIFIER` operator/command which adds new slot to current frame without searching parent frames to see if that identifier already exists

// TO DO: really need to distinguish between Environment (stores local/global state) and other types of scope (e.g. values with their own attributes/methods which are referred to using `of` operator, 'tell' blocks [`tell TARGET BLOCK`] which creates a custom scope atop the current stack frame [unlike `of`, this scope handles all lookups, not just the initial command/attribute lookup])


// TO DO: all lookups need to use normalized (all-lowercase) name strings to ensure case-insensitive behavior


// for sake of getting everything running, only practical option [without deep hooks into refcounting] is to strong-ref all library-defined handlers [since libraries are unlikely to be unloaded again during process lifetime]


// TO DO: *might* be useful for Env instances (activation records) to provide 'auto-cleanup pool' into which code within that scope can throw resources for deferred cleanup [c.f. Swift's own `defer` keyword] (e.g. for auto-closing file handles [on the assumption that open file object itself hasn't been stored outside this scope]), with caveat that cleanup is called when native handler returns; the Env itself may persist much longer if it's been captured in a closure stored elsewhere)

// TO DO: for JS-style objects, should leading underscore indicate private attribute? (this could be enforced by AttributedValue wrapper, which might in turn just wrap a captured Env; main challenge is delegation between chained scopes [equiv. to setting prototype slot in JS], but as long as prototypes are members of wrapper, they should be able to bypass the external barrier okay)

// note that significant gotcha to user-defined objects is current 'arguments are evaluated in target's scope first and [their own lexical] command scope second' behavior, which exists as workaround for conflicting precedence needs of selectors vs commands when operating on references (e.g. `get(text of document(1))` is unambiguous, but `get text of document 1` parses as `of(get(text),document(1))`, not as `get(of(text,document(1)))` which is what we really want but cannot achieve as there's no way to bind `document` command tighter than `of` but `get` command looser than `of`); one option, if current arrangement proves unworkable, is to define `get` and `set` as operators, which can set their own precedence levels to get the desired effect [and just tell users to parenthesize args for all other commands]




class Env: Scope {
    
    // Q. can/should .handler slot always be readOnly? i.e. initial definition of primitive/native handler probably shouldn't be overwritable; where switching between handlers is required, use a separate read-write Value/Closure slot and assign a closure to it
    
    typealias Slot = (readOnly: Bool, value: Value) // TO DO: use enum Slot{.value(Value);.handler(HandlerProtocol);.closure(HandlerProtocol)} [TO DO: is .closure needed? e.g. if handle() looks up a slot containing a Value, it needs to cast `as? Handler`; as long as that cast succeeds it can use it; it could re-store it as .closure to avoid need for future casts, but let's not worry about that for now; whereas .handler() would contain unbound callable, which is fine for handle() but when get() retrieves it it needs to wrap it in Closure before returning it; bear in mind that this could end up leaking depending on where it's stored, but will have to worry about that later]
    
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
    
    func get(_ key: String) throws -> Value {
        guard let result = self.find(key) else { throw ValueNotFoundError(name: key, env: self) }
        if let handler = result.slot.value as? HandlerProtocol, !(handler is Closure) { // TO DO: rework this once Slot is an enum, as handlers assigned to this scope via set() are already wrapped in a Closure so don't need another layer of wrapping
            return Closure(handler: handler, handlerEnv: result.env)
        } else {
            return result.slot.value
        }
    }
    
    func set(_ key: String, to value: Value, readOnly: Bool = true, thisFrameOnly: Bool = false) throws { // TO DO: rename 'thisFrameOnly' to 'maskable'
        if !thisFrameOnly, let (slot, env) = self.find(key) {
            if slot.readOnly { throw ReadOnlyValueError(name: key, env: self) }
            env.frame[key] = (readOnly: readOnly, value: value)
        } else {
            self.frame[key] = (readOnly: readOnly, value: value)
        }
    }
    
    func handle(command: Command, commandEnv: Scope, coercion: Coercion) throws -> Value {
        //print("Env CLASS \(self) handling \(command)")
        guard let field = self.find(command.key), let handler = field.slot.value as? HandlerProtocol else { throw HandlerNotFoundError(name: command.key, env: self) }
        return try handler.call(command: command, commandEnv: commandEnv, handlerEnv: field.env, coercion: coercion)
    }
    
    // TO DO: `addHandler`; this will add a read-only `.handler(Handler)` Slot containing an unbound Handler
    
    func child() -> Scope { // TO DO: what about scope name, global/local, writable flag?
        return Env(parent: self)
    }
}




extension Scope {
    
    func set(_ name: String, to value: Value) throws {
        try self.set(name, to: value, readOnly: true, thisFrameOnly: false)
    }
    
    func add(_ handler: Handler) throws { // used by library loader
        try self.set(handler.key, to: handler, readOnly: true, thisFrameOnly: true)
    }
    
    func add(_ coercion: Coercion) throws { // used by library loader
        try self.set(coercion.key, to: coercion, readOnly: true, thisFrameOnly: true)
    }
}



class TargetScope: Scope { // creates sub-scope of an existing scope (typically an Env instance representing current activation record) with Value's attributes; used by `tell` block
    
    private let target: AttributedValue
    private let parent: Scope
    
    init(_ target: AttributedValue, parent: Scope) {
        self.target = target
        self.parent = parent
    }
    
    func set(_ name: String, to value: Value, readOnly: Bool, thisFrameOnly: Bool) throws {
        try self.parent.set(name, to: value, readOnly: readOnly, thisFrameOnly: thisFrameOnly)
    }
    
    func child() -> Scope { // TO DO: what should this return?
        return self
    }
    
    func get(_ key: String) throws -> Value {
        do {
            return try self.target.get(key)
        } catch is ValueNotFoundError {
            do {
                return try self.parent.get(key)
            } catch is ValueNotFoundError {
                throw GeneralError("Can't find value named ‘\(key)’ in \(self.target) or in \(self.parent)") // TO DO: need to throw an error describing both scopes (chaining would be simplest, though possibly misleading)
            }
        }
    }
    
    func handle(command: Command, commandEnv: Scope, coercion: Coercion) throws -> Value {
        //print("TELL block \(self) handling \(command)")
        do {
            return try self.target.handle(command: command, commandEnv: commandEnv, coercion: coercion)
        } catch is ValueNotFoundError {
            do {
                return try self.parent.handle(command: command, commandEnv: commandEnv, coercion: coercion)
            } catch is ValueNotFoundError {
                throw GeneralError("Can't find handler named ‘\(command.key)’ in \(self.target) or in \(self.parent)") // TO DO: as above
            }
        }
    }
}
