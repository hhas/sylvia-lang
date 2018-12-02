//
//  expression.swift
//
//  

// TO DO: need to check null coercion errors are always rethrown at correct point(s) (correction: all errors need to be caught and rethrown [this will take care of null coercion errors too] to provide traceback)


// TO DO: is it possible/practical for all toTYPE methods to be added via extension?


// abstract base classes for values (blocks, identifiers, commands) that evaluate to yield other values

class Expression: Value {
    
    // forward all Expression.toTYPE() calls to evaluate()/run()
    
    override var nominalType: Coercion { return asAnythingOrNothing }
    
    //
    
    // not sure this helps
    internal func safeRun<T: Value>(env: Env, type: Coercion, function: String = #function) throws -> T {
        let value: Value
        do {
            value = try self.run(env: env, type: type)
        } catch let e as NullCoercionError { // check
            print("\(self).safeRun(type:\(type)) caught null coercion result.")
            //throw CoercionError(value: self, type: type)
            throw e
        }
        guard let result = value as? T else { // kludgy; any failure is presumably an implementation bug in a Coercion.coerce()/Value.toTYPE() method
            throw InternalError("\(Swift.type(of:self)) \(function) expected \(type) coercion to return \(T.self) but got \(Swift.type(of: value)): \(value)")
        }
        return result
    }
    
    //
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return try self.run(env: env, type: type)
    }
    
    override func toText(env: Env, type: Coercion) throws -> Text {
        return try self.safeRun(env: env, type: type)
    }
    
    override func toList(env: Env, type: AsList) throws -> List {
        return try self.safeRun(env: env, type: type) // ditto
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try self.evaluate(env: env, type: type)
    }
}


// concrete expression classes

class Identifier: Expression {
    
    // TO DO: while the goal is to build a slow AST interpreter with good runtime introspection that facilitates easy exploration and debugging plus option to cross-compile to fast[er] Swift code, there may still be a few parse-/run-time optimizations worth implementing once all the essentials are done. e.g. How can/when should Identifiers and Commands memoize non-maskable, read-only slot values (`nothing`, `π`, `+`, `as`, `show()`, etc) so they never need looked more than once? In theory, primitive library-defined constants could be defined in LIB_operators.swift as .constant(Value) parsefuncs, telling parser to substitute immediately as it builds the AST. Even when slots are writable, as long as they're guaranteed never to be masked the cost of identifier/command lookups could be reduced by capturing the environment frame in which they're defined, avoiding a full recursive lookup of Env every time.
    
    override var description: String { return "\(self.name)" }
    
    let name: String // used by assignment operator
    
    init(_ name: String) {
        self.name = name
    }
    
    private func lookup(env: Env) throws -> (value: Value, lexicalEnv: Env) {
        guard let (slot, lexicalEnv) = env.find(self.name) else {
            throw ValueNotFoundError(name: self.name, env: env)
        }
        return (slot.value, lexicalEnv)
    }
    
    override func evaluate<T: BridgingCoercion>(env: Env, type: T) throws -> T.SwiftType {
        let (value, lexicalEnv) = try self.lookup(env: env)
       // do {
        return try value.evaluate(env: lexicalEnv, type: type)
        //} catch is NullCoercionError {
        //    throw CoercionError(value: self, type: type)
        //}
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        let (value, lexicalEnv) = try self.lookup(env: env)
        do {
            return try value.run(env: lexicalEnv, type: type)
        } catch {
            print("Identifier `\(self.name)` couldn't coerce following value to `\(type)`: \(value)")
            throw error
        }
    }
}


class Command: Expression {
    
    override var description: String { return "‘\(self.name)’ (\((self.arguments.map{$0.description}).joined(separator:", ")))" }
    
    let name: String
    let arguments: [Value]
    
    init(_ name: String, _ arguments: [Value]) {
        self.name = name
        self.arguments = arguments
    }
    
    func argument(_ index: Int) -> Value {
        return index >= arguments.count ? noValue : self.arguments[index]
    }
    
    private func lookup(env: Env) throws -> (handler: Callable, lexicalEnv: Env) {
        guard let (slot, lexicalEnv) = env.find(self.name), let handler = slot.value as? Callable else {
            throw HandlerNotFoundError(name: self.name, env: env)
        }
        return (handler, lexicalEnv)
    }
    
    override func evaluate<T: BridgingCoercion>(env: Env, type: T) throws -> T.SwiftType {
        fatalError() // TO DO
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        //print("Calling run on Command:", self)
        let (handler, handlerEnv) = try self.lookup(env: env)
        //print("Got Handler \(handler.name):", handler)
        do {
            return try handler.call(command: self, commandEnv: env, handlerEnv: handlerEnv, type: type)
        } catch {
            //print("Handler ‘\(handler.name)’ failed:", error)
            throw error
        }
    }
}


//


class Thunk: Expression {
    
    override var description: String { return "<Thunk \(self.value)>" }
    
    private let value: Value
    private let env: Env
    private let type: Coercion
    
    init(_ value: Value, env: Env, type: Coercion) {
        self.value = value
        self.env = env
        self.type = type
    }
    
    func force() throws -> Value {
        return try self.value.run(env: self.env, type: self.type)
    }
    
    override internal func safeRun<T: Value>(env: Env, type: Coercion, function: String = #function) throws -> T {
        let value: Value
        do {
            value = try self.force().run(env: env, type: type) // TO DO: check, fix;
        } catch is NullCoercionError {
            print("\(self).safeRun(type:\(type)) caught null coercion result.")
            //throw CoercionError(value: self, type: type)
            
            throw NullCoercionError(value: self, type: type)
        }
        guard let result = value as? T else { // kludgy; any failure is presumably an implementation bug in a Coercion.coerce()/Value.toTYPE() method
            throw InternalError("\(Swift.type(of:self)) \(function) expected \(type) coercion to return \(T.self) but got \(Swift.type(of: value)): \(value)")
        }
        return result
    }

    
    // evaluating a thunk forces it (unless type specifies AsThunk, in which case it thunks again)
    
    override func evaluate<T: BridgingCoercion>(env: Env, type: T) throws -> T.SwiftType {
        do {
            return try type.unbox(value: self.force(), env: env) // TO DO: fix
        } catch is NullCoercionError {
            throw CoercionError(value: self, type: type)
        }
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        return try type.coerce(value: self, env: env)
    }

}


// expression sequences

class Block: Expression { // a sequence of zero or more Values to evaluate in turn; result is last value evaluated; TO DO: use Icon-style evaluation, where 'failure' result causes subsequent evals to be skipped? (this might be done via exceptions, c.f. null coercion, rather than actual return values)
    
    // TO DO: implement Formatter class + visitor API, allowing AST to be pretty printed with indentation, operator syntax
    
    override var description: String { return "{\n\t\(self.body.map{$0.description}.joined(separator:"\n"))\n}" }
    
    let body: [Value]
    
    init(_ body: [Value]) {
        self.body = body
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        var result: Value = noValue
        for value in self.body {
            result = try value.run(env: env, type: asResult) // TO DO: `return VALUE` would throw a recoverable exception [and be caught here? or further up in Callable? Q. what about `let foo = {some block}` idiom? should block be callable for this?]
        }
        return try type.coerce(value: result, env: env) // not quite right
    }
}


class ScriptAST: Block { // TO DO: what should be main entry point[s] for evaluation, node-walking, etc? (note: might want to put public convenience eval entry point on Env, which can provide options for per-line/whole script execution, sharing/creating/copying/persisting environment state as appropriate, c.f. AppleScript OSA component)

    override var description: String { return self.body.map{$0.description}.joined(separator:"\n") }

}

