//
//  value.swift
//
//  native datatypes; these should have literal representations
//


// Q. how should pretty printer apply rich text styles, e.g. annotations should probably appear italicized; should [some user-defined] command names appear emboldened? (thinking here is that operators tend to be defined for small general operations that are very frequently performed, e.g. math); TBH, only user really knows which of their handlers are "significant" and which are supporting (and this assumes that all library-defined handlers are support); maybe auto-embolden all names defined by current package (eventually, editor might provide command line where users can specify how they want code highlighted/selected at any time, e.g. `highlight every command whose handler is_in LIBRARY`)

// TO DO: how to denote symbol literals?
//
//   item \name of [\name: "untitled", \class: \document, \edited: false] « 'backslash escape' of identifier »
//
//   item #name of [#name: "untitled", #class: #document, #edited: false] « hash prefix; looks better but precludes hashtags as first-class syntax »
//
// note that while it *might* be possible to coerce identifiers to symbols in some use cases, it is important that users should not confuse the two, e.g.:
//
//   #name of [#name: "untitled", #class: #document, #edited: false]
//
// might be acceptable as shortcut for `item #name of KV_LIST`, but:
//
//   name of [#name: "untitled", #class: #document, #edited: false]
//
// will cause confusion and should not be treated as interchangeable for the first (in this example, `name` would be resolved as attribute of the key-value list); we want to avoid AS-style ambiguity where a record or script object's standard properties, e.g. `class`, may return different results depending on whether or not they're overridden by a declared property of same name (note: this assumes no native record/struct datatype, which is probably for best if we're not using records as unary arguments c.f. entoli)
//


// TO DO: need to start thinking about public/internal/private declarations

// TO DO: what about annotating values with canonical Coercion types? (e.g. a list that is explicitly declared as `editable(list(text(nonEmpty),1,10))` could have that coercion attached to it so that all subsequent insertions/replacements/deletions to that list are constraint-checked against that coercion; ultimately, Coercion instances might even interlinked to provide generic-/dependent coercion-style capabilities; e.g. a handler that accepts a variant input `anyOf([number, date])` could guarantee that its output value will always be of the same coercion as the given input value - the output coercion receiving the Coercion object that was successfully matched by the input coercion - along with additional comparison checks, e.g. `outputValue>inputValue`, which can also be converted into mixture of compile-time and run-time checks when cross-compiling to Swift)

// TO DO: any benefit in annotating Values parsed from source code as `.literal`, `.immutable`, etc, to distinguish from Values created at runtime? (e.g. parser and/or runtime could intern or otherwise optimize literal values that they know will never be mutated)

// TO DO: assuming Value supports flexible annotating (i.e. per-value dict/struct rather than hardcoded vars), parser should attach source code range to each AST node for use in generating error messages, tracebacks, GUI editor code highlighting (c.f. OSAScriptError), etc

// TO DO: also consider supporting tuple syntax in multiple assignments, return values. (Note that `return` could be defined solely as a command, in which case the parens are mandatory there anyway, or as a prefix operator with custom parsefunc that accepts either tuple syntax or single EXPR. Likewise, an assignment operator can use a custom parsefunc to accept either `TUPLE of IDENTIFIER` or `IDENTIFIER`.) Using tuple syntax for command arguments only is wasteful and lacks symmetry (technically every command is a unary operator `f x -> y`; it just so happens that the argument type is always a tuple, but this is purely to avoid syntactic ambiguity), although we probably want to avoid arbitrary use


// abstract base class

class Value: CustomStringConvertible { // base class for all native values // Q. would it be better for Value to be a protocol + extension? (need to check how multiple extensions that implement same methods are resolved, e.g. if Value extension implements default toTYPE methods)
    
    lazy var annotations = [Int:Any]() // TO DO: what data structure?
    
    var description: String { return "«TODO: `\(type(of:self)).description`»" }
    
    // TO DO: class var typeName (canonical name, e.g. `list`), var typeName (generated from self.nominalType, e.g. `list(text,max:10)`)
    
