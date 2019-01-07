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


// TO DO: Coercions should implement Callable so runtime can create constrained coercions from stdlib's standard Coercion instances, e.g. `list(text(nonEmpty:true),min:1,max:10)`; note that all constraint parameters are [almost] always optional (where there are exceptions, e.g. `multichoice` [asEnum], some fudging may be required)

// TO DO: implement Swift initializers for instantiating constrained coercions in bridging code, e.g. `AsList(AsText(nonEmpty:true),min:1,max:10)`

// TO DO: how would 'AsPipe(TYPE)' work? (this should work across *nix pipes, coroutines/generators, SAX readers, and anything else that resembles streaming data)


typealias Coercion = Value & CoercionProtocol // TO DO: rename `Constraint`?

typealias BridgingCoercion = Value & CoercionProtocol & BridgingProtocol


protocol CoercionProtocol { // all Coercions are Value subclass, allowing them to be used directly in language
    
    // coercion name as it appears in native language; this is used as env slot name (see stdlib_coercions.swift), so should be a native identifier
    var coercionName: String { get } // caution: used in Env.add() without automatically normalizing (see below), so for now must be all-lowercase
    
    // all concrete Coercion subclasses must implement coerce() method for use in native language (e.g. `someValue as text`)
    func coerce(value: Value, env: Scope) throws -> Value
}

extension CoercionProtocol {
    
    var normalizedName: String { return self.coercionName }
    
}


// bridging coercions convert native values to/from Swift equivalents when calling primitive library functions

protocol BridgingProtocol {
    
    // provides additional box()/unbox() methods used by bridging glue code
    
    // (BridgingCoercion is implemented as a protocol on top of Coercion, not as a generic subclass of Coercion, as generic subclasses quickly become incomprehensible)
    
    // TO DO: var swiftName: String {get}? or just auto-generate from class name? (need to figure out how `primitive(TYPE)` modifier should work in FFI signatures)
    
    associatedtype SwiftType // this is either a Swift coercion (e.g. Bool, Int, Array<String>) or a Value [sub]class
    
    func unbox(value: Value, env: Scope) throws -> SwiftType
    
    func box(value: SwiftType, env: Scope) throws -> Value
    
    func unboxArgument(at index: Int, command: Command, commandEnv: Scope, handler: CallableValue) throws -> SwiftType
    
    // TO DO: bridging coercions that perform constraint checks need ability to emit raw Swift code for performing those checks in order to compile away unnecessary coercions, e.g. given native code `bar(foo())`, if foo() returns a boxed Swift String and bar() unboxes it again, partial compilation can discard those Coercions and generate `LIB.bar(LIB.foo())` Swift code
}

extension BridgingProtocol {
    
    func unboxArgument(at index: Int, command: Command, commandEnv: Scope, handler: CallableValue) throws -> SwiftType {
        //print("Unboxing argument \(index)")
        do {
            return try self.unbox(value: command.argument(index), env: commandEnv)// TO DO: should use bridgingEval
            //return try command.argument(index).bridgingEval(env: Scope, coercion: self) // TO DO: …except this doesn't work as bridgingEval<T>() can't be inferred
        } catch {
            //print("Unboxing argument \(index) failed:",error)
            throw BadArgumentError(command: command, handler: handler, index: index).from(error)
        }
    }
}


/******************************************************************************/
// concrete coercion classes

// TO DO: how best to indicate which coercions are exposed in stdlib slots, and which are only exposed in FFI_lib slots? (thinking that `primitive()` modifier should provide access to all BridgingCoercions, including those that are solely for boxing/unboxing specialized Swift types - asFloat, asUInt, asInt64, etc - whereas stdlib would expose only those that make sense to language users - e.g. asText, asNumber, asInteger, etc - and have obvious Swift equivalents)

// Q. how to bridge Swift enum, tuple types? (tuple BridgingCoercions might be implemented as generics, where implementor supplies their own box/unbox functions to init(); enum coercion constructor might take an array/dict of (STRING,CASE) pairs and build runtime mapping tables from that)



class AsValue: BridgingCoercion { // any value *except* `nothing`
    
