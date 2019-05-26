//
//  list.swift
//
//  TO DO: this is extension on List, so will need to be builtin
//


// TO DO: how best to define bridging glue for native attributes? (for now we just use handcoded `switch` blocks in `get()`; eventually the get method should presumably be in code-generated extension)

//
// attribute types: primitive(?), to-one relationship, to-many relationship; Q. how/when should these be resolved for native values? e.g. , `show (items 1 thru 5 of my_list)` [shows 5-item list], `foo: items 1 thru 5 of my_list` [expr should eval to 5-item list], `foo: reference_to items 1 thru 5 of my_list` [expr will evaluate to reference value], `delete (items 1 thru 5 of my_list)` [`delete` handler will receive specifier as argument]
//


// Q. `count(value)` vs `length of value`?
// `count(value, each: word)` vs `count(words of value)` vs `length of words of value`

// Q. what should be attribute vs what should be command? e.g. use `text 1 thru 5 of value`, not `substr(value, 1, 5)`

// words of value
// characters of value
// text of value
// text [at] 1 thru 5 of value

// note that text values should *not* have `item` elements; i.e. passing a text value where a list of text is expected will treat it as a list containing a single text item, not a list of characters; to iterate over text's characters be explicit, e.g. "map(characters of some_text,EXPR)"


// Q. at what point should chunk expressions resolve? (unlike AS, there's no implicit `get`, so presumably will resolve immediately according to type of object to which they're applied: native object -> native object; remote reference -> remote reference)

// Q. how to implement chunk exprs over native values (e.g. `items of my_list where CONDITION`)? (note that same implementation might eventually provide underpinnings for a new IPC handling framework)


// re. global namespace, supporting `A.B` as synonym of `B of A` allows reverse domain names to be used idiomatically as module names+mount points, e.g. `use com.example.foo`, `use mylib of org.example.repo` [where `use` is analogous to C `include` or Swift `import`]

// Q. how best to resolve name collisions when importing multiple modules? one option might be to block all direct referrals to that name when evaluating from source, requiring user always to qualify to avoid any ambiguity/race; in the case of baked scripts, each library's handler names would be included in the script, allowing the script to run against newer versions of the same libraries ignoring any new names that have since been added to those libraries (i.e. versioning libraries' interfaces is more significant than versioning their implementations; doubly so for libraries that define operators)


// TO DO: think it's important that symbols have their own syntax, to eliminate confusion between symbols and specifiers, e.g. in AS, `document` = class name, but `document 1` = specifier; syntax options are limited, `#NAME`, `~NAME`, ``NAME`; don't want to use `:NAME` as colon is already used as pair operator


// TO DO: how to generalize selections as queries, and when to resolve automatically (e.g. via coercion when consumed) vs explicitly (via `get` command); bear in mind that these need to support set, add, remove, etc; also mind that query resolvers may also provide foundation code for an IPC server framework




extension List: Attributed { // TO DO: List should be Attributed, not Scope (which is intended for stack frames, JS-style Objects, etc); this needs more thought/work (for starters, it needs to be compiled as part of core, not library, so next step will be to split value.swift into per-class files for easier maintainability and move this there)
    
    // attributes
    
    func set(_ name: String, to value: Value) throws { // TO DO: really want to get rid of this: there shouldn't be any use case where a list attribute (e.g. "items") is set directly, e.g. `set(items of LIST, to:…)`
        fatalError() // TO DO: any settable attributes? if not, throw ReadOnly error
    }
    
    func get(_ key: String, delegate: Attributed? = nil) throws -> Value { // e.g. `items of LIST`
        switch key {
        case "items", "item": // singular/plural naming conventions aren't consistent, so have to treat them as synonyms; TO DO: where both spellings are available, pretty printer should choose according to to-one/to-many selector, e.g. `item at 1`, `items at 1 thru 3`
            return AllListItemsSpecifier(self, key)
        case "at": // `item at 1 of LIST` -> `'of' ('at' (item, 1), LIST)`, which looks up `at` on LIST
            return IndexSelector(for: self)
        default:
            throw ValueNotFoundError(name: key, env: self)
        }
        
        // Q. when a library implements operator syntax for a command handler, that handler must(?) be non-maskable; Q. what about operators over value slots (e.g. `at`)?
        
        // if we allow `IDENTIFIER EXPR` as synonym for `IDENTIFIER(EXPR)`, the `at` and `named` forms could be provided by callables, e.g. `item x of foo` == `item(x) of foo` == `item at x of foo` when foo is ordered list, or `item named x of foo` when foo is key-value list (i.e. dictionary), although this does get trickier with application specifiers where both forms are often supported by an object, so would have to standardize on `at` form only
    }
    
    
    
