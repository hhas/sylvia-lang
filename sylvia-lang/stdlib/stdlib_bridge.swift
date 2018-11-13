//
//  stdlib_bridge
//

// TO DO: once language is fully bootstrapped, LIBRARY_bridge.swift files should be 100% code-generated from native interface declarations

/*
 
 TO DO: primitive handler signatures should be defined using same syntax as for native handlers; only differences are that parameter+result coercions must be specified, and any 'external' resource requirements must be indicated so that bridging code generator can add the necessary parameters to the func call (all this info will also be used in auto-generated user documentation, and in [optimising] native-to-Swift cross-compilation of user 'scripts')
 
 */



// auto-generated primitive Handler classes

class Handler_add_a_b: PrimitiveHandler {
    
    // bridging coercions
    
    let paramType_0 = asDouble
    let paramType_1 = asDouble
    let returnType = asDouble
    
    // introspection // TO DO: include handler+param+result description strings, categories, hashtags, dependencies, etc
    
    let name: String = "add"
    private(set) lazy var parameters: [Parameter] = [
        (name: "a", type: paramType_0),
        (name: "b", type: paramType_1)
    ]
    private(set) lazy var result: Coercion = returnType
    
    // func wrapper
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        do{
            let arg_0: Double, arg_1: Double
            do {
                arg_0 = try paramType_0.unbox(value: command.argument(0), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 0)
            }
            do {
                arg_1 = try paramType_1.unbox(value: command.argument(1), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 1)
            }
            let result = try add(a: arg_0, b: arg_1)
            return try returnType.box(value: result, env: handlerEnv)
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}


class Handler_subtract_a_b: PrimitiveHandler {
    
    // bridging coercions
    
    let paramType_0 = asDouble
    let paramType_1 = asDouble
    let returnType = asDouble
    
    // introspection
    
    let name: String = "subtract"
    private(set) lazy var parameters: [Parameter] = [
        (name: "a", type: paramType_0),
        (name: "b", type: paramType_1)
    ]
    private(set) lazy var result: Coercion = returnType
    
    // func wrapper
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        do{
            let arg_0: Double, arg_1: Double
            do {
                arg_0 = try paramType_0.unbox(value: command.argument(0), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 0)
            }
            do {
                arg_1 = try paramType_1.unbox(value: command.argument(1), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 1)
            }
            let result = try subtract(a: arg_0, b: arg_1)
            return try returnType.box(value: result, env: handlerEnv)
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}

//

class Handler_show_value: PrimitiveHandler {
    
    let param_0 = asAny // note: can't use a (name:type:) tuple here as it won't coerce to less specific Parameter type
    
    let name: String = "show"
    private(set) lazy var parameters: [Parameter] = [(name: "value", type: param_0)]
    let result: Coercion = asNothing
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        do{
            let arg_0: Value
            do {
                arg_0 = try param_0.unbox(value: command.argument(0), env: commandEnv) // unboxing evaluates argument
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 0)
            }
            show(
                value: arg_0
            )
            return noValue // autogenerate alternate code to return `nothing` instead of calling `box()`
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}

//

class Handler_store_name_value_readOnly: PrimitiveHandler {
    
    // bridging coercions
    
    let paramType_0 = asString
    let paramType_1 = asAny
    let paramType_2 = asBool // TO DO: use enum?
    let returnType = asAny
    
    // introspection
    
    let name: String = "store"
    private(set) lazy var parameters: [Parameter] = [
        (name: "name", type: paramType_0),
        (name: "value", type: paramType_1),
        (name: "readOnly", type: paramType_2)
    ]
    private(set) lazy var result: Coercion = returnType
    
    // func wrapper
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        do{
            let arg_0: String, arg_1: Value, arg_2: Bool
            do {
                arg_0 = try paramType_0.unbox(value: command.argument(0), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 0)
            }
            do {
                arg_1 = try paramType_1.unbox(value: command.argument(1), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 1)
            }
            do {
                arg_2 = try paramType_2.unbox(value: command.argument(2), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 2)
            }
            let result = try store(name: arg_0, value: arg_1, readOnly: arg_2, commandEnv: commandEnv)
            return try returnType.box(value: result, env: handlerEnv)
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}


class Handler_defineHandler_name_parameters_result_body: PrimitiveHandler {
    
    // bridging coercions
    
    // defineHandler(name: String, parameters: [Parameter], result: Coercion, body: Value, commandEnv: Env) throws -> Handler
    
