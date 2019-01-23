//
//  value.swift
//
//  native datatypes; these should have literal representations
//

// TO DO: aelib requires native Boolean datatype in order to bridge reliably



// Q. how should pretty printer apply rich text styles, e.g. annotations should probably appear italicized; should [some user-defined] command names appear emboldened? (thinking here is that operators tend to be defined for small general operations that are very frequently performed, e.g. math); TBH, only user really knows which of their handlers are "significant" and which are supporting (and this assumes that all library-defined handlers are support); maybe auto-embolden all names defined by current package (eventually, editor might provide command line where users can specify how they want code highlighted/selected at any time, e.g. `highlight every command whose handler is_in LIBRARY`)




// TO DO: need to start thinking about public/internal/private declarations

// TO DO: what about annotating values with canonical Coercion types? (e.g. a list that is explicitly declared as `editable(list(text(nonEmpty),1,10))` could have that coercion attached to it so that all subsequent insertions/replacements/deletions to that list are constraint-checked against that coercion; ultimately, Coercion instances might even interlinked to provide generic-/dependent coercion-style capabilities; e.g. a handler that accepts a variant input `anyOf([number, date])` could guarantee that its output value will always be of the same coercion as the given input value - the output coercion receiving the Coercion object that was successfully matched by the input coercion - along with additional comparison checks, e.g. `outputValue>inputValue`, which can also be converted into mixture of compile-time and run-time checks when cross-compiling to Swift)

// TO DO: any benefit in annotating Values parsed from source code as `.literal`, `.immutable`, etc, to distinguish from Values created at runtime? (e.g. parser and/or runtime could intern or otherwise optimize literal values that they know will never be mutated)

// TO DO: assuming Value supports flexible annotating (i.e. per-value dict/struct rather than hardcoded vars), parser should attach source code range to each AST node for use in generating error messages, tracebacks, GUI editor code highlighting (c.f. OSAScriptError), etc

// TO DO: also consider supporting tuple syntax in multiple assignments, return values. (Note that `return` could be defined solely as a command, in which case the parens are mandatory there anyway, or as a prefix operator with custom parsefunc that accepts either tuple syntax or single EXPR. Likewise, an assignment operator can use a custom parsefunc to accept either `TUPLE of IDENTIFIER` or `IDENTIFIER`.) Using tuple syntax for command arguments only is wasteful and lacks symmetry (technically every command is a unary operator `f x -> y`; it just so happens that the argument type is always a tuple, but this is purely to avoid syntactic ambiguity), although we probably want to avoid arbitrary use


// TO DO: may need non-maskable `current_scope`/`[scope of] current_handler` for use in `tell` blocks and other contexts which can mask parent scopes' slots; one advantage of this is that prototype OO might be implemented as constructor handlers that return their own scope (Env) as AttributedValue (if a 'parent' is assigned, e.g. `to Bar () returning custom_object { parent: Foo (), … }` (note: if `custom_object` is specified as return type, `return scope of current_handler` isn't needed), need to wrap both that and handler scope in a TargetScope to preserve both delegation chains); Q. how close is ScopeValue to an AS-style script object? main challenge is full-object serialization [which is also problematic in AS ever since it got Cocoa support, compounded by sandbox restrictions on self-mutating executable files; even with Codable protocol for known native objects, it's unlikely we'd be able to serialize entire Environments alongside ASTs]; Q. how [well] did Frontier's object database handle persistent native vs foreign object storage?


// abstract base class


class Value: CustomStringConvertible {
    
    // base class for all native values // Q. would it be better for Value to be a protocol + extension? (need to check how multiple extensions that implement same methods are resolved, e.g. if Value extension implements default toTYPE methods)
    
    lazy var annotations = [Int:Any]() // TO DO: what data structure?
    
    var description: String { return "«TODO: `\(type(of:self)).description`»" }
    
    // TO DO: class var typeName (canonical name, e.g. `list`), var typeName (generated from self.nominalType, e.g. `list(text,max:10)`)
    
