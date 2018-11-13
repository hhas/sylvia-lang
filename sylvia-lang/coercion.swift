//
//  coercion.swift
//

// important: all coercions should be non-lossy (lossy conversions should be implemented as handlers); there may be some bending of this rule for text<->number conversions (e.g. "3.1" -> 3.1 -> "3.1", though always "foo" -> error), but promoting a value from simpler to more complex type (e.g. "foo" as list -> ["foo"]) should not be reversible by coercion (since accepting an arbitrary-length list would fail if there's <>1 item in it, and requiring a 1-item list is just silly)

// TO DO: what about canonical vs localized representations of numbers and dates? (one option is for `number` and `date` coercions to accept optional country code/time zone/format/etc, although that may not work so well; explicit converters would be safer; custom contexts (e.g. 'using US_dates {…}') that convert to/from canonical representations automatically might be more convenient)

// TO DO: what about first-class quantities, e.g. `3mm`, `1.5kg`? (as with scalars, pinch Numeric [rename Quantity] implementation from entoli; main reason for this would be to refine that implementation before plugging back into entoli)


// TO DO: coercions should implement call() method, allowing standard coercion values exposed as standard in stdlib (`list`, `text`, `any`, etc) to be specialized (e.g. `list (text)` would invoke AsList instance's call() method with an AsText instance as argument, returning an `AsList(AsText())` instance)

// TO DO: bridging coercions should implement intersect() method, allowing two coercions to be merged into one; this will ensure output values are only coerced/unboxed once (or an error thrown if `C1 ∩ C2 = ∅`) [caveat any debates about which environment[s] to use when performing that grand unified expansion, although the coercions should be able to figure that out for themselves, performing non-merged coercions in multiple steps with captured envs]


// TO DO: Coercions should implement Callable so runtime can create constrained coercions from stdlib's standard Coercion instances, e.g. `list(text(nonEmpty:true),min:1,max:10)`; note that all constraint parameters are [almost] always optional (where there are exceptions, e.g. `multichoice` [asEnum], some fudging may be required)

// TO DO: implement Swift initializers for instantiating constrained coercions in bridging code, e.g. `AsList(AsText(nonEmpty:true),min:1,max:10)`


typealias BridgingCoercion = Coercion & Bridge


class Coercion: Value { // all Coercions are Value subclass, allowing them to be used directly in language // TO DO: should coercion be a protocol on top of Value, avoiding need for the following `fatalError` stubs (which are currently required by compiler due to lack of an `abstract` keyword)
    
    // all concrete Coercion subclasses must implement coerce() method for use in native language (e.g. `someValue as text`)
    
    var name: String { fatalError() }
    
    func coerce(value: Value, env: Env) throws -> Value {
        fatalError("All concrete Coercion subclasses must implement coerce(value:env:) method.")
    }
}


// bridging coercions convert native values to/from Swift equivalents when calling primitive library functions

protocol Bridge {
    
    // provides additional box()/unbox() methods used by bridging glue code
    
    // (BridgingCoercion is implemented as a protocol on top of Coercion, not as a generic subclass of Coercion, as generic subclasses quickly become incomprehensible)
    
    // TO DO: var swiftName: String {get}? or just auto-generate from class name? (need to figure out how `primitive(TYPE)` modifier should work in FFI signatures)
    
    associatedtype SwiftType // TO DO: for naming convention, use "Primitive" rather than "Swift"?
    
    func unbox(value: Value, env: Env) throws -> SwiftType
    
    func box(value: SwiftType, env: Env) throws -> Value
    
    // TO DO: bridging coercions that perform constraint checks need ability to emit raw Swift code for performing those checks in order to compile away unnecessary coercions, e.g. given native code `bar(foo())`, if foo() returns a boxed Swift String and bar() unboxes it again, partial compilation can discard those Coercions and generate `LIB.bar(LIB.foo())` Swift code
}


// concrete coercion classes

// TO DO: how best to indicate which coercions are exposed in stdlib slots, and which are only exposed in FFI_lib slots?

class AsAny: BridgingCoercion {
    
    override var name: String { return "anything" }
    
    typealias SwiftType = Value
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return try value.toAny(env: env, type: self)
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        return try value.toAny(env: env, type: self)
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        return value
    }
}


class AsString: BridgingCoercion { // Q. what about constraints?
    
    override var name: String { return "text" }
    
    typealias SwiftType = String
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return try value.toText(env: env, type: self)
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        return try value.toText(env: env, type: self).swiftValue
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        return Text(value)
    }
}


class AsDouble: BridgingCoercion {
    
    override var name: String { return "number" }
    
    typealias SwiftType = Double
    
    override func coerce(value: Value, env: Env) throws -> Value {
        let result = try value.toText(env: env, type: self)
        if Double(result.swiftValue) == nil { throw CoercionError(value: value, type: self) } // note: this only validates; it doesn't rewrite (Q. should it return `Text(String(n))`?)
        return result
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        guard let n = try Double(value.toText(env: env, type: self).swiftValue) else { throw CoercionError(value: value, type: self) }
        return n
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        return Text(String(value))
    }
}


class AsBool: BridgingCoercion {
    
    override var name: String { return "boolean" }
    
    typealias SwiftType = Bool
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return try value.toText(env: env, type: self).swiftValue != "" ? trueValue : falseValue
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        return try value.toText(env: env, type: self).swiftValue != ""
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        return value ? trueValue : falseValue
    }
}


class AsArray<ElementType: BridgingCoercion>: BridgingCoercion {
    
