//
//  handler.swift
//


// TO DO: to implement [glue-managed] methods, should these subclass PrimitiveHandler? (or should method constructors just be convenience funcs that pass interface, function, and scope? note that if method's owner [e.g. aelib 'app' object] caches the method once bound, this will create memory-leaking refcycle unless there is a weakref somewhere; Q. what about caching in a command scope? in the case of methods on objects, how do we know if/when object goes out of scope and is ready to release? w.r.t. refcounting, if both object and method have 1 retain each, we know that's their cycle and can actively break it, but we'd need live hooks into refcounting); TBH, using command scope to release might be sufficient, as most times a reference is created it's used in that scope, and in situations where it is returned for use elsewhere, it'll just create a new method the next time it's used and cache it in that scope (pathological case it's it's created in one sub-scope of a parent scope and used in many sub-scopes of that parent); Q. what about using autorelease pools, or equivalent [e.g. closure cache in Environment], to dispose of bound methods?


// TO DO: requiresClosure is redundant; for primitive and native library handlers, simplest just to circular-ref it; for methods, get() should always wrap in Closure before returning

// another possibility is for Environment/Scope to implement `handleCommand` and only use `get` for identifiers; ends up with the same Swift stack consumption while saving construction of unnecessary Closure just to throw it away; Q. how will this redistribute logic for unpacking arguments list?


// IMPORTANT: Handlers must not directly return HandlerNotFoundError (it'll confuse `tell` blocks and similar, which delegate handle() call to a second scope if first scope throws 'handler not found')

// TO DO: consider eliminating PrimitiveHandler and just have Environment.Slot store each handler's interface_ and function_ directly; the only time it'd need to be wrapped then is when get() returns a primitive handler as a closure (which could be implemented as a very simple PrimitiveClosure class, which will also work for methods, although we've yet to figure out practical glue architecture for those)


// helper function; given mutable array of VALUE and/or LABEL:VALUE arguments, attempt to match and return the first argument, or nil if no match

func removeArgument(_ paramKey: String, from arguments: inout [Argument]) -> Value? {
    if arguments.count > 0 && (arguments[0].label == nil || arguments[0].label!.key == paramKey) {
        return arguments.removeFirst().value // remove and return matched argument
    }
    return nil // else no arguments/mismatched label, so assume this argument was omitted
}


// concrete classes


class NativeHandler: Handler {
    
    override var description: String { return self.interface.signature }
    
    let interface: HandlerInterface // TO DO: support declaring capability requirements as part of interface (Q. in native code, should capabilities be declared via annotations, or something else?)
    
    let body: Value // TO DO: require Block?
    let isEventHandler: Bool
    
    init(_ interface: HandlerInterface, _ body: Value, _ isEventHandler: Bool) { // TO DO: Bool option to modify how unmatched arguments are handled: command handlers (`to ACTION(…){…}`) should throw, event handlers (`when EVENT(…){…}`) should silently discard (Q. should command/event parameter matching behavior be specified as a capability flag? seems like it'd be a good idea to have a single standardized API and syntax, allowing new capability types to be added over time. Per-handler capabilities could prove extremely powerful combined with dynamic sandboxing. e.g. Consider a command shell where user cannot be expected to declare up-front exactly which safety protections/security rights/etc they will require when interacting with machine. As user enters new commands, the shell could list each handler's capability requirements, then confirm all new rights upon user clicking Run; this will be vastly more pleasant to use than, say, 10.14's current UX for approving per-app Apple event IPC, where user may be prompted at multiple points throughout the program's lifetime ['fire and forget' is not an option here].)
        self.interface = interface
        self.body = body
        self.isEventHandler = isEventHandler
    }
    
    // unbox()/coerce() support; returns Closure capturing both handler and its original handlerEnv (i.e. a closure); this allows identifiers to retrieve handlers and pass as arguments/assign to other vars
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value { // TO DO: not sure about this logic; it'd be safer done in Environment.get()
        return Closure(handler: self, handlerEnv: env)
    }
    
