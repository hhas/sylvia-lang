//
//  coercion.swift
//

/* Notes:

 - Evaluation involves dynamically dispatching on both Value and Coercion subclasses, which is really a job for multimethods, but we make do with double-dispatch where client calls Value which calls Coercion which calls back into Value to obtain the required representation before performing any constraint checks and returning the result. (Current implementation has some bugs due to ill-considered attempt to reduce this call chain.)

 */


// important: all coercions should be non-lossy (lossy conversions should be implemented as handlers); there may be some bending of this rule for text<->number conversions (e.g. "3.1" -> 3.1 -> "3.1", though always "foo" -> error), but promoting a value from simpler to more complex coercion (e.g. "foo" as list -> ["foo"]) should not be reversible by coercion (since accepting an arbitrary-length list would fail if there's <>1 item in it, and requiring a 1-item list is just silly)

// TO DO: what about canonical vs localized representations of numbers and dates? (one option is for `number` and `date` coercions to accept optional country code/time zone/format/etc, although that may not work so well; explicit converters would be safer; custom contexts (e.g. 'using US_dates {…}') that convert to/from canonical representations automatically might be more convenient)

// TO DO: what about first-class quantities, e.g. `3mm`, `1.5kg`? (as with scalars, pinch Numeric [rename Quantity] implementation from entoli; main reason for this would be to refine that implementation before plugging back into entoli)


// TO DO: coercions should implement call() method, allowing standard coercion values exposed as standard in stdlib (`list`, `text`, `any`, etc) to be specialized (e.g. `list (text)` would invoke AsList instance's call() method with an AsText instance as argument, returning an `AsList(AsText())` instance)

// TO DO: coercions should implement toCommand, returning Command for constructing a coercion natively (this command can also be used for `description`)

// TO DO: bridging coercions should implement intersect() method, allowing two coercions to be merged into one; this will ensure output values are only coerced/unboxed once (or an error thrown if `C1 ∩ C2 = ∅`) [caveat any debates about which environment[s] to use when performing that grand unified expansion, although the coercions should be able to figure that out for themselves, performing non-merged coercions in multiple steps with captured envs]


// TO DO: Coercions should implement HandlerProtocol so runtime can create constrained coercions from stdlib's standard Coercion instances, e.g. `list(text(nonEmpty:true),min:1,max:10)`; note that all constraint parameters are [almost] always optional (where there are exceptions, e.g. `multichoice` [asEnum], some fudging may be required)

// TO DO: implement Swift initializers for instantiating constrained coercions in bridging code, e.g. `AsList(AsText(nonEmpty:true),min:1,max:10)`

// TO DO: how would 'AsPipe(TYPE)' work? (this should work across *nix pipes, coroutines/generators, SAX readers, and anything else that resembles streaming data)

// TO DO: how practical to support `COLLECTION_TYPE of TYPE`, e.g. `list of text` as synonym for `list (text)`? (probably risky, as it conflicts with `TYPE of MODULE` usage)

// TO DO: allow complex type specs to be expressed template-style where context makes it unambiguous (e.g. RH `as` operand), e.g. `[string]`, `[#foo:integer, #bar:date]`, `any item of [number,string,date]`

// Q. if coercions support constructor call chaining, each time returning a more specialized copy of self, e.g. `list(max_length:10)(of_type:text)`, `list(anything) -> list(anything,max_length:10) -> list(of_type:text,max_length:10)`, could this approach be generalized for intersecting coercions as well, e.g. `list(text) ∩ list(number(min:0),max_length:10)`? (this'd go a long way to streamlining how return values are coerced [currently 2 coercions are performed; first to the handler's return type, then to the caller's input type])


typealias Coercion = Value & CoercionProtocol

typealias BridgingCoercion = Value & CoercionProtocol & BridgingProtocol

typealias CallableCoercion = Coercion & HandlerProtocol



protocol CoercionProtocol { // all Coercions are Value subclass, allowing them to be used directly in language
    
    // coercion name as it appears in native language; this is used as env slot name (see stdlib_coercions.swift), so should be a native identifier
    var coercionName: String { get } // caution: used in Environment.add() without automatically normalizing (see below), so for now must be all-lowercase
    
    // all concrete Coercion subclasses must implement coerce() method for use in native language (e.g. `someValue as text`)
    func coerce(value: Value, env: Scope) throws -> Value
}

extension CoercionProtocol {
    var key: String { return self.coercionName }
}

extension CoercionProtocol where Self: HandlerProtocol { // Coercion and Handler extensions implement conflicting `key` vars, so disambiguate it here
    var key: String { return self.coercionName }
}



// bridging coercions convert native values to/from Swift equivalents when calling primitive library functions

protocol BridgingProtocol {
    
    // provides additional box()/unbox() methods used by bridging glue code
    
    // (BridgingCoercion is implemented as a protocol on top of Coercion, not as a generic subclass of Coercion, as generic subclasses quickly become incomprehensible)
    
    // TO DO: var swiftName: String {get}? or just auto-generate from class name? (need to figure out how `primitive(TYPE)` modifier should work in FFI signatures)
    
    associatedtype SwiftType // this is either a Swift coercion (e.g. Bool, Int, Array<String>) or a Value [sub]class
    
    func unbox(value: Value, env: Scope) throws -> SwiftType
    
    func box(value: SwiftType, env: Scope) throws -> Value
    
    func unboxArgument(_ paramKey: String, in arguments: inout [Argument], commandEnv: Scope, command: Command, handler: Handler) throws -> SwiftType
    
    // TO DO: bridging coercions that perform constraint checks need ability to emit raw Swift code for performing those checks in order to compile away unnecessary coercions, e.g. given native code `bar(foo())`, if foo() returns a boxed Swift String and bar() unboxes it again, partial compilation can discard those Coercions and generate `LIB.bar(LIB.foo())` Swift code
}


extension BridgingProtocol {
    
    func unboxArgument(_ paramKey: String, in arguments: inout [Argument], commandEnv: Scope, command: Command, handler: Handler) throws -> SwiftType {
        //print("Unboxing argument \(paramKey)")
        let value = removeArgument(paramKey, from: &arguments) ?? noValue
        do {
            return try self.unbox(value: value, env: commandEnv)// TO DO: should use bridgingEval…
            //return try value.bridgingEval(env: Scope, coercion: self) // TO DO: …except this doesn't work as bridgingEval<T>() can't be inferred
        } catch {
            //print("Unboxing argument \(paramKey) failed:",error)
            throw BadArgumentError(paramKey: paramKey, argument: value, command: command, handler: handler).from(error)
        }
    }
}


extension BridgingProtocol where SwiftType: Value {
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


extension BridgingProtocol where SwiftType == Coercion {
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}

