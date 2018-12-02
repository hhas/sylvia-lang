//
//  handler.swift
//


typealias CallableValue = Value & Callable

typealias Parameter = (name: String, type: Coercion)




enum EnvType { // used in primitive libraries; indicates what, if any, environment[s] the handler needs to access (module, body, and/or caller) in order to perform its work
    case noEnv
    case handlerEnv // TO DO: one of the challenges with handlerEnv (i.e. moduleEnv) is legality of the module's handlers modifying the module's slots; in principle, a module could just use its own internal Swift vars - is there any situation where it would be preferable to push this state into Env? (e.g. module persistency; Swift vars won't persist, but Env state could be written to disk)
    case bodyEnv // create a sub-env from handler scope (TO DO: when would this be needed? e.g. a handler that creates and returns a BoundHandler [closure] might want to use bodyEnv, giving the returned handler access to constructor's arguments and any additional local values it creates while keeping those values visible in native runtime debugger/introspection)
    case commandEnv
    // TO DO: include read-only/write-only/read-write flags? this can be used to determine [some] side-effects, which might in turn be used by runtime to memoize outputs (e.g. for performance, or to enable backtracking in 'debugger' mode), or in user docs to indicate scope of action (unfortunately, Swift/Cocoa doesn't provide a mechanism to indicate other side effects, e.g. file read/write, so that sort of metainfo would have to be supplied by module developer on trust)
}


struct CallableInterface: CustomDebugStringConvertible {
    // describes a handler interface; used for introspection, and also for argument/result coercions in NativeHandler
    
    // note: for simplicity, parameters are positional only; ideally they should also support labelling (but requires more complex unpacking algorithm to match labeled/unlabeled command arguments to labeled parameters, particularly when args are omitted from anywhere other than end of arg list)
    
    let name: String
    let parameters: [Parameter]
    let returnType: Coercion
    
    var debugDescription: String { return "<CallableInterface: \(self.signature)>" }
    
    var signature: String { return "\(self.name)\(self.parameters) returning \(self.returnType)" } // quick-n-dirty; TO DO: format as native syntax
    
    // TO DO: how should handlers' Value.description appear? (showing signature alone is ambiguous as it's indistinguishable from a command; what about "SIGNATURE{…}"? or "«handler SIGNATURE»"? [i.e. annotation syntax could be used to represent opaque/external values as well as attached metadata])
    
    // TO DO: what about documentation?
    // TO DO: what about meta-info (categories, hashtags, module location, dependencies, etc)?
}


protocol Callable {
    
    var interface: CallableInterface { get }
    
    var name: String { get }
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value

}

extension Callable {
    
    var name: String { return self.interface.name }
}




// concrete classes

class BoundHandler: CallableValue { // getting a Handler from an Env creates a closure, allowing it to be passed to and called in other contexts
    
    var interface: CallableInterface { return self.handler.interface }
    
    override var description: String { return self.interface.signature } // TO DO: how best to implement `var description` on handlers? (cleanest solution is to add it automatically via a protocol extension to Callable, though that will require reworking Value.description first); for now, just kludge it onto each handler class
    
    private let handler: Callable
    private let handlerEnv: Env
    
    init(handler: Callable, handlerEnv: Env) {
        self.handler = handler
        self.handlerEnv = handlerEnv
    }
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        // note: command name may be different to handler name if handler has been assigned to different slot
        return try self.handler.call(command: command, commandEnv: commandEnv, handlerEnv: self.handlerEnv, type: type)
    }
}


class Handler: CallableValue { // native handler
    
    override var description: String { return self.interface.signature }
    
    let interface: CallableInterface // TO DO: support declaring capability requirements as part of interface (Q. in native code, should capabilities be declared via annotations, or something else?)
    
    let body: Value
    let isEventHandler: Bool
    
    init(_ interface: CallableInterface, _ body: Value, _ isEventHandler: Bool) { // TO DO: Bool option to modify how unmatched arguments are handled: command handlers (`to ACTION(…){…}`) should throw, event handlers (`when EVENT(…){…}`) should silently discard (Q. should command/event parameter matching behavior be specified as a capability flag? seems like it'd be a good idea to have a single standardized API and syntax, allowing new capability types to be added over time. Per-handler capabilities could prove extremely powerful combined with dynamic sandboxing. e.g. Consider a command shell where user cannot be expected to declare up-front exactly which safety protections/security rights/etc they will require when interacting with machine. As user enters new commands, the shell could list each handler's capability requirements, then confirm all new rights upon user clicking Run; this will be vastly more pleasant to use than, say, 10.14's current UX for approving per-app Apple event IPC, where user may be prompted at multiple points throughout the program's lifetime ['fire and forget' is not an option here].)
        self.interface = interface
        self.body = body
        self.isEventHandler = isEventHandler
    }
    
