//
//  expression.swift
//

// TO DO: need to check null coercion errors are always rethrown at correct point(s) (correction: all errors need to be caught and rethrown [this will take care of null coercion errors too] to provide traceback)


// TO DO: is it possible/practical for all toTYPE methods to be added via extension?

// TO DO: operator-generated commands/identifiers should be annotated with operator definition; this can be used by pretty-printer and in error message generation (e.g. "‘-’ handler’s ‘left’ parameter" should read as "‘-’ operator’s ‘left’ operand" in BadArgumentError message)



// concrete expression classes

class Identifier: Expression {
    
    // TO DO: while the goal is to build a slow AST interpreter with good runtime introspection that facilitates easy exploration and debugging plus option to cross-compile to fast[er] Swift code, there may still be a few parse-/run-time optimizations worth implementing once all the essentials are done. e.g. How can/when should Identifiers and Commands memoize non-maskable, read-only slot values (`nothing`, `π`, `+`, `as`, `show()`, etc) so they never need looked more than once? In theory, primitive library-defined constants could be defined in LIB_operators.swift as .constant(Value) parsefuncs, telling parser to substitute immediately as it builds the AST. Even when slots are writable, as long as they're guaranteed never to be masked the cost of identifier/command lookups could be reduced by capturing the environment frame in which they're defined, avoiding a full recursive lookup of Env every time.
    
    override var description: String { return "\(self.name)" }
    
    override class var nominalType: Coercion { return asIdentifierLiteral }
    
    let name: String
    let key: String // used by assignment
    let symbol: Symbol // may be used by operator parsers, e.g. `item at 1` -> `'at'(#item,1)`
    
    // TO DO: use key (all-lowercase) for env lookups
    
    init(_ name: String) {
        self.symbol = Symbol(name)
        self.name = name // TO DO: how/when to check if name should be quoted? (this will require access to lexer's character tables and to operator tables; lexer itself might want to offer quoting hints based on whether or not the identifier was already quoted in source code; also, if operator table is going to be extended by imported libraries, this *will* require a special form, `use LIBRARY [with_syntax VERSION]`, that lexer can recognize and process at top-level of code)
        self.key = name.lowercased()
    }
    
    override func nativeEval(env: Scope, coercion: Coercion) throws -> Value {
        let (value, lexicalEnv) = try env.get(self.key)
        // TO DO: catch null coercions, c.f. below?
        do {
            return try value.nativeEval(env: lexicalEnv, coercion: coercion)
        } catch {
            print("Identifier `\(self.name)` couldn't coerce following value to `\(coercion)`: \(value)")
            throw error
        }
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        let (value, lexicalEnv) = try env.get(self.key)
        // TO DO: where should null coercion errors become permanent?
        //do {
        return try value.bridgingEval(env: lexicalEnv, coercion: coercion)
        //} catch let error as NullCoercionError {
        //    throw CoercionError(value: self, coercion: coercion).from(error)
        //}
    }
}


class Command: Expression {
    
    override var description: String { return "‘\(self.name)’ (\((self.arguments.map{$0.description}).joined(separator:", ")))" }
    
    override class var nominalType: Coercion { return asCommandLiteral }
    
    let name: String
    let key: String
    let arguments: [Value]
    
    init(_ name: String, _ arguments: [Value]) {
        self.name = name
        self.key = name.lowercased()
        self.arguments = arguments
    }
    
    func argument(_ index: Int) -> Value {
        return index >= arguments.count ? noValue : self.arguments[index]
    }
    
    // TO DO: caching? (the challenge here is that `A.B()`/`B() of A` requires that A supply the Env [or Env-like object], but there's no guarantee that A will be the same every time; one possible solution is to implement `nativeEval(inScope:Accessor,env:Env,…)`), which would allow commands and identifiers to lookup in scope instead of env; given `of(B(),A)`, the` of` `handler` implements nativeEval() to look up the B handler in A then call()s it with current scope as commandEnv and A as handlerEnv

    override func nativeEval(env: Scope, coercion: Coercion) throws -> Value {
        let (value, handlerEnv) = try env.get(self.key)
        guard let handler = value as? Callable else { throw HandlerNotFoundError(name: self.name, env: env) }
        return try handler.call(command: self, commandEnv: env, handlerEnv: handlerEnv, coercion: coercion)
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        fatalError() // TO DO: implement; one option might be to tunnel primitive results through native eval, returning an opaque Value that is a minimal wrapper around Swift value, avoiding need for generic `swiftCall`
    }
}


