//
//  identifier.swift
//

// TO DO: when resolving global names (e.g. module-defined handlers), memoize constant value if it's read-only or value's container (stack frame) if it isn't (in the case of Command, value is a Handler instance so additional optimizations can be done for argument matching)


class Identifier: Expression {
    
    // TO DO: while the goal is to build a slow AST interpreter with good runtime introspection that facilitates easy exploration and debugging plus option to cross-compile to fast[er] Swift code, there may still be a few parse-/run-time optimizations worth implementing once all the essentials are done. e.g. How can/when should Identifiers and Commands memoize non-maskable, read-only slot values (`nothing`, `π`, `+`, `as`, `show()`, etc) so they never need looked more than once? In theory, primitive library-defined constants could be defined in LIB_operators.swift as .constant(Value) parsefuncs, telling parser to substitute immediately as it builds the AST. Even when slots are writable, as long as they're guaranteed never to be masked the cost of identifier/command lookups could be reduced by capturing the environment frame in which they're defined, avoiding a full recursive lookup of Env every time.
    
    override var description: String { return "‘\(self.name)’" }
    
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
        //let (value, lexicalEnv) = try env._get(self.key)
        let value = try env.get(self.key)
        // TO DO: catch null coercions, c.f. below?
        do {
            //return try value.nativeEval(env: lexicalEnv, coercion: coercion)
            return try value.nativeEval(env: env, coercion: coercion)
        } catch {
            print("Identifier `\(self.name)` couldn't coerce following value to `\(coercion)`: \(value)")
            throw error
        }
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        //let (value, lexicalEnv) = try env._get(self.key)
        let value = try env.get(self.key)
        // TO DO: where should null coercion errors become permanent?
        //do {
        //return try value.bridgingEval(env: lexicalEnv, coercion: coercion)
        return try value.bridgingEval(env: env, coercion: coercion)
        //} catch let error as NullCoercionError {
        //    throw CoercionError(value: self, coercion: coercion).from(error)
        //}
    }
}



class Command: Expression {
    
    override var description: String {
        let args = self.arguments.map{ (argument: Argument) -> String in
            if let identifier = argument.label {
                return Pair(identifier, argument.value).description
            } else {
                return argument.value.description
            }
        }
        return "‘\(self.name)’ (\(args.joined(separator:", ")))" }
    
    override class var nominalType: Coercion { return asCommandLiteral }
    
    let name: String
    let key: String
    let arguments: [Argument]
    
    init(_ name: String, _ arguments: [Value]) {
        self.name = name
        self.key = name.lowercased()
        self.arguments = arguments.map{
            if let pair = $0 as? Pair, let identifier = pair.swiftValue.0 as? Identifier {
                return (identifier, pair.swiftValue.1)
            } else {
                return (nil, $0)
            }
        }
    }
    
    // TO DO: caching? (the challenge here is that `A.B()`/`B() of A` requires that A supply the Env [or Env-like object], but there's no guarantee that A will be the same every time; one possible solution is to implement `nativeEval(inScope:Accessor,env:Env,…)`), which would allow commands and identifiers to lookup in scope instead of env; given `of(B(),A)`, the` of` `handler` implements nativeEval() to look up the B handler in A then call()s it with current scope as commandEnv and A as handlerEnv
    
    override func nativeEval(env: Scope, coercion: Coercion) throws -> Value {
        return try env.handle(command: self, commandEnv: env, coercion: coercion)
    }
    
    override func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType {
        fatalError() // TO DO: implement; one option might be to tunnel primitive results through native eval, returning an opaque Value that is a minimal wrapper around Swift value, avoiding need for generic `swiftCall`
    }
}
