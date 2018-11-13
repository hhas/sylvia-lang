//
//  expression.swift
//
//  


// TO DO: is it possible/practical for all toTYPE methods to be added via extension?


// abstract base classes for values (blocks, identifiers, commands) that evaluate to yield other values

class Expression: Value {
    
    // forward all Expression.toTYPE() calls to evaluate()/run()
    
    // Q. if Value is a Protocol and Expression is a protocol, and both have corresponding extensions implementing standard toTYPE methods, how will that compile? (one advantage of protocols over subclassing is that it avoids nasty 'abstract methods' such as those below)
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return try self._run(env: env, type: type)
    }
    
    override func toText(env: Env, type: Coercion) throws -> Text {
        return try self._run(env: env, type: type)
    }
    
    override func toList(env: Env, type: AsList) throws -> List {
        return try self._run(env: env, type: type) // ditto
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try self.evaluate(env: env, type: type)
    }
    
    //
    
    func _run<T: Value>(env: Env, type: Coercion, function: String = #function) throws -> T {
        let value = try self.run(env: env, type: type)
        guard let result = value as? T else { // we pull our punches here as it's still less painful than trying to implement strong typing throughout runtime
            throw InternalError("\(Swift.type(of:self)) \(function) expected \(type) coercion to return \(T.self) but got \(Swift.type(of: value)): \(value)")
        }
        return result
    }
    
    // subclasses must override the following abstract methods:
    
    func evaluate<T: BridgingCoercion>(env: Env, type: T) throws -> T.SwiftType {
        fatalError("Expression subclasses must override \(#function).")
    }
    
    func run(env: Env, type: Coercion) throws -> Value {
        fatalError("Expression subclasses must override \(#function).")
    }
}


// concrete expression classes

class Block: Expression { // a sequence of zero or more Values to evaluate in turn; result is last value evaluated; TO DO: use Icon-style evaluation, where 'failure' result causes subsequent evals to be skipped? (this might be done via exceptions, c.f. null coercion, rather than actual return values)
    
    override var description: String { return "\(self.body)" }
    
    let body: [Value]
    
    init(_ body: [Value]) {
        self.body = body
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        var result: Value = noValue
        for value in self.body {
            result = try asAny.coerce(value: value, env: env) // TO DO: `return VALUE` would throw a recoverable exception [and be caught here? or further up in Callable? Q. what about `let foo = {some block}` idiom? should block be callable for this?]
        }
        return try type.coerce(value: result, env: env)
    }
}


class Identifier: Expression {
    
    override var description: String { return "\(self.name)" }
    
    let name: String // used by assignment operator
    
    init(_ name: String) {
        self.name = name
    }
    
    private func lookup(env: Env) throws -> (value: Value, lexicalEnv: Env) {
        guard let (slot, lexicalEnv) = env.find(self.name) else {
            throw ValueNotFoundException(name: self.name, env: env)
        }
        return (slot.value, lexicalEnv)
    }
    
    override func evaluate<T: BridgingCoercion>(env: Env, type: T) throws -> T.SwiftType {
        let (value, lexicalEnv) = try self.lookup(env: env)
        return try type.unbox(value: value, env: lexicalEnv)
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        let (value, lexicalEnv) = try self.lookup(env: env)
        return try type.coerce(value: value, env: lexicalEnv)
    }
}


class Command: Expression {
    
    override var description: String { return "\(self.name)\(self.arguments)" }
    
    let name: String
    let arguments: [Value]
    
    init(_ name: String, _ arguments: [Value]) {
        self.name = name
        self.arguments = arguments
    }
    
    func argument(_ index: Int) -> Value {
        return index > arguments.count ? noValue : self.arguments[index]
    }
    
    private func lookup(env: Env) throws -> (handler: Callable, lexicalEnv: Env) {
        guard let (slot, lexicalEnv) = env.find(self.name), let handler = slot.value as? Callable else {
            throw HandlerNotFoundException(name: self.name, env: env)
        }
        return (handler, lexicalEnv)
    }
    
    override func evaluate<T: BridgingCoercion>(env: Env, type: T) throws -> T.SwiftType {
        fatalError()
    }
    
    override func run(env: Env, type: Coercion) throws -> Value {
        let (handler, handlerEnv) = try self.lookup(env: env)
        return try handler.call(command: self, commandEnv: env, handlerEnv: handlerEnv, type: type)
    }
}


//


class Thunk: Value {
    
    override var description: String { return "<Thunk \(self.value)>" }
    
    private let value: Value
    private let env: Env
    private let type: Coercion
    
    init(_ value: Value, env: Env, type: Coercion) {
        self.value = value
        self.env = env
        self.type = type
    }
    
    private func force() throws -> Value {
        return try self.type.coerce(value: self.value, env: self.env)
    }
    
    // evaluating a thunk forces it (unless type specifies AsThunk, in which case it thunks again)
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return try self.force()
    }
    override func toText(env: Env, type: Coercion) throws -> Text {
        return try type.coerce(value: self.force(), env: env) as! Text
    }
    override func toList(env: Env, type: AsList) throws -> List {
        return try type.coerce(value: self.force(), env: env) as! List
    }
    override func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try type.unbox(value: self.force(), env: env)
    }
}
