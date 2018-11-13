//
//  stdlib.swift
//

/*
 
 Note: primitive libraries are implemented as Swift funcs that follow standardized naming and parameter/return conventions; all bridging code is auto-generated. Clean separation of native/bridging/primitive logic has big advantages over Python/Ruby/etc-style modules where primitive functions must perform all their own bridging:
 
    - faster, simpler, less error-prone development of primitive libraries
 
    - free API documentation
 
    - free partial optimizing compilation (e.g. when composing two primitive functions that return/accept same Swift type, boxing/unboxing steps can be skipped)
 
 */

// math

// signature: add(a: primitive(double), b: primitive(double)) returning primitive(double)
// requirements: [throws]

func add(a: Double, b: Double) throws -> Double { // TO DO: math funcs should use Scalars (union of Int|UInt|Double) (e.g. pinch Scalar struct from entoli) allowing native language to have a single unified `number` type (numeric values might themselves be represented in runtime as Text value annotated with scalar info for efficiency, or as distinct Number values that can be coerced to/from Text) (note that while arithmetic/comparison library funcs will have to work with Scalars in order to handle both ints and floats, Swift code generation could reduce overheads when both arguments are known to be ints, in which case it'll output`a+b`, otherwise `Double(a)+Double(b)`)
    return a + b // TO DO: check how Double signals out-of-range
}

func subtract(a: Double, b: Double) throws -> Double { // for now, use Doubles; eventually there should be a generalized Number type/annotation that encapsulates Int|UInt|Double, and eventually BigInt, Decimal, Quantity, etc
    return a - b
}


// misc

// signature: show(value: anything)
// requirements: [stdout]

// TO DO: would it be better to pass explicitly required pipes as arguments? need to give some thought to read/write model; rather than accessing std/FS/network pipes directly, 'mount' them in local/global namespace as Values which can be manipulated via standard get/set operations (note: the value's 'type' should be inferred where practical, e.g. from filename extension/MIME type where available, or explicitly indicated in `attach` command, enabling appropriate transcoders to be automatically found and used)

func show(value: Value) { // primitive library function
    print(value)
}


// state

// signature: defineHandler(name: primitive(text), parameters: default([], parametersList), result: default(anything, type), body: primitive(expression)) returning handler
// requirements: [commandEnv] // any required env params are appended to bridging call in standard order (commandEnv,handlerEnv,bodyEnv)

// TO DO: need asParameterList coercion that knows how to parse user-defined parameters list (which may consist of label strings and/or (label,coercion) tuples, and may include optional description strings too)
func defineHandler(name: String, parameters: [Parameter], result: Coercion, body: Value, commandEnv: Env) throws -> Handler {
    let  h = Handler(name: name, parameters: parameters, result: result, body: body)
    try commandEnv.add(h)
    return h
}


// signature: store(name: primitive(text), value: anything, readOnly: default(true, boolean)) returning anything
// requirements: [commandEnv]

func store(name: String, value: Value, readOnly: Bool, commandEnv: Env) throws -> Value {
    try commandEnv.set(name, to: value, readOnly: readOnly)
    return value
}

/*
 
 TO DO: primitive handler signatures should be defined using same syntax as for native handlers; only differences are that parameter+result coercions must be specified, and any 'external' resource requirements must be indicated so that bridging code generator can add the necessary parameters to the func call (all this info will also be used in auto-generated user documentation, and in [optimising] native-to-Swift cross-compilation of user 'scripts')
 
 */




// code-generated primitive Handler classes

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



// TO DO: auto-generated load func

func stdlib_load(env: Env) throws { // TO DO: this adds directly to supplied env rather than creating its own; who should be responsible for creating module namespaces? (and who is responsible for adding modules to a global namespace where scripts can access them); Q. what is naming convention for 3rd-party modules? (e.g. reverse domain), and how will those modules appear in namespace (e.g. flat/custom name or hierarchical names [e.g. `com.foo.module[.handler]`])
    try env.add(Handler_add_a_b()) // TO DO: loading should never fail (unless there's a module implementation bug)
    try env.add(Handler_subtract_a_b())
    try env.add(Handler_show_value())
    try env.add(Handler_store_name_value_readOnly())
    try env.add(Handler_defineHandler_name_parameters_result_body())
    
    // TO DO: method for setting constraints (names should be vars)
    try env.add(asAny)
    
    try env.add(asText)
    try env.add(asBool)
    try env.add(asDouble)
    
    try env.add(asList)
    
    try env.add(AsDefault(asAny, noValue)) // note: AsDefault requires dummy constraint args to instantiate; native language will call() it to create new instances with appropriate constraints
    
    try env.set("nothing", to: noValue)
}
