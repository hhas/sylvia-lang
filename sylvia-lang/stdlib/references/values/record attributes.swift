//
//  record attributes.swift
//


// TO DO: there's a lot of bouncing about here; wouldn't be so bad if 'All*ItemsSpecifier' was standard implementation that works for any element on any selectable value; also wouldn't hurt if it could all be done as code-generated extensions; really need a 'standard language' for describing value interfaces in terms of attributes and one-to-one and one-to-many relationships (just as we already have a 'standard language' for describing handler interfaces)


extension Record: Attributed { // TO DO: List should be Attributed, not Scope (which is intended for stack frames, JS-style Objects, etc); this needs more thought/work (for starters, it needs to be compiled as part of core, not library, so next step will be to split value.swift into per-class files for easier maintainability and move this there)
    
    // attributes
    
    func set(_ name: String, to value: Value) throws { // TO DO: really want to get rid of this: there shouldn't be any use case where a list attribute (e.g. "items") is set directly, e.g. `set(items of LIST, to:…)`
        fatalError() // TO DO: any settable attributes? if not, throw ReadOnly error
    }
    
    func get(_ key: String) throws -> Value { // e.g. `items of RECORD`
        switch key {
        // TO DO: `keys`, `values`
        // e.g. to resolve `item named KEY of RECORD` `of` operator looks up selector form method (e.g. "named") followed by element[s] name (e.g. "items")
        case "items", "item": // TO DO: is this appropriate? (if so, it should really refer to Pairs); might want to rename "field[s]"
            return AllRecordItemsSpecifier(self, key)
        case "named": // `item named "foo" of RECORD` // TO DO: is there an easy standard way to make selector lookups fall thru to standard handlers?
            return NameSelector(for: self)
        case "where":
            fatalError("TO DO: TestSelector")
        default:
            throw ValueNotFoundError(name: key, env: self)
        }
        
        // Q. when a library implements operator syntax for a command handler, that handler must(?) be non-maskable; Q. what about operators over value slots (e.g. `at`)?
        
        // if we allow `IDENTIFIER EXPR` as synonym for `IDENTIFIER(EXPR)`, the `at` and `named` forms could be provided by callables, e.g. `item x of foo` == `item(x) of foo` == `item at x of foo` when foo is ordered list, or `item named x of foo` when foo is key-value list (i.e. dictionary), although this does get trickier with application specifiers where both forms are often supported by an object, so would have to standardize on `at` form only
    }
    
    func getValue(forKey key: RecordKey) throws -> Value {
        guard let result = self.swiftValue[key] else { throw ValueNotFoundError(name: String(describing: key.value), env: self) } // TO DO: fix ValueNotFoundError
        return result
    }
}



// TO DO: this currently relies on stdlib-defined selector handlers; this needs to change

class AllRecordItemsSpecifier: Handler, Selectable { // `items of LIST` specifier; constructed by `List` extension // TO DO: rename and decide how best to generalize implementation
    
    // `item` and `items` are effectively synonyms
    
    override var description: String { return "items of \(self.value)" } // TO DO: expressions need to be generated via pretty printer as representation changes depending on what operator tables are loaded (may be best to use `description` for canonical representations only, e.g. for troubleshooting/portable serialization)
    
    override class var nominalType: Coercion { return asReference }
    
    // command-based shortcut for constructing the most commonly-used reference form, which for ordered collections is by-index
    // e.g. `item 3 of LIST` (which is syntactic sugar for `item(at:3) of LIST`) is shorthand for `item at 3 of LIST`
    lazy var interface = HandlerInterface(
        name: self.elementsName,
        parameters: [("named", "", asInt)], // TO DO: use `Variant([asRange, asInt])` (need to implement `Variant` Coercion subclass first; Q. how to unpack as typesafe enum which switch block can use directly rather than having to do a further round of `as?` casts?)
        returnType: asAnything
    )
    
    private let value: Record
    let elementsName: String
    
    init(_ value: Record, _ elementsName: String) {
        self.value = value
        self.elementsName = elementsName
    }
    
    // TO DO: to support selectors; `call` invokes preferred selector form (`at` for ordered list, `named` for key-value list); define `Selectable` protocol (Q. how to provide default implementations for unsupported forms?)
    
    // TO DO: atRange; Q. how will app selectors implement atIndex, given that anything can be passed there?
    
    func byIndex(_ index: Value) throws -> Value { // TO DO: probably need to pass env
        throw UnsupportedSelectorError(name: "at", value: self)
    }
    
    func byName(_ selectorData: Value) throws -> Value { // ugh
        guard let key = (selectorData as? Text)?.recordKey ?? (selectorData as? Tag)?.recordKey else { throw GeneralError("by-name selector is not string/tag\(selectorData)") }
        return try self.value.getValue(forKey: key)
    }
    
    func byID(_ selectorData: Value) throws -> Value {
        throw UnsupportedSelectorError(name: "by_ID", value: self) // TO DO: what to call this operator?
    }
    
    func byTest(_ selectorData: Value) throws -> Value {
        fatalError("TO DO: `\(self) where \(selectorData)`")
    }
    
    // syntactic shortcut for 'named' selector
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // `item KEY` == `item named KEY`
        var arguments = command.arguments
        let arg_0 = try asRecordKey.unboxArgument("selector_data", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return try self.value.getValue(forKey: arg_0)
    }
}