    let paramType_0 = asString
    let paramType_1 = AsArray(asString) // TO DO: currently doesn't support coercions
    let paramType_2 = asAny // coercion object
    let paramType_3 = asIs
    let returnType = asAny
    
    // introspection
    
    let name: String = "define"
    private(set) lazy var parameters: [Parameter] = [
        (name: "name", type: paramType_0),
        (name: "parameters", type: paramType_1),
        (name: "result", type: paramType_2),
        (name: "body", type: paramType_3)
    ]
    private(set) lazy var result: Coercion = returnType
    
    // func wrapper
    
    func call(command: Command, commandEnv: Env, handlerEnv: Env, type: Coercion) throws -> Value {
        do{
            let arg_0: String, arg_1: [Parameter], arg_2: Coercion, arg_3: Value
            do {
                arg_0 = try paramType_0.unbox(value: command.argument(0), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 0)
            }
            do {
                arg_1 = try paramType_1.unbox(value: command.argument(1), env: commandEnv) .map{return(name:$0,type:asAny)} // KLUDGE; TO DO: define AsParameter coercion
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 1)
            }
            do {
                arg_2 = try paramType_2.unbox(value: command.argument(2), env: commandEnv) as! Coercion // KLUDGE; TO DO: define AsCoercion coercion
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 2)
            }
            do {
                arg_3 = try paramType_3.unbox(value: command.argument(3), env: commandEnv)
            } catch {
                throw BadArgumentException(command: command, handler: self, index: 2)
            }
            let result = try defineHandler(name: arg_0, parameters: arg_1, result: arg_2, body: arg_3, commandEnv: commandEnv)
            return try returnType.box(value: result, env: handlerEnv)
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}



// auto-generated module load function

func stdlib_load(env: Env) throws { // TO DO: this adds directly to supplied env rather than creating its own; who should be responsible for creating module namespaces? (and who is responsible for adding modules to a global namespace where scripts can access them); Q. what is naming convention for 3rd-party modules? (e.g. reverse domain), and how will those modules appear in namespace (e.g. flat/custom name or hierarchical names [e.g. `com.foo.module[.handler]`])
    try env.add(Handler_add_a_b()) // TO DO: loading should never fail (unless there's a module implementation bug)
    try env.add(Handler_subtract_a_b())
    try env.add(Handler_show_value())
    try env.add(Handler_store_name_value_readOnly())
    try env.add(Handler_defineHandler_name_parameters_result_body())
    
    
    
    // TO DO: unlike primitive handlers, bridging coercions must be manually implemented in full; however, it may be possible to auto-generate the glue code that enables them to be added to stdlib's env and call()-ed from native code with additional constraints, e.g. `list(text,min:1,max:10)`. Currently, Coercion.init() requires constraints to be supplied as Swift values, but 'convenience' bridging initializers could be added via code-generated extensions that perform the requisite unboxing (ideally using extant Coercion classes assuming it doesn't all get ridiculously circular); conversely, Coercion objects should be able to emit their own construction code as both native commands and Swift code, for use in pretty printing and Swift code generation respectively.
    
    try env.add(asAny)
    
    try env.add(asText)
    try env.add(asBool)
    try env.add(asDouble)
    
    try env.add(asList)
    
    try env.add(AsDefault(asAny, noValue)) // note: AsDefault requires dummy constraint args to instantiate; native language will call() it to create new instances with appropriate constraints
    
    // TO DO: what constants?
    
    
    try env.set("nothing", to: noValue)
    try env.set("pi", to: piValue)
    
    // not sure if defining true/false constants is a good idea; if using 'emptiness' to signify true/false, having `true`/`false` constants that evaluate to anything other than `true`/`false` is liable to create far more confusion than convenience (one option is to define a formal Boolean value class and use that, but that raises questions on how to coerce it to text - it can't go to "true"/"false", as "false" is non-empty text, so would have to go to "ok"/"" which is unintuitive; another option is to copy Swift's approach where *only* true/false can be used in Boolean contexts, but that doesn't fit well with weak typing behavior; last alternative is to do away with true/false constants below and never speak of them again; note that only empty text and lists should be treated as Boolean false; 1 and 0 would both be true since both are represented as non-empty text, whereas strongly typed languages such as Python can treat 0 as false; the whole point of weak typing being to roundtrip data without changing its meaning even as its representation changes)
    try env.set("true", to: trueValue)
    try env.set("false", to: falseValue)
}