    // unbox()/coerce() support; returns BoundHandler capturing both handler and its original handlerEnv; this allows identifiers to retrieve handlers and pass as arguments/assign to other vars
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return BoundHandler(handler: self, handlerEnv: env)
    }
    
    // called by Command
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        let result: Value
        do {
            //print("calling \(self):", command)
            let bodyEnv = handlerEnv.child()
            var arguments = command.arguments
            for (parameterName, parameterType) in self.interface.parameters {
                let value = arguments.count > 0 ? arguments.removeFirst() : noValue
                //print("unpacking argument \(parameterName): \(value)")
                try bodyEnv.set(parameterName, to: parameterType.coerce(value: value, env: commandEnv)) // expand/thunk parameter using command's lexical scope
            }
            if arguments.count > 0 && !self.isEventHandler { throw UnrecognizedArgumentError(command: command, handler: self) }
            //print("\(self) evaluating body as \(self.interface.returnType).")
            result = try self.interface.returnType.coerce(value: self.body, env: bodyEnv)
            //print("…got result: \(result)")
        } catch {
            throw HandlerFailedError(handler: self, command: command).from(error)
        }
        //print("\(self) coercing returned value to requested \(type): \(result)")
        return try type.coerce(value: result, env: commandEnv) // TO DO: intersect Coercions to avoid double-coercion (Q. not sure what env[s] to use)
    }
}




typealias PrimitiveCall = (_ command: Command, _ commandEnv: Env, _ handler: CallableValue, _ handlerEnv: Env, _ type: Coercion) throws -> Value



class PrimitiveHandler: CallableValue {
    
    override var description: String { return self.interface.signature }
    
    let interface: CallableInterface
    
    private let swiftFunctionWrapper: PrimitiveCall
    
    init(_ interface: CallableInterface, _ swiftFunc: @escaping PrimitiveCall) {
        self.interface = interface
        self.swiftFunctionWrapper = swiftFunc
    }
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        // TO DO: double-coercing returned values (once in self.call() and again in type.coerce()) is a pain, but should mostly go away once Coercions can be intersected (hopefully, intersected Coercions created within static expressions can eventually be memoized, or the AST rewritten by the interpreter to use them in future, avoiding the need to recreate those intersections every time they're used)
        let result: Value
        do {
            result = try self.swiftFunctionWrapper(command, commandEnv, self, handlerEnv, type) // TO DO: function wrapper currently ignores `type` (it's passed here on assumption that glue code will eventually intersect it with its interface.returnType, but see below TODO)
        } catch {
            throw HandlerFailedError(handler: self, command: command).from(error)
        }
        return try type.coerce(value: result, env: commandEnv) // TO DO: double coercion is doubly problematic: type should intersect with interface.returnType to avoid duplication of effort; however running command with asAnythingOrNothing as type invokes `call()` with type:asAnything, so NullCoercionError here needs to propagate back to be handled correctly (Q. is this why there was an atomic `AsAnything[OrNothing]` class before? for now, use `asResult`, which is same thing, to evaluate an expr without specifying a return type). Basically, return types are a giant PITA from implementation POV; idea is that given `foo(bar())`, foo's parameter type is passed to bar handler which can intersect it with its return type and ensure its return value adheres to that, but this requires full type to be passed all the way up to bar handler whereas AsOptional/AsDefault modifiers stay further up the call chain waiting to catch any NullCoercionErrors that propagate back…except those errors have already been caught and rethrown as permanent coercion errors by then; got a vague feeling this might be why kiwi/entoli have an extra layer of dispatch - Value->Coercion->Value - rather than Coercion->Value as is done here, allowing values to have more control over how return types are handled (coerce now vs pass along). This stuff is potentially very powerful and may well be a prerequisite to efficient native->Swift compilation, but is a huge headache to get it exactly right.
    }
}

