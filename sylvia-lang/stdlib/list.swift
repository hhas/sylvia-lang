//
//  list.swift
//


// TO DO: how best to define bridging glue for native attributes?

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

// Q. at what point should chunk expressions resolve? (unlike AS, there's no implicit `get`, so presumably will resolve immediately according to type of object to which they're applied: native object -> native object; remote reference -> remote reference)

// Q. how to implement chunk exprs over native values (e.g. `items of my_list where CONDITION`)? (note that same implementation might eventually provide underpinnings for a new IPC handling framework)


// re. global namespace, supporting `A.B` as synonym of `B of A` allows reverse domain names to be used idiomatically as module names+mount points, e.g. `use com.example.foo`, `use mylib of org.example.repo` [where `use` is analogous to C `include` or Swift `import`]

// Q. how best to resolve name collisions when importing multiple modules? one option might be to block all direct referrals to that name when evaluating from source, requiring user always to qualify to avoid any ambiguity/race; in the case of baked scripts, each library's handler names would be included in the script, allowing the script to run against newer versions of the same libraries ignoring any new names that have since been added to those libraries (i.e. versioning libraries' interfaces is more significant than versioning their implementations; doubly so for libraries that define operators)


// TO DO: think it's important that symbols have their own syntax, to eliminate confusion between symbols and specifiers, e.g. in AS, `document` = class name, but `document 1` = specifier; syntax options are limited, `#NAME`, `~NAME`, ``NAME`; don't want to use `:NAME` as colon is already used as pair operator




protocol Selectable { // unselected (all) elements // TO DO: rename `Elements`? // TO DO: need default method implementations that throw 'unrecognized reference form' error (only applies to native collections; AE specifiers must permit all legal selector forms, regardless of what app dictionary says, as it's target app's decision whether to accept it or not)
    
    func selectByIndex(_ index: Value) throws -> Value
    
    func selectByIndex(_ index: Int) throws -> Value
    
    func selectByName(_ name: String) throws -> Value // TO DO: KV lists will want to use `item named NAME of KV_LIST`
    
    func selectByName(_ name: Value) throws -> Value // TO DO: KV lists will want to use `item named NAME of KV_LIST`
    
    func selectByRange(from startIndex: Int, to endIndex: Int) throws -> Value // Value may be List, ObjectSpecifier, etc
    
    // func selectByRange(from startSpecifier: Value, to endSpecifier: Value) throws -> Value // how best to implement generalized by-range? (start and end are con-based specifiers, with integer and string values as shortcuts for by-index and by-name selectors respectively)
    
    // func selectByTest(from startIndex: Int, to endIndex: Int) throws -> Value
    
    // func selectByID(_ uid: Value) throws -> Value
    
    // func first/middle/last/any/every() throws -> Value
    
    // func before/after/beginning/end() throws -> InsertionLocation
    
    // func previous/next(elementType) throws -> Value
    
}




let nullEnv = Env()


extension List: Scope {
    
    func child() -> Scope { // TO DO: normally used by NativeHandler; could also be used by nested `tell` blocks; any reason why it might be used here?
        return self // what to return?
    }
    
    func set(_ name: String, to value: Value, readOnly: Bool, thisFrameOnly: Bool) throws {
        fatalError() // TO DO: any settable attributes? if not, throw ReadOnly error
    }
    
    func get(_ name: String) throws -> (value: Value, scope: Scope) { // TO DO: scope is returned here for benefit of handlers that need to mutate handlerEnv (or create bodyEnv from handlerEnv)
        switch name {
        case "item", "items": // singular/plural naming conventions aren't consistent, so have to treat them as synonyms; TO DO: where both spellings are available, pretty printer should choose according to to-one/to-many selector, e.g. `item at 1`, `items at 1 thru 3`
            return (ListItemAccessor(self), nullEnv) // TO DO: kludge; don't really want to pass nullEnv here
        case "at": // `item at 1 of LIST` -> `'of' ('at' (item, 1), LIST)`, which looks up `at` on LIST
            return (IndexSelectorConstructor(parentObject: self), nullEnv)
        default:
            throw UnrecognizedAttributeError(name: name, value: self)
        }
        
        // Q. when a library implements operator syntax for a command handler, that handler must(?) be non-maskable; Q. what about operators over value slots (e.g. `at`)?
        
        // if we allow `IDENTIFIER EXPR` as synonym for `IDENTIFIER(EXPR)`, the `at` and `named` forms could be provided by callables, e.g. `item x of foo` == `item(x) of foo` == `item at x of foo` when foo is ordered list, or `item named x of foo` when foo is key-value list (i.e. dictionary), although this does get trickier with application specifiers where both forms are often supported by an object, so would have to standardize on `at` form only
    }
    
}


class ListItemAccessor: CallableValue, Selectable { // `items of LIST` specifier; constructed by `List` extension
    
    // TO DO: should this be callable, e.g. `item(3) of LIST`? this really only makes sense if parens can be omitted when a single unnamed argument is given, i.e. `item 3 of LIST`
    var interface = CallableInterface(
        name: "item",
        parameters: [(name: "at", coercion: asInt)], // `item (INDEX)` is shortcut for `item at INDEX`
        returnType: asAnything
    )
    
    private let list: List // TO DO: IndexedValue protocol
    
    init(_ list: List) {
        self.list = list
    }
    
    // TO DO: to support selectors, `item` and `items` are effectively synonyms; `call` invokes preferred selector form (`at` for ordered list, `named` for key-value list); define `Selectable` protocol (Q. how to provide default implementations for unsupported forms?)
    
    // TO DO: atRange; Q. how will app selectors implement atIndex, given that anything can be passed there?
    
    func selectByIndex(_ index: Int) throws -> Value {
        let length = self.list.swiftValue.count
        if index > 0 && index <= length { return self.list.swiftValue[index-1] }
        if index < 0 && -index <= length { return self.list.swiftValue[length+index] }
        throw ConstraintError(value: Text(String(index))) // TO DO: out of range
    }
    
    func selectByIndex(_ index: Value) throws -> Value {
        switch index {
        case let text as Text:
            if let n = Int(text.swiftValue) { return try self.selectByIndex(n) }
        // TO DO: `case let range as Range:`
        default:
            () // fall thru
        }
        throw ConstraintError(value: index) // TO DO: what error type?
    }
    
    func selectByName(_ name: String) throws -> Value {
        throw UnsupportedSelectorError(name: "named", value: self)
    }
    
    func selectByName(_ name: Value) throws -> Value {
        throw UnsupportedSelectorError(name: "named", value: self)
    }
    
    func selectByRange(from startIndex: Int, to endIndex: Int) throws -> Value { // TO DO: what return value? `List` or `[Value]`?
        fatalError()
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // TO DO: delete this unless implementing `item INDEX` as shortcut for `item at INDEX` (assuming parens-less commands are practical)
        let index = try asInt.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return try self.selectByIndex(index)
    }
}
