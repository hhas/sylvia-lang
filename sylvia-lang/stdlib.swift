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

func add(a: Double, b: Double) throws -> Double { // TO DO: math funcs should use Scalars (union of Int|UInt|Double) (e.g. pinch Scalar struct from entoli) allowing native language to have a single unified `number` type (numeric values might themselves be represented in runtime as Text value annotated with scalar info for efficiency, or as distinct Number values that can be coerced to/from Text) (note that while arithmetic/comparison library funcs will have to work with Scalars in order to handle both ints and floats, Swift code generation could reduce overheads when both arguments are known to be ints, in which case it'll output`a+b`, otherwise `Double(a)+Double(b)`)
    return a + b
}

func sub(a: Double, b: Double) throws -> Double { // for now, use Doubles; eventually there should be a generalized Number type/annotation that encapsulates Int|UInt|Double, and eventually BigInt, Decimal, Quantity, etc
    return a - b
}


// misc

func show(value: Value) { // primitive library function
    print(value)
}



/*
 
 TO DO: primitive handler signatures should be defined using same syntax as for native handlers; only difference would be coercion names and env flags, e.g.:
 
     add(a as primitive(number), b as primitive(number)) returning primitive(number)
     sub(a as primitive(number), b as primitive(number)) returning primitive(number)
     show(value as anything)
 
 */



class Handler_add_a_b: CallableValue {
    
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



class Handler_sub_a_b: CallableValue {
    
    // bridging coercions
    
    let paramType_0 = asDouble
    let paramType_1 = asDouble
    let returnType = asDouble
    
    // introspection
    
    let name: String = "sub"
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
            let result = try sub(a: arg_0, b: arg_1)
            return try returnType.box(value: result, env: handlerEnv)
        } catch {
            throw HandlerFailedException(handler: self, error: error)
        }
    }
}



// auto-generated code

class Handler_show_value: CallableValue {
    
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


// TO DO: auto-generated load func

func stdlib_load(env: Env) throws { // TO DO: this adds directly to supplied env rather than creating its own; who should be responsible for creating module namespaces? (and who is responsible for adding modules to a global namespace where scripts can access them); Q. what is naming convention for 3rd-party modules? (e.g. reverse domain), and how will those modules appear in namespace (e.g. flat/custom name or hierarchical names [e.g. `com.foo.module[.handler]`])
    try env.add(handler: Handler_add_a_b()) // TO DO: loading should never fail (unless there's a module implementation bug)
    try env.add(handler: Handler_sub_a_b())
    try env.add(handler: Handler_show_value())
    
    try env.set("text", to: asText)
    try env.set("list", to: asList)
    try env.set("anything", to: asAny)
    
    try env.set("nothing", to: noValue)
}
