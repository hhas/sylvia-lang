//
//  value.swift
//
//  native datatypes; these should have literal representations
//


// TO DO: need to start thinking about public/internal/private declarations

// TO DO: what about annotating values with canonical Coercion types? (e.g. a list that is explicitly declared as `editable(list(text(nonEmpty),1,10))` could have that coercion attached to it so that all subsequent insertions/replacements/deletions to that list are constraint-checked against that coercion; ultimately, Coercion instances might even interlinked to provide generic-/dependent coercion-style capabilities; e.g. a handler that accepts a variant input `anyOf([number, date])` could guarantee that its output value will always be of the same coercion as the given input value - the output coercion receiving the Coercion object that was successfully matched by the input coercion - along with additional comparison checks, e.g. `outputValue>inputValue`, which can also be converted into mixture of compile-time and run-time checks when cross-compiling to Swift)

// TO DO: any benefit in annotating Values parsed from source code as `.literal`, `.immutable`, etc, to distinguish from Values created at runtime? (e.g. parser and/or runtime could intern or otherwise optimize literal values that they know will never be mutated)

// TO DO: assuming Value supports flexible annotating (i.e. per-value dict/struct rather than hardcoded vars), parser should attach source code range to each AST node for use in generating error messages, tracebacks, GUI editor code highlighting (c.f. OSAScriptError), etc


// abstract base class

class Value: CustomStringConvertible { // base class for all native values // Q. would it be better for Value to be a protocol + extension? (need to check how multiple extensions that implement same methods are resolved, e.g. if Value extension implements default toTYPE methods)
    
    lazy var annotations = [Any]() // TO DO: what data structure?
    
    var description: String { return "«TODO: `\(type(of:self)).description`»" }
    
    var nominalType: Coercion { fatalError("Not yet implemented: \(type(of:self)).nominalType") }
    
    // TO DO: implement debugDescription (this should return Swift representation whereas description should return native representation using default formatting)
    
    // TO DO: implement pretty printing API (ideally this would be a general-purpose Visitor API; Q. for rewriting, use read-only visitor API that reconstructs entire AST from scratch, or support read-write? [right now most Value classes' internal state is `let` rather than `private(set)var`])
    
    // double-dispatch methods; these are called by Coercion.swiftEval()/eval() methods; they should not be called directly
    
    func toAny(env: Env, coercion: Coercion) throws -> Value { // collection subclasses override this to recursively evaluate items
        return self
    }
    
    // concrete subclasses must override the following as appropriate
    
    func toText(env: Env, coercion: Coercion) throws -> Text { // re. coercion parameter: Coercion is assumed to be AsText, but may be AsString or other coercion as long as its coerce() method returns Text (would be good to get this strongly typed, but need to decide inheritance hierarchy for Coercion types)
        throw CoercionError(value: self, coercion: coercion)
    }
    
    // coerce atomic values to 1-item list/array
    
    func toList(env: Env, coercion: AsList) throws -> List {
        do {
            return try List([self.eval(env: env, coercion: coercion.elementType)])
        } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
            throw CoercionError(value: self, coercion: coercion.elementType).from(error) // TO DO: more detailed error message indicating which list item couldn't be evaled
        }
    }
    
    func toArray<E, T: AsArray<E>>(env: Env, coercion: T) throws -> T.SwiftType {
        do {
            return try [self.swiftEval(env: env, coercion: coercion.elementType)] //[coercion.elementType.unbox(value: self, env: env)]
        } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
            throw CoercionError(value: self, coercion: coercion.elementType).from(error) // TO DO: ditto
        }
    }
    
    // main entry points for native/bridging evaluation
    
    func eval(env: Env, coercion: Coercion) throws -> Value {
        return try coercion.coerce(value: self, env: env)
    }
    
    func swiftEval<T: BridgingCoercion>(env: Env, coercion: T) throws -> T.SwiftType {
        return try coercion.unbox(value: self, env: env)
    }
}


// concrete classes


class Nothing: Value {
    
    override var description: String { return "nothing" }
    
    override var nominalType: Coercion { return asNoResult }
    
    override func toAny(env: Env, coercion: Coercion) throws -> Value {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toText(env: Env, coercion: Coercion) throws -> Text {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toList(env: Env, coercion: AsList) throws -> List {
        throw NullCoercionError(value: self, coercion: coercion)
    }
    override func toArray<E, T: AsArray<E>>(env: Env, coercion: T) throws -> T.SwiftType {
        throw NullCoercionError(value: self, coercion: coercion)
    }
}


class DidNothing: Nothing {
    
    override var description: String { return "didNothing" }
    
}



class Text: Value { // TO DO: Scalar?
    
    override var description: String { return "“\(self.swiftValue)”" } // TO DO: pretty printing
    
    override var nominalType: Coercion { return asText }
    
    // TO DO: need ability to capture raw Swift value in case of numbers, dates, etc; while this could be done in annotations, it might be quicker to have a dedicated private var containing enum of standard raw types we want to cache (.int, .double, .scalar, .date, whatever); another option is for annotations to be linked list/B-tree where entries are ordered according to predefined importance or frequency of use (would need to see how this compares to a dictionary, which should be pretty fast out of the box with interned keys)
    
    private(set) var swiftValue: String // TO DO: restricted mutability; e.g. perform appends in-place only if refcount==1, else copy self and append to that
    
    init(_ swiftValue: String) { // TO DO: what constraints are appropriate here? e.g. nonEmpty, minLength, maxLength, pattern, etc are all possibilities; simplest from API perspective is regexp, although that's also the most complex (unless standard patterns for describing the other constraints - e.g. "."/".+"/"\A.+\Z" are common patterns for indicating 'nonEmpty:true' - are recognized and optimized away)
        self.swiftValue = swiftValue
    }
    
    override func toText(env: Env, coercion: Coercion) throws -> Text {
        return self
    }
}


class List: Value {
    
    override var description: String { return "\(self.swiftValue)" }
    
    override var nominalType: Coercion { return asList }
    
    private(set) var swiftValue: [Value]
    
    init(_ swiftValue: [Value]) {
        self.swiftValue = swiftValue
    }
    
    override func toAny(env: Env, coercion: Coercion) throws -> Value {
        return try List(self.swiftValue.map {
            do {
                return try $0.eval(env: env, coercion: coercion)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                throw CoercionError(value: $0, coercion: coercion).from(error)
            }
        })
    }
    
    override func toList(env: Env, coercion: AsList) throws -> List {
        return try List(self.swiftValue.map {
            do {
                return try $0.eval(env: env, coercion: coercion.elementType)
            } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors, i.e. `[nothing] as list(optional) => [nothing]`, but `[nothing] as optional => CoercionError`
                throw CoercionError(value: $0, coercion: coercion.elementType).from(error)  // TO DO: more detailed error message indicating which list item couldn't be evaled
            }
        })
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Env, coercion: T) throws -> T.SwiftType {
        return try self.swiftValue.map {
            do {
                return try $0.swiftEval(env: env, coercion: coercion.elementType)
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