    private func absIndex(_ index: Int) throws -> Int {
        let length = self.swiftValue.count
        if index > 0 && index <= length { return index-1 }
        if index < 0 && -index <= length { return length+index }
        throw ConstraintError(value: Text(String(index))) // TO DO: throw out of range error
    }
    
    func getByIndex(_ index: Int) throws -> Value {
        return try self.swiftValue[self.absIndex(index)]
    }
    
    func getByRange(from startIndex: Int, to endIndex: Int) throws -> [Value] { // TO DO: what return value? `List` or `[Value]`?
        return try self.swiftValue[self.absIndex(startIndex)...self.absIndex(endIndex)].map{$0} // shallow-copy ArraySlice to new Array (in theory List.swiftValue could be typed as RandomAccessCollection, allowing it to hold ArraySlice directly, but this retains original array and also creates safety issues if either List is subsequently mutated)
    }
}



// TO DO: this currently relies on stdlib-defined selector handlers; this needs to change

class AllListItemsSpecifier: Handler, Selectable { // `items of LIST` specifier; constructed by `List` extension // TO DO: rename and decide how best to generalize implementation
    
    // `item` and `items` are effectively synonyms
    
    override var description: String { return "items of \(self.list)" } // TO DO: expressions need to be generated via pretty printer as representation changes depending on what operator tables are loaded (may be best to use `description` for canonical representations only, e.g. for troubleshooting/portable serialization)
    
    override class var nominalType: Coercion { return asReference }
    
    // command-based shortcut for constructing the most commonly-used reference form, which for ordered collections is by-index
    // e.g. `item 3 of LIST` (which is syntactic sugar for `item(at:3) of LIST`) is shorthand for `item at 3 of LIST`
    lazy var interface = HandlerInterface(
        name: self.elementsName,
        parameters: [("at", "", asInt)], // TO DO: use `Variant([asRange, asInt])` (need to implement `Variant` Coercion subclass first; Q. how to unpack as typesafe enum which switch block can use directly rather than having to do a further round of `as?` casts?)
        returnType: asAnything
    )
    
    private let list: List // TO DO: type as OrderedCollection protocol?
    let elementsName: String
    
    init(_ list: List, _ elementsName: String) {
        self.list = list
        self.elementsName = elementsName
    }
    
    // TO DO: to support selectors; `call` invokes preferred selector form (`at` for ordered list, `named` for key-value list); define `Selectable` protocol (Q. how to provide default implementations for unsupported forms?)
    
    // TO DO: atRange; Q. how will app selectors implement atIndex, given that anything can be passed there?
    
    func byIndex(_ index: Value) throws -> Value { // TO DO: probably need to pass env
        switch index {
        case let text as Text:
            if let n = Int(text.swiftValue) { return try self.list.getByIndex(n) }
        case let range as Range:
            guard let startText = range.start as? Text, let endText = range.stop as? Text,
                let startIndex = Int(startText.swiftValue), let endIndex = Int(endText.swiftValue) else {
                    throw NotYetImplementedError("Non-numeric list range is not yet supported: \(range)")
            }
            return try List(self.list.getByRange(from: startIndex, to: endIndex))
        default:
            () // fall thru
        }
        throw GeneralError("Invalid index type: \(index)") // TO DO: what error type?
    }
    
    func byName(_ selectorData: Value) throws -> Value {
        throw UnsupportedSelectorError(name: "named", value: self)
    }
    
    func byID(_ selectorData: Value) throws -> Value {
        throw UnsupportedSelectorError(name: "by_ID", value: self) // TO DO: what to call this operator?
    }
    
    func byTest(_ selectorData: Value) throws -> Value {
        fatalError("TO DO: `\(self) where \(selectorData)`")
    }
    
    // TO DO:
    
    func first() throws -> Value {
        throw UnsupportedSelectorError(name: "first", value: self)
    }
    
    func middle() throws -> Value {
        throw UnsupportedSelectorError(name: "middle", value: self)
    }
    
    func last() throws -> Value {
        throw UnsupportedSelectorError(name: "last", value: self)
    }
    
    func any() throws -> Value {
        throw UnsupportedSelectorError(name: "any", value: self)
    }
    
    func all() throws -> Value {
        throw UnsupportedSelectorError(name: "every", value: self)
    }
    
    // syntactic shortcut for 'at' selector
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // `item INDEX` -> `item(at:INDEX)`
        var arguments = command.arguments
        let arg_0 = try asInt.unboxArgument("selector_data", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return try self.list.getByIndex(arg_0)
    }
}
