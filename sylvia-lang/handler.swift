//
//  handler.swift
//


typealias Parameter = (name: String, type: Coercion)




enum EnvType { // used in primitive libraries; indicates what, if any, environment[s] the handler needs to access (module, body, and/or caller) in order to perform its work
    case noEnv
    case handlerEnv // TO DO: one of the challenges with handlerEnv (i.e. moduleEnv) is legality of the module's handlers modifying the module's slots; in principle, a module could just use its own internal Swift vars - is there any situation where it would be preferable to push this state into Env? (e.g. module persistency; Swift vars won't persist, but Env state could be written to disk)
    case bodyEnv // create a sub-env from handler scope
    case commandEnv
    // TO DO: include read-only/write-only/read-write flags? this can be used to determine [some] side-effects, which might in turn be used by runtime to memoize outputs (e.g. for performance, or to enable backtracking in 'debugger' mode), or in user docs to indicate scope of action (unfortunately, Swift/Cocoa doesn't provide a mechanism to indicate other side effects, e.g. file read/write, so that sort of metainfo would have to be supplied by module developer on trust)
}




protocol Callable { // TO DO: might be easier if this is class; Handlers and Coercions can then inherit from it, overriding name, parameters, call() [athough it's mildly irritating that Swift doesn't have `abstract` keyword, avoiding need to define `fatalError()` implementations here]
    
    // standard introspection // TO DO: what about documentation, metainfo (e.g. categories, hashtags)
    
    var name: String { get }
    var parameters: [Parameter] { get }
    var result: Coercion { get }
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value

}



// concrete classes

class BoundHandler: Value, Callable {
    
    var name: String { return self.handler.name }
    var parameters: [Parameter] { return self.handler.parameters }
    var result: Coercion { return self.handler.result }
    
    let handler: Callable
    let handlerEnv: Env
    
    init(handler: Callable, handlerEnv: Env) {
        self.handler = handler
        self.handlerEnv = handlerEnv
    }
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        // note: command name may be different to handler name if handler has been assigned to different slot
        return try self.handler.call(command: command, commandEnv: commandEnv, handlerEnv: self.handlerEnv, type: type)
    }
}


class Handler: Value, Callable { // native handler
    
    override var description: String { return "\(self.name)\(self.parameters)" }
    
    
    // for now, parameters are positional; eventually they should be labeled (which requires more complex unpacking algorithm to match labeled/unlabeled command arguments to labeled parameters, particularly when args are omitted from anywhere other than end of arg list)
    
    let name: String // TO DO: name and parameters should be introspectable; might consider making Callable a protocol which any Value can implement (e.g. Coercion should implement call method allowing additional constraints to be applied, e.g. `foo as list (type:text, min:1, max:10)` would call standard `AsList` coercion stored in global `list` slot in order to specialize it)
    let parameters: [Parameter]
    let body: Value
    let result: Coercion
    
    init(name: String, parameters: [Parameter], result: Coercion, body: Value) {
        self.name = name
        self.parameters = parameters
        self.body = body
        self.result = result
    }
    
    // unbox()/coerce() support; returns BoundHandler capturing both handler and its original handlerEnv; this allows identifiers to retrieve handlers and pass as arguments/assign to other vars
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return BoundHandler(handler: self, handlerEnv: env)
    }
    
    // called by Command
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        do {
            let bodyEnv = handlerEnv.child()
            var arguments = command.arguments
            for (parameterName, parameterType) in self.parameters {
                let value = arguments.count > 0 ? arguments.removeFirst() : noValue
                //print("unpacking argument \(parameterName): \(value)")
                try bodyEnv.set(parameterName, to: parameterType.coerce(value: value, env: commandEnv)) // expand/thunk parameter using command's lexical scope
            }
            if arguments.count > 0 {
                print("unconsumed arguments: \(arguments)") // throw TooManyArgumentsException?
            }
            return try type.coerce(value: self.result.coerce(value: self.body, env: bodyEnv), env: commandEnv) // TO DO: intersect Coercions to avoid double-coercion (Q. not sure what env[s] to use)
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}