    class var nominalType: Coercion { fatalError("Not yet implemented: \(type(of:self)).nominalType") }
    
    var nominalType: Coercion { return type(of: self).nominalType }
    
    // TO DO: implement debugDescription (this should return Swift representation whereas description should return native representation using default formatting)
    
    // TO DO: implement pretty printing API (ideally this would be a general-purpose Visitor API; Q. for rewriting, use read-only visitor API that reconstructs entire AST from scratch, or support read-write? [right now most Value classes' internal state is `let` rather than `private(set)var`])
    
    // toTYPE() methods; these are called by Coercion.bridgingEval()/nativeEval() methods to convert; they should not be called directly
    
    func toAny(env: Scope, coercion: Coercion) throws -> Value { // collection subclasses override this to recursively evaluate items
        return self
    }
    
    // concrete subclasses must override the following as appropriate
    
    func toText(env: Scope, coercion: Coercion) throws -> Text { // re. coercion parameter: Coercion is assumed to be AsText, but may be AsString or other coercion as long as its coerce() method returns Text (would be good to get this strongly typed, but need to decide inheritance hierarchy for Coercion types)
        throw CoercionError(value: self, coercion: coercion)
    }
    
    func toSymbol(env: Scope, coercion: Coercion) throws -> Symbol {
        throw CoercionError(value: self, coercion: coercion)
    }
    
    // coerce atomic values to 1-item list/array
    
    func toList(env: Scope, coercion: AsList) throws -> List {
        do {
            return try List([self.nativeEval(env: env, coercion: coercion.elementType)])
        } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
            throw CoercionError(value: self, coercion: coercion.elementType).from(error) // TO DO: more detailed error message indicating which list item couldn't be evaled
        }
    }
    
    func toArray<E, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        do {
            return try [self.bridgingEval(env: env, coercion: coercion.elementType)] //[coercion.elementType.unbox(value: self, env: env)]
        } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
            throw CoercionError(value: self, coercion: coercion.elementType).from(error) // TO DO: ditto
        }
    }
    
    // main entry points for evaluation
    
    // env -- typically global scope or stack frame, though can also be a custom scope (c.f. JavaScript objects, which are effectively heap-allocated frames in a thin API wrapper allowing them to pass through runtime along with JS primitives)
    // coercion -- specifies the return value's static/dynamic type, along with any additional runtime constraints (e.g. min/max length)
    
    func nativeEval(env: Scope, coercion: Coercion) throws -> Value { // evaluates this Value returning an "untyped" native Value; used in native runtime
        return try coercion.coerce(value: self, env: env)
    }
    
    func bridgingEval<T: BridgingCoercion>(env: Scope, coercion: T) throws -> T.SwiftType { // evaluates this Value returning a Swift primitive/known Value subclass; used in typesafe Swift code (primitive libraries, external client code)
        return try coercion.unbox(value: self, env: env)
    }
}


// concrete classes


class Nothing: Value {
    
    override var description: String { return "nothing" }
    
    override class var nominalType: Coercion { return asNoResult }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toSymbol(env: Scope, coercion: Coercion) throws -> Symbol {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toList(env: Scope, coercion: AsList) throws -> List {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toArray<E, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        throw NullCoercionError(value: self, coercion: coercion)
    }
}


class DidNothing: Nothing {
    
    override var description: String { return "did_nothing" }
    
}



class Text: Value { // TO DO: Scalar?
    
    override var description: String { return "“\(self.swiftValue)”" } // TO DO: pretty printing
    
    override class var nominalType: Coercion { return asText }
    
    internal(set) var scalar: Scalar? // TO DO: any way to make this lazily self-initialize if not set by init?
    
    // TO DO: need ability to capture raw Swift value in case of numbers, dates, etc; while this could be done in annotations, it might be quicker to have a dedicated private var containing enum of standard raw types we want to cache (.int, .double, .scalar, .date, whatever); another option is for annotations to be linked list/B-tree where entries are ordered according to predefined importance or frequency of use (would need to see how this compares to a dictionary, which should be pretty fast out of the box with interned keys)
    