    class var nominalType: Coercion { return asAnything /*fatalError("Not yet implemented: \(type(of:self)).nominalType")*/ } // TO DO: need to return Precis
    
    var nominalType: Coercion { return type(of: self).nominalType }
    
    // TO DO: implement debugDescription (this should return Swift representation whereas description should return native representation using default formatting)
    
    // TO DO: implement pretty printing API (ideally this would be a general-purpose Visitor API; Q. for rewriting, use read-only visitor API that reconstructs entire AST from scratch, or support read-write? [right now most Value classes' internal state is `let` rather than `private(set)var`])
    
    // toTYPE() methods; these are called by Coercion.bridgingEval()/nativeEval() methods to convert; they should not be called directly
    
    func toAny(env: Scope, coercion: Coercion) throws -> Value { // collection subclasses override this to recursively evaluate items
        return self
    }
    
    // concrete subclasses must override the following as appropriate
    
    func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        return trueValue
    }
    
    func toText(env: Scope, coercion: Coercion) throws -> Text { // re. coercion parameter: Coercion is assumed to be AsText, but may be AsString or other coercion as long as its coerce() method returns Text (would be good to get this strongly typed, but need to decide inheritance hierarchy for Coercion types)
        throw CoercionError(value: self, coercion: coercion)
    }
    
    func toTag(env: Scope, coercion: Coercion) throws -> Tag {
        throw CoercionError(value: self, coercion: coercion)
    }
    
    func toRecordKey(env: Scope, coercion: Coercion) throws -> RecordKey {
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
    
    func toRecord(env: Scope, coercion: AsRecord) throws -> Record {
        throw CoercionError(value: self, coercion: coercion)
    }
    
    func toDictionary<K: BridgingCoercion, V: BridgingCoercion, T: AsDictionary<K,V>>(env: Scope, coercion: T) throws -> [K.SwiftType:V.SwiftType] {
        throw CoercionError(value: self, coercion: coercion)
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

 

// abstract base classes for values (blocks, identifiers, commands) that evaluate to yield other values

class Expression: Value {
    
    // forward all Expression.toTYPE() calls to bridgingEval()/nativeEval()
    
    override class var nominalType: Coercion { return asAnything }
    
    //
    
    // not sure this helps (also hits speed); need to check if/where Expression.toTYPE() methods could be called, given that they implement their own eval entry points
    internal func safeRun<T: Value>(env: Scope, coercion: Coercion, function: String = #function) throws -> T {
        let value: Value
        // do {
        value = try self.nativeEval(env: env, coercion: coercion)
        // } catch let e as NullCoercionError { // check
        //     print("\(self).safeRun(coercion:\(coercion)) caught null coercion result.")
        //    //throw CoercionError(value: self, coercion: coercion)
        //     throw e
        // }
        return value as! T
        //guard let result = value as? T else { // kludgy; any failure is presumably an implementation bug in a Coercion.coerce()/Value.toTYPE() method
        //    throw InternalError("\(type(of:self)) \(function) expected \(coercion) coercion to return \(T.self) but got \(type(of: value)): \(value)")
        //}
        //return result
    }
    
    //
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value { // still gets called on Identifier, Command, Block
        //        print("\(type(of:self)).\(#function) was called")
        return try self.nativeEval(env: env, coercion: coercion)
    }
    
    override func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        return try self.safeRun(env: env, coercion: coercion)
    }
    
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        //        print("\(type(of:self)).\(#function) was called")
        return try self.safeRun(env: env, coercion: coercion)
    }
    
    override func toList(env: Scope, coercion: AsList) throws -> List {
        //        print("\(type(of:self)).\(#function) was called")
        return try self.safeRun(env: env, coercion: coercion) // ditto
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        print("\(type(of:self)).\(#function) was called")
        return try self.bridgingEval(env: env, coercion: coercion)
    }
    
    override func toRecord(env: Scope, coercion: AsRecord) throws -> Record {
        return try self.safeRun(env: env, coercion: coercion)
    }
}