    // called by Command
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let result: Value
        do {
            //print("calling \(self):", command)
            let bodyEnv = handlerEnv.child()
            var arguments = command.arguments // the arguments to match
            for (paramKey, binding, coercion) in self.interface.parameters {
                let value = removeArgument(paramKey, from: &arguments) ?? noValue
                try bodyEnv.set(binding, to: coercion.coerce(value: value, env: commandEnv)) // expand/thunk parameter using command's lexical scope
            }
            if arguments.count > 0 && !self.isEventHandler { throw UnrecognizedArgumentError(command: command, handler: self) }
            //print("\(self) evaluating body as \(self.interface.returnType).")
            result = try self.interface.returnType.coerce(value: self.body, env: bodyEnv)
            //print("…got result: \(result)")
        } catch {
            throw HandlerFailedError(handler: self, command: command).from(error)
        }
        //print("\(self) coercing returned value to requested \(coercion): \(result)")
        return try coercion.coerce(value: result, env: commandEnv) // TO DO: intersect Coercions to avoid double-coercion (Q. not sure what env[s] to use)
    }
}




typealias PrimitiveCall = (_ command: Command, _ commandEnv: Scope, _ handler: Handler, _ handlerEnv: Scope, _ coercion: Coercion) throws -> Value


class PrimitiveHandler: Handler {
    
    override var description: String { return self.interface.signature }
    
    let interface: HandlerInterface
    
    private let swiftFunctionWrapper: PrimitiveCall
    
    init(_ interface: HandlerInterface, _ swiftFunc: @escaping PrimitiveCall) {
        self.interface = interface
        self.swiftFunctionWrapper = swiftFunc
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        // TO DO: double-coercing returned values (once in self.call() and again in coercion.coerce()) is a pain, but should mostly go away once Coercions can be intersected (hopefully, intersected Coercions created within static expressions can eventually be memoized, or the AST rewritten by the interpreter to use them in future, avoiding the need to recreate those intersections every time they're used)
        let result: Value
        do {
            result = try self.swiftFunctionWrapper(command, commandEnv, self, handlerEnv, coercion) // TO DO: function wrapper currently ignores `coercion` (it's passed here on assumption that glue code will eventually intersect it with its interface.returnType, but see below TODO)
        } catch {
            throw HandlerFailedError(handler: self, command: command).from(error)
        }
        return try coercion.coerce(value: result, env: commandEnv) // TO DO: double coercion is doubly problematic: coercion should intersect with interface.returnType to avoid duplication of effort; however running command with asAnything as coercion invokes `call()` with coercion:asValue, so NullCoercionError here needs to propagate back to be handled correctly (Q. is this why there was an atomic `AsAnything[OrNothing]` class before? for now, use `asAnything`, which is same thing, to evaluate an expr without specifying a return coercion). Basically, return types are a giant PITA from implementation POV; idea is that given `foo(bar())`, foo's parameter coercion is passed to bar handler which can intersect it with its return coercion and ensure its return value adheres to that, but this requires full coercion to be passed all the way up to bar handler whereas AsOptional/AsDefault modifiers stay further up the call chain waiting to catch any NullCoercionErrors that propagate back…except those errors have already been caught and rethrown as permanent coercion errors by then; got a vague feeling this might be why kiwi/entoli have an extra layer of dispatch - Value->Coercion->Value - rather than Coercion->Value as is done here, allowing values to have more control over how return types are handled (coerce now vs pass along). This stuff is potentially very powerful and may well be a prerequisite to efficient native->Swift compilation, but is a huge headache to get it exactly right.
    }
}



// caution: when comparing, say, coercions for equality, they may be wrapped in closure

class Closure: Handler { // `get()`-ing an unbound Handler from an Environment automatically returns a closure by wrapping both the handler and the env in a new Closure instance, allowing that handler to be passed to, stored, and called in other contexts without (unlike AppleScript) losing its lexical bindings
    
    var interface: HandlerInterface { return self.handler.interface }
    
    override var description: String { return self.interface.signature } // TO DO: how best to implement `var description` on handlers? (cleanest solution is to add it automatically via a protocol extension to HandlerProtocol, though that will require reworking Value.description first); for now, just kludge it onto each handler class
    
    private let handler: HandlerProtocol
    private let handlerEnv: Scope
    
    init(handler: HandlerProtocol, handlerEnv: Scope) {
        self.handler = handler
        self.handlerEnv = handlerEnv
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        // note: command name may be different to handler name if handler has been assigned to different slot
        return try self.handler.call(command: command, commandEnv: commandEnv, handlerEnv: self.handlerEnv, coercion: coercion)
    }
}