    var coercionName: String { return "value" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toAny(env: env, coercion: self)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toAny(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


class AsString: BridgingCoercion { // Q. what about constraints?
    
    var coercionName: String { return "text" }
    
    override var description: String { return self.coercionName } // TO DO: all coercion descriptions should be coercionName + any constraints (probably simplest to implement Callable and asCommand() first, then generate description string from Command)
    
    typealias SwiftType = String
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toText(env: env, coercion: self)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toText(env: env, coercion: self).swiftValue
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(value)
    }
}


class AsScalar: BridgingCoercion {
    
    var coercionName: String { return "number" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Scalar
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let result = try value.toText(env: env, coercion: self)
        let _ = try result.toScalar()
        return result
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toText(env: env, coercion: self).toScalar()
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(value.literalRepresentation(), scalar: value)
    }
}


class AsInt: BridgingCoercion {
    
    var coercionName: String { return "whole_number" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Int
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let result = try value.toText(env: env, coercion: self)
        if Int(result.swiftValue) == nil { throw CoercionError(value: value, coercion: self) } // note: this only validates; it doesn't rewrite (Q. should it return `Text(String(n))`?)
        return result
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let n = try Int(value.toText(env: env, coercion: self).swiftValue) else { throw CoercionError(value: value, coercion: self) }
        return n
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(String(value))
    }
}


class AsDouble: BridgingCoercion {
    
    var coercionName: String { return "number" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Double
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let result = try value.toText(env: env, coercion: self)
        do {
            let _ = try result.toScalar().toDouble()
        } catch {
            throw CoercionError(value: value, coercion: self)
        }
        // TO DO: implement `Value.toScalar()` method? or do all text-to-number/date/whatever conversion work in Coercion methods (Q. what about quantities, dates, URLs, and other data nominally represented as text?)
//        guard let number = Double(result.swiftValue) else {  } // note: this only validates; it doesn't rewrite (Q. should it return `Text(String(n))`?)
        return result
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        //guard let n = try Double(value.toText(env: env, coercion: self).swiftValue) else { throw CoercionError(value: value, coercion: self) }
        let result = try value.toText(env: env, coercion: self)
        let n: Double
        do {
            n = try result.toScalar().toDouble()
        } catch {
            throw CoercionError(value: value, coercion: self)
        }
        return n
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return Text(String(value), scalar: Scalar(value))
    }
}


class AsBool: BridgingCoercion {
    
    var coercionName: String { return "boolean" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Bool
    
    // TO DO: implement `Value.toBool()` and use that (right now this implementation only accepts text/nothing and errors on lists)
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try value.toText(env: env, coercion: self).swiftValue != "" ? trueValue : falseValue
        } catch is NullCoercionError {
            return falseValue
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try value.toText(env: env, coercion: self).swiftValue != ""
        } catch is NullCoercionError {
            return false
        }
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value ? trueValue : falseValue
    }
}


class AsArray<ElementCoercion: BridgingCoercion>: BridgingCoercion {
    
    var coercionName: String { return "list" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }
    
    typealias SwiftType = [ElementCoercion.SwiftType]
    
    let elementType: ElementCoercion
    
    init(_ elementType: ElementCoercion) { // TO DO: optional min/max length constraints
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        fatalError()//return try value.toList(env: env, coercion: AsList(self.elementType)) // TO DO: reboxing AsArray coercion as AsList is smelly; the problem is that toList() expects coercion:AsList (which allows it to get coercion.elementType); one option might be for AsArray to subclass AsList (although that may require some ugly casting to get AsList.elementType from Coercion back to ElementCoercion for use in box/unbox)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toArray(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return try List(value.map { try self.elementType.box(value: $0, env: env) })
    }
}



// TO DO: Variant should be separate Coercion class (Q. how will Variant support Swift types? needs to use enum)


// native coercions; these may be used as bridging coercions where a Swift function works with native values

class AsText: BridgingCoercion { // Q. what about constraints? // TO DO: would be nice to share common constraint-checking code, though not sure how best to do that
    