    override var name: String { return "list" }
    
    typealias SwiftType = [ElementType.SwiftType]
    
    let elementType: ElementType
    
    init(_ elementType: ElementType) { // TO DO: optional min/max length constraints
        self.elementType = elementType
    }
    
    override func coerce(value: Value, env: Env) throws -> Value {
        fatalError()//return try value.toList(env: env, type: AsList(self.elementType)) // TO DO: reboxing AsArray coercion as AsList is smelly; the problem is that toList() expects type:AsList (which allows it to get type.elementType); one option might be for AsArray to subclass AsList (although that may require some ugly casting to get AsList.elementType from Coercion back to ElementType for use in box/unbox)
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        return try value.toArray(env: env, type: self)
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        return try List(value.map { try self.elementType.box(value: $0, env: env) })
    }
}



// TO DO: Variant should be separate Coercion class (Q. how will Variant support Swift types? needs to use enum)


// native coercions; these may be used as bridging coercions where a Swift function works with native values

class AsText: BridgingCoercion { // Q. what about constraints? // TO DO: would be nice to share common constraint-checking code, though not sure how best to do that
    
    override var name: String { return "text" }
    
    typealias SwiftType = Text
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return try value.toText(env: env, type: self)
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType { // also add this via extension? (it'd need to cast `return self.coerce(…) as! SwiftType`, which isn't ideal)
        return try value.toText(env: env, type: self)
    }
    
    func box(value: SwiftType, env: Env) throws -> Value { // add this method automatically via `extension BridgingCoercion where SwiftType: Value {}`
        return value
    }
}


// native-only coercions // TO DO: this smells

class AsList: Coercion {
    
    override var name: String { return "list" }
    
    let elementType: Coercion
    
    init(_ elementType: Coercion) {
        self.elementType = elementType
    }
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return try value.toList(env: env, type: self)
    }
}


// coercion modifiers

class AsIs: BridgingCoercion { // the value is passed thru as-is, without evaluation; unlike AsThunk, its context (env) is not captured
    
    override var name: String { return "anything" }
    
    typealias SwiftType = Value
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return value
    }
    func unbox(value: Value, env: Env) throws -> SwiftType {
        return value
    }
    func box(value: SwiftType, env: Env) throws -> Value {
        return value
    }
}


class AsNothing: Coercion { // value is discarded; noValue is returned (used in primitive handler type sigs when handler returns no result)
    
    override var name: String { return "NULL" } // TO DO: can/should this be merged with Nothing value class, allowing `nothing` to describe both 'no value' and 'no [return] type'?
    
    typealias SwiftType = Value
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return noValue
    }
    func unbox(value: Value, env: Env) throws -> SwiftType {
        return noValue
    }
    func box(value: SwiftType, env: Env) throws -> Value {
        return noValue
    }
}


class AsLazy: Coercion { // native only; TO DO: what about bridging?
    
    override var name: String { return "lazy" }
    
    let type: Coercion
    
    init(_ type: Coercion) {
        self.type = type
    }
    
    override func coerce(value: Value, env: Env) throws -> Value {
        return Thunk(value, env: env, type: self.type)
    }
}


class AsDefault: Coercion { // native only; TO DO: what about bridging? (remember, we want to avoid primitive library developers hardcoding default values in func implementation)
    
    override var name: String { return "default" }
    
    let type: Coercion
    let defaultValue: Value
    
    init(_ type: Coercion, _ defaultValue: Value) { // TO DO: make defaultValue param optional, and provide `standardDefaultValue` var on Coercion classes? (Q. what to do for coercions that don't have meaningful defaults? would be better to use a DefaultCoercible protocol and have alternate initializer; Q. what about constraints?)
        self.type = type
        self.defaultValue = defaultValue
    }
    
    override func coerce(value: Value, env: Env) throws -> Value {
        do {
            return try self.type.coerce(value: value, env: env)
        } catch is NullCoercionError {
            return self.defaultValue
        }
    }
}


class AsOptional<T: BridgingCoercion>: BridgingCoercion {
    
    override var name: String { return "optional" }
    
    typealias SwiftType = T.SwiftType?
    
    let type: T
    
    init(_ type: T, defaultValue: Value) {
        self.type = type
    }
    
    override func coerce(value: Value, env: Env) throws -> Value {
        do {
            return try self.type.coerce(value: value, env: env)
        } catch is NullCoercionError {
            return noValue
        }
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        do {
            return try self.type.unbox(value: value, env: env)
        } catch is NullCoercionError {
            return nil
        }
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        if let v = value {
            return try self.type.box(value: v, env: env)
        } else {
            return noValue
        }
    }
}


class AsThunk<T: BridgingCoercion>: BridgingCoercion {
    
    override var name: String { return "lazy" }
    
    typealias SwiftType = T.SwiftType?
    
    let type: T
    
    init(_ type: T) {
        self.type = type
    }
    
    override func coerce(value: Value, env: Env) throws -> Value {
        fatalError() //return Thunk(value, env: env, type: self.type)
    }
    
    func unbox(value: Value, env: Env) throws -> SwiftType {
        fatalError()
    }
    
    func box(value: SwiftType, env: Env) throws -> Value {
        fatalError()
    }
}



let asAny = AsAny()
let asText = AsText()
let asBool = AsBool()
let asDouble = AsDouble()
let asString = AsString()
let asList = AsList(asAny)
let asIs = AsIs()
let asNothing = AsNothing()
