//
//  expression.swift
//

// TO DO: need to check null coercion errors are always rethrown at correct point(s) (correction: all errors need to be caught and rethrown [this will take care of null coercion errors too] to provide traceback)


// TO DO: is it possible/practical for all toTYPE methods to be added via extension?

// TO DO: operator-generated commands/identifiers should be annotated with operator definition; this can be used by pretty-printer and in error message generation (e.g. "‘-’ handler’s ‘left’ parameter" should read as "‘-’ operator’s ‘left’ operand" in BadArgumentError message)


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

// TO DO: under what circumstances can/should blocks implement HandlerProtocol? (in normal use, a literal block is evaluated same as any other literal value: any command can take a block as argument, coercing its result to the required type)

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
            result = try value.nativeEval(env: env, coercion: asAnything) // TO DO: `return VALUE` would throw a recoverable exception [and be caught here? or further up in HandlerProtocol? Q. what about `let foo = {some block}` idiom? should block be callable for this?]
        }
        return try coercion.coerce(value: result, env: env) // TO DO: how to pass output coercion to last expr to be evaluated? (for last expr in body, should be enough to take it out of self.body and eval it here with `coercion`; if `return VALUE` op is implemented, it could break out of eval loop and again have VALUE coerced to return type here; another trick would be to change last item of body to `return(ITEM)` during initialization, making the value return explicit, though need to consider how this'd work for handler bodies vs control flow bodies)
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        var result: Value = noValue
        for value in self.body { result = try value.nativeEval(env: env, coercion: asAnything) }
        return try coercion.unbox(value: result, env: env)
    }
}


class ScriptAST: Block { // TO DO: what should be main entry point[s] for evaluation, node-walking, etc? (note: might want to put public convenience eval entry point on Environment, which can provide options for per-line/whole script execution, sharing/creating/copying/persisting environment state as appropriate, c.f. AppleScript OSA component)

    override var description: String { return self.body.map{$0.description}.joined(separator:"\n") }

}

