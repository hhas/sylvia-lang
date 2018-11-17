//
//  value.swift
//
//  native datatypes; these should have literal representations
//


// TO DO: need to start thinking about public/internal/private declarations

// TO DO: what about annotating values with canonical Coercion types? (e.g. a list that is explicitly declared as `editable(list(text(nonEmpty),1,10))` could have that coercion attached to it so that all subsequent insertions/replacements/deletions to that list are constraint-checked against that coercion; ultimately, Coercion instances might even interlinked to provide generic-/dependent type-style capabilities; e.g. a handler that accepts a variant input `anyOf([number, date])` could guarantee that its output value will always be of the same type as the given input value - the output coercion receiving the Coercion object that was successfully matched by the input coercion - along with additional comparison checks, e.g. `outputValue>inputValue`, which can also be converted into mixture of compile-time and run-time checks when cross-compiling to Swift)

// TO DO: any benefit in annotating Values parsed from source code as `.literal`, `.immutable`, etc, to distinguish from Values created at runtime? (e.g. parser and/or runtime could intern or otherwise optimize literal values that they know will never be mutated)


// abstract base class

class Value: CustomStringConvertible { // base class for all native values // Q. would it be better for Value to be a protocol + extension? (need to check how multiple extensions that implement same methods are resolved, e.g. if Value extension implements default toTYPE methods)
    
    var description: String { return "<Value>" }
    
    // TO DO: implement debugDescription (this should return Swift representation whereas description should return native representation using default formatting)
    
    // TO DO: implement pretty printing API (ideally this would be a general-purpose Visitor API; Q. for rewriting, use read-only visitor API that reconstructs entire AST from scratch, or support read-write? [right now most Value classes' internal state is `let` rather than `private(set)var`])
    
    // double-dispatch methods; these are called by Coercion.evaluate()/run() methods; they should not be called directly
    
    func toAny(env: Env, type: Coercion) throws -> Value { // collection subclasses override this to recursively evaluate items
        return self
    }
    
    // concrete subclasses must override the following as appropriate
    
    func toText(env: Env, type: Coercion) throws -> Text { // re. type parameter: Coercion is assumed to be AsText, but may be AsString or other type as long as its coerce() method returns Text (would be good to get this strongly typed, but need to decide inheritance hierarchy for Coercion types)
        throw CoercionError(value: self, type: type)
    }
    
    // List subclass overrides the following; other values coerce to single-item list/array (V->[V]):
    
    func toList(env: Env, type: AsList) throws -> List {
        return try List([type.elementType.coerce(value: self, env: env)]) // TO DO: catch NullCoercionError and rethow as permanent CoercionError
    }
    
    func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try [type.elementType.unbox(value: self, env: env)] // TO DO: ditto
    }
}


// concrete classes


class Nothing: Value {
    
    override var description: String { return "nothing" }
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        throw NullCoercionError(value: self, type: type)
    }
    override func toText(env: Env, type: Coercion) throws -> Text {
        throw NullCoercionError(value: self, type: type)
    }
    override func toList(env: Env, type: AsList) throws -> List {
        throw NullCoercionError(value: self, type: type)
    }
    override func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        throw NullCoercionError(value: self, type: type)
    }
}



class Text: Value { // TO DO: Scalar?
    
    override var description: String { return "“\(self.swiftValue)”" } // TO DO: pretty printing
    
    private(set) var swiftValue: String // TO DO: restricted mutability; e.g. perform appends in-place only if refcount==1, else copy self and append to that
    
    init(_ swiftValue: String) { // TO DO: what constraints are appropriate here? e.g. nonEmpty, minLength, maxLength, pattern, etc are all possibilities; simplest from API perspective is regexp, although that's also the most complex (unless standard patterns for describing the other constraints - e.g. "."/".+"/"\A.+\Z" are common patterns for indicating 'nonEmpty:true' - are recognized and optimized away)
        self.swiftValue = swiftValue
    }
    
    override func toText(env: Env, type: Coercion) throws -> Text {
        return self
    }
}


class List: Value {
    
    override var description: String { return "\(self.swiftValue)" }
    
    private(set) var swiftValue: [Value]
    
    init(_ swiftValue: [Value]) {
        self.swiftValue = swiftValue
    }
    
    override func toList(env: Env, type: AsList) throws -> List {
        return try List(self.swiftValue.map { try type.elementType.coerce(value: $0, env: env) })
    }
    
    override func toArray<E, T: AsArray<E>>(env: Env, type: T) throws -> T.SwiftType {
        return try self.swiftValue.map { try type.elementType.unbox(value: $0, env: env) } // TO DO: block needs to catch and rethrow NullCoercionError as permanent CoercionError (e.g.. `[nothing]->list(optional(anything))` should return `[nothing]`, but `[nothing]->optional(list(anything))` needs to throw CoercionError, not return `nothing`)
    }
    
    override func toAny(env: Env, type: Coercion) throws -> Value {
        return try List(self.swiftValue.map { try type.coerce(value: $0, env: env) }) // TO DO: ditto
    }
}


// other native values might include Boolean, Number, Date (if distinct from Text, which can easily represent these data types as text, caching any underlying representations for performance if needed, if Perl-style 'scalar' representation is preferred); Symbol (enum); Table (dict); Block, Identifier, Command, Handler, Thunk (being an Algol-style language, these latter value types aren't exposed as first-class datatypes in language, although a more Lisp-ish flavor could represent all code structures as data); downside is each new native type requires another `toType()` method added to Value and to each subclass that supports that coercion (though these can at least be organized into class extensions so don't clog up the main class implementations)





// convenience constants


let noValue = Nothing()
let emptyText = Text("")
let emptyList = List([])

let trueValue = Text("ok")
let falseValue = emptyText

let piValue = Text(String(Double.pi))