//


class Thunk: Expression {
    
    override var description: String { return "<Thunk \(self.value)>" }
    
    private let value: Value
    private let env: Scope
    private let coercion: Coercion
    
    init(_ value: Value, env: Scope, coercion: Coercion) {
        self.value = value
        self.env = env
        self.coercion = coercion
    }
    
    // currently, evaling a thunk with non-thunk Coercion should call Thunk.nativeEval(C)->C.coerce()->Thunk.toTYPE()->Thunk.safeRun(), which forces original value
    
    override internal func safeRun<T: Value>(env: Scope, coercion: Coercion, function: String = #function) throws -> T {
        let value: Value
        do {
            // force thunked value // TO DO: this should simplify once Coercion.intersect() is implemented
            value = try self.value.nativeEval(env: self.env, coercion: self.coercion).nativeEval(env: env, coercion: coercion)
        } catch is NullCoercionError {
            print("\(self).safeRun(coercion:\(coercion)) caught null coercion result.")
            //throw CoercionError(value: self, coercion: coercion)
            
            throw NullCoercionError(value: self, coercion: coercion)
        }
        guard let result = value as? T else { // kludgy; any failure is presumably an implementation bug in a Coercion.coerce()/Value.toTYPE() method
            throw InternalError("\(type(of:self)) \(function) expected \(coercion) coercion to return \(T.self) but got \(type(of: value)): \(value)")
        }
        return result
    }

    
    // evaluating a thunk forces it (unless coercion specifies AsThunk, in which case it thunks again)
    
    override func nativeEval(env: Scope, coercion: Coercion) throws -> Value {
        // TO DO: this is why we need to implement Coercion.intersect(): if `coercion` is another thunk, it will capture self.coercion and itself in a new thunk, otherwise it will expand value to intersection of both; right now,
        return try coercion.coerce(value: self, env: env)
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        return try coercion.unbox(value: self, env: env)
    }
}


// expression sequences

// TO DO: under what circumstances can/should blocks implement Callable? (in normal use, a literal block is evaluated same as any other literal value: any command can take a block as argument, coercing its result to the required type)

class Block: Expression { // a sequence of zero or more Values to evaluate in turn; result is last value evaluated; TO DO: use Icon-style evaluation, where 'failure' result causes subsequent evals to be skipped? (this might be done via exceptions, c.f. null coercion, rather than actual return values)
    
    // TO DO: implement Formatter class + visitor API, allowing AST to be pretty printed with indentation, operator syntax
    
    override var description: String { return "{\n\t\(self.body.map{$0.description}.joined(separator:"\n\t"))\n}" }
    
    let body: [Value]
    
    init(_ body: [Value]) {
        self.body = body
    }
    
    override func nativeEval(env: Scope, coercion: Coercion) throws -> Value { // TO DO: visualization hooks? (learning, debugging, profiling, etc)
        var result: Value = noValue
        for value in self.body {
            result = try value.nativeEval(env: env, coercion: asAnything) // TO DO: `return VALUE` would throw a recoverable exception [and be caught here? or further up in Callable? Q. what about `let foo = {some block}` idiom? should block be callable for this?]
        }
        return try coercion.coerce(value: result, env: env) // TO DO: how to pass output coercion to last expr to be evaluated? (for last expr in body, should be enough to take it out of self.body and eval it here with `coercion`; if `return VALUE` op is implemented, it could break out of eval loop and again have VALUE coerced to return type here; another trick would be to change last item of body to `return(ITEM)` during initialization, making the value return explicit, though need to consider how this'd work for handler bodies vs control flow bodies)
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        var result: Value = noValue
        for value in self.body { result = try value.nativeEval(env: env, coercion: asAnything) }
        return try coercion.unbox(value: result, env: env)
    }
}


class ScriptAST: Block { // TO DO: what should be main entry point[s] for evaluation, node-walking, etc? (note: might want to put public convenience eval entry point on Env, which can provide options for per-line/whole script execution, sharing/creating/copying/persisting environment state as appropriate, c.f. AppleScript OSA component)

    override var description: String { return self.body.map{$0.description}.joined(separator:"\n") }

}

