//
//  stdlib_values.swift
//


// TO DO: how best to define bridging glue for native attributes?




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



let nullEnv = Env()


extension List: Scope {
    func set(_ name: String, to value: Value, readOnly: Bool, thisFrameOnly: Bool) throws {
        fatalError()
    }
    
    func add(_ handler: CallableValue) throws {
        fatalError()
    }
    
    func add(_ interface: CallableInterface, _ call: @escaping PrimitiveCall) throws {
        fatalError()
    }
    
    func add(_ coercion: Coercion) throws {
        fatalError()
    }
    
    func child() -> Env {
        fatalError()
    }
    
    
    func get(_ name: String) throws -> (value: Value, scope: Scope) {
        switch name {
        case "item":
            return (IndexAccessor(self), nullEnv) // TO DO: kludge
        default:
            throw UnrecognizedAttributeError(name: name, value: self)
        }
        
        // Q. how do selectors apply? could be that item and items() are synonyms that return a callable, or could return proxy value that implements `at`, `named`, etc. handlers (in case of ordered list, `at` would be supported; in case of key-value list, `named` would be supported; both would support `where`); fwiw, if we did allow `IDENTIFIER EXPR` as synonym for `IDENTIFIER(EXPR)`, the `at` and `named` forms could be provided by callables, e.g. `item x of foo` = `item(x) of foo`; = `item at x of foo` when foo is ordered list, or `item named x of foo` when foo is key-value list (i.e. dictionary), although this does get trickier with application specifiers where both forms are often supported by an object, so would have to standardize on `at` form only
        // "item"
        // "items"
    }
    
}


class IndexAccessor: CallableValue {
    
    var interface = CallableInterface(
        name: "item",
        parameters: [(name: "at", coercion: asInt)],
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
    
    func selectByRange(from startIndex: Int, to endIndex: Int) throws -> [Value] {
        fatalError()
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        // TO DO: how practical to express 'dependent types'? in this case, `asInt` could be defined as `asIndex` and additionally constrained here with list's length before unboxing
        let index = try asInt.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return try self.selectByIndex(index)
    }
}