    var coercionName: String { return "text" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Text
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toText(env: env, coercion: self)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType { // also add this via extension? (it'd need to cast `return self.coerce(…) as! SwiftType`, which isn't ideal)
        return try value.toText(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value { // add this method automatically via `extension BridgingCoercion where SwiftType: Value {}`
        return value
    }
}


class AsSymbol: BridgingCoercion {
    
    var coercionName: String { return "symbol" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Symbol
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toSymbol(env: env, coercion: self)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try value.toSymbol(env: env, coercion: self)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


// native-only coercions // TO DO: this smells

class AsList: Coercion {
    
    var coercionName: String { return "list" }
    
    override var description: String { return "\(self.coercionName)(\(self.elementType))" }
    
    let elementType: Coercion
    
    init(_ elementType: Coercion) {
        self.elementType = elementType
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toList(env: env, coercion: self)
    }
}


/******************************************************************************/
// coercion modifiers

// optionals


class AsDefault: Coercion, Callable {
    
    let signature = (
        paramType_0: asAnything,
        paramType_1: asCoercion,
        returnType: asIs
    )
    
    lazy private(set) var interface = CallableInterface(
        name: self.coercionName,
        parameters: [
            ("value", signature.paramType_0),
            ("of_type", signature.paramType_1)
        ],
        returnType: asCoercion)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let defaultValue = try self.signature.paramType_0.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        let ofType = try self.signature.paramType_1.unboxArgument(at: 1, command: command, commandEnv: commandEnv, handler: self)
        if command.arguments.count > 2 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return AsDefault(ofType, defaultValue)
    }
    
    // native only; TO DO: what about bridging? (remember, we want to avoid primitive library developers hardcoding default values in func implementation)
    
    var coercionName: String { return "default" }
    
    var normalizedName: String { return self.interface.normalizedName } // TO DO: currently need this as both Callable and Coercion implement `normalizedName` via extensions
    
    override var description: String { return "\(self.coercionName)(\(self.defaultValue), \(self.coercion))" }
    
    let coercion: Coercion
    let defaultValue: Value
    
    init(_ coercion: Coercion, _ defaultValue: Value) { // TO DO: make defaultValue param optional, and provide `standardDefaultValue` var on Coercion classes? (Q. what to do for coercions that don't have meaningful defaults? would be better to use a DefaultCoercible protocol and have alternate initializer; Q. what about constraints?)
        self.coercion = coercion
        self.defaultValue = defaultValue
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch is NullCoercionError {
            return self.defaultValue
        }
    }
}


class AsOptionalValue: BridgingCoercion { // native optional
    
    var coercionName: String { return "optional" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    typealias SwiftType = Value
    
    let coercion: Coercion
    
    init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch let error as NullCoercionError {
            return error.value
        } catch {
            //print("\(self) caught error: \(error)")
            throw error
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch is NullCoercionError {
            return noValue
        }
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


class AsOptional<T: BridgingCoercion>: BridgingCoercion { // Swift `Optional` enum; `nothing` → `Optional<T>.none`
    
    var coercionName: String { return "optional" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    typealias SwiftType = T.SwiftType?
    
    let coercion: T
    
    init(_ coercion: T) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try self.coercion.coerce(value: value, env: env)
        } catch let error as NullCoercionError {
            return error.value
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        do {
            return try self.coercion.unbox(value: value, env: env)
        } catch is NullCoercionError {
            return nil
        }
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        if let v = value {
            return try self.coercion.box(value: v, env: env)
        } else {
            return noValue
        }
    }
}


// TO DO: AsVariant, AsPrecis

// lazy evaluation

class AsThunk<T: BridgingCoercion>: BridgingCoercion {
    
    var coercionName: String { return "lazy" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    typealias SwiftType = Thunk
    
    let coercion: T
    
    init(_ coercion: T) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return Thunk(value, env: env, coercion: self.coercion)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return Thunk(value, env: env, coercion: self.coercion)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


class AsLazy: Coercion { // native only; TO DO: what about bridging?
    
    var coercionName: String { return "lazy" }
    
    override var description: String { return "\(self.coercionName)(\(self.coercion))" }
    
    let coercion: Coercion
    
    init(_ coercion: Coercion) {
        self.coercion = coercion
    }
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return Thunk(value, env: env, coercion: self.coercion)
    }
}


class AsIs: BridgingCoercion { // the value is passed thru as-is, without evaluation; unlike AsThunk, its context (env) is not captured
    
    var coercionName: String { return "optional" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    // TO DO: take coercion for display purposes?
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return value
    }
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return value
    }
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}

class AsAnything: BridgingCoercion { // any value including `nothing`; used to evaluate expressions
    
    var coercionName: String { return "anything" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func coerce(value: Value, env: Scope) throws -> Value {
        do {
            return try value.toAny(env: env, coercion: self)
        } catch let error as NullCoercionError {
            return error.value // TO DO: how far should `didNothing` result propagate before being converted to `nothing`/permanent coercion error? it probably shouldn't go beyond an immediate `else` clause, e.g. `(if x action) else (y)` but not `(moreStuff(if x action)) else (y)`; might need to define an additional return type for handlers that can return `didNothing`, and have AsAnything/AsOptional catch and return noValue
        }
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        return try self.coerce(value: value, env: env)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}

//

class AsIdentifier: BridgingCoercion { // the Identifier is passed thru as-is, without evaluation, or an error thrown if wrong type
    
    var coercionName: String { return "identifier" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Identifier
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let result = value as? Identifier else { throw CoercionError(value: value, coercion: self) }
        return result
    }
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}

/******************************************************************************/
// defining handler signatures


class AsParameter: BridgingCoercion {
    
    var coercionName: String { return "parameter" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Parameter
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try value.toAny(env: env, coercion: self) // TO DO: FIX
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        let fields: [Value]
        if let list = value as? List { fields = list.swiftValue } else { fields = [value] } // kludge; we don't want to expand Identifier
        let coercion: Coercion
        switch fields.count {
        case 1: // name only
            coercion = asValue // any value except `nothing` (as that is used for optional params)
        case 2: // name + coercion
            coercion = try asCoercion.unbox(value: fields[1], env: env)
        default:
            throw CoercionError(value: value, coercion: self)
        }
        guard let name = (fields[0] as? Text)?.swiftValue else { throw CoercionError(value: value, coercion: self) }
        return (name: name, coercion: coercion)
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return List([Text(value.name), value.coercion])
    }
}


class AsCoercion: BridgingCoercion {
    
    var coercionName: String { return "coercion" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Coercion
    
    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        guard let result = try value.toAny(env: env, coercion: self) as? Coercion else { throw CoercionError(value: value, coercion: self) }
        return result
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


class AsNoResult: Coercion { // value is discarded; noValue is returned (used in primitive handler coercion sigs when handler returns no result)
    
    var coercionName: String { return "no_result" } // TO DO: can/should this be merged with Nothing value class, allowing `nothing` to describe both 'no value' and 'no [return] coercion'? (A. this would be problematic, as `defineHandler`'s `returnType` parameter should be able to distinguish omitted argument [indicating it should use `asValue`] from 'returns nothing')
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func coerce(value: Value, env: Scope) throws -> Value {
        let _ = try asAnything.coerce(value: value, env: env)
        return noValue
    }
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        let _ = try asAnything.coerce(value: value, env: env)
        return noValue
    }
    func box(value: SwiftType, env: Scope) throws -> Value {
        return noValue
    }
}


/******************************************************************************/
// value attributes

class AsAttributedValue: BridgingCoercion { // a value that implements the `get()` (slot lookup) protocol
    
    var coercionName: String { return "attributed_value" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value
    
    func coerce(value: Value, env: Scope) throws -> Value {
        if !(value is AttributedValue) { throw CoercionError(value: value, coercion: self) }
        return value
    }
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        if !(value is AttributedValue) { throw CoercionError(value: value, coercion: self) }
        return value
    }
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}



class AsAttribute: BridgingCoercion { // an identifier/command (i.e. a value whose name can be used in get() protocol)
    
    var coercionName: String { return "attribute" }
    
    override var description: String { return self.coercionName }
    
    typealias SwiftType = Value

    func coerce(value: Value, env: Scope) throws -> Value {
        return try self.unbox(value: value, env: env)
    }
    
    func unbox(value: Value, env: Scope) throws -> SwiftType {
        switch value {
        case is Identifier, is Command:
            return value
        case is Symbol: // also accept Symbol as shorthand, e.g. `#FOO of KV_LIST` is converted to `item #FOO of KV_LIST`
            return Command("item", [value])
        default:
            throw CoercionError(value: value, coercion: self)
        }
    }
    
    func box(value: SwiftType, env: Scope) throws -> Value {
        return value
    }
}


/******************************************************************************/
// convenience constants; use these when no additional constraints are needed

// basic evaluation

let asValue = AsValue() // any value except `nothing`; this is the default parameter coercion for native handlers

let asAnything = AsAnything() // any value or `nothing`; this is the default return coercion for native handlers and may be used to expand any value, including [nested] lists containing `nothing`, e.g. `[1,nothing] as optional(value) -> CoercionError`, whereas `[1,nothing] as anything -> [1,nothing]`


let asText = AsText()
let asSymbol = AsSymbol()
let asBool = AsBool()
let asScalar = AsScalar()
let asInt = AsInt()
let asDouble = AsDouble()
let asString = AsString()
let asList = AsList(asValue)


// lazy evaluation

let asThunk = AsThunk(asAnything) // native handlers may use this to declare lazily evaluated parameters


// handler signatures

let asParameter = AsParameter()
let asCoercion = AsCoercion()

let asIs = AsIs() // supplied value is returned as-is, without expanding or thunking it; used in primitive handlers to take lazily-evaluated arguments that will be evaluated using the supplied `commandEnv` (primitive handlers should only need to thunk values that will be evaluated after the handler is returned)

let asIdentifier = AsIdentifier()

let asBlock = asIs // primitive handlers don't really care if an argument is a block or an expression (to/if/repeat/etc operators should check for block syntax themselves), so for now just pass it to the handler body as-is (there's no need to thunk it either, unless the supplied block/expression needs to be retained beyond the handler call in which case it must be captured with the command scope, either by declaring the parameter coercion asThunk or by calling asThunk.coerce in the handler body)

let asNoResult = AsNoResult() // expands value to anything, ignoring any result, and always returns `nothing`; used as a handler's return type when no result is given/required


// references

let asAttributedValue = AsAttributedValue()
let asAttribute = AsAttribute()