    private(set) var swiftValue: String // TO DO: restricted mutability; e.g. perform appends in-place only if refcount==1, else copy self and append to that
    
    init(_ swiftValue: String, scalar: Scalar? = nil) { // TO DO: what constraints are appropriate here? e.g. nonEmpty, minLength, maxLength, pattern, etc are all possibilities; simplest from API perspective is regexp, although that's also the most complex (unless standard patterns for describing the other constraints - e.g. "."/".+"/"\A.+\Z" are common patterns for indicating 'nonEmpty:true' - are recognized and optimized away)
        self.swiftValue = swiftValue
        self.scalar = scalar
    }
    
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        return self
    }
}




extension Text {
    
    convenience init(_ scalar: Scalar)  { self.init(scalar.literalRepresentation(), scalar: scalar) }
    convenience init(_ n: Int)          { self.init(Scalar(n)) }
    convenience init(_ n: Double)       { self.init(Scalar(n)) }
    
    func toScalar() throws -> Scalar { // initializes scalar property on first use
        if let scalar = self.scalar { return scalar }
        do {
            let scalar = try Scalar(self.swiftValue)
            self.scalar = scalar
            return scalar
        } catch {
            self.scalar = .invalid(self.swiftValue) // set Text.scalar property to .invalid, which will always throw when used
            throw error
        }
    }
    func toInt() throws -> Int { return try self.toScalar().toInt() }
    func toDouble() throws -> Double { return try self.toScalar().toDouble() }
}


class Symbol: Value {
    
    override var description: String { return "\(symbolLiteralPrefix)‘\(self.swiftValue)’" }
    
    override class var nominalType: Coercion { return asSymbol }
    
    let key: String
    
    let swiftValue: String
    
    init(_ swiftValue: String) {
        self.swiftValue = swiftValue
        self.key = swiftValue.lowercased()
    }
    
    override func toSymbol(env: Scope, coercion: Coercion) throws -> Symbol {
        return self
    }
}


class List: Value { // TO DO: how best to represent ordered (Array) vs key-value (Dictionary) vs unique (Set) lists? subclasses? internal enum?
    
    override var description: String { return "\(self.swiftValue)" } // note: this assumes native `[…,…]` list syntax is same as Swift Array syntax; if that changes then use "[\(self.swiftValue.map{$0.description}.joined(separator:","))]" // TO DO: pretty printer needs to support line wrapping and indentation of long lists
    
    override class var nominalType: Coercion { return asList }
    
    private(set) var swiftValue: [Value]
    
    init(_ swiftValue: [Value]) {
        self.swiftValue = swiftValue
    }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        return try List(self.swiftValue.map {
            do {
                return try $0.nativeEval(env: env, coercion: coercion)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion).from(error)
            }
        })
    }
    
    override func toList(env: Scope, coercion: AsList) throws -> List {
        return try List(self.swiftValue.map {
            do {
                return try $0.nativeEval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors, i.e. `[nothing] as list(optional) => [nothing]`, but `[nothing] as optional => CoercionError`
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)  // TO DO: more detailed error message indicating which list item couldn't be evaled
            }
        })
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        return try self.swiftValue.map {
            do {
                return try $0.bridgingEval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)
            }
        }
    }
}


// other native values might include Boolean, Number, Date (if distinct from Text, which can easily represent these data types as text, caching any underlying representations for performance if needed, if Perl-style 'scalar' representation is preferred); Symbol (enum); Table (dict); Block, Identifier, Command, Handler, Thunk (being an Algol-style language, these latter value types aren't exposed as first-class datatypes in language, although a more Lisp-ish flavor could represent all code structures as data); downside is each new native coercion requires another `toType()` method added to Value and to each subclass that supports that coercion (though these can at least be organized into class extensions so don't clog up the main class implementations)





// convenience constants


let noValue = Nothing()
let didNothing = DidNothing()
let emptyText = Text("")
let emptyList = List([])

let trueValue = Text("ok")
let falseValue = emptyText

let piValue = Text(String(Double.pi))
