//
//  interface.swift
//

import Foundation



// TO DO: separate protocols for ordered (by-index/by-range) and unordered (by-name/by-id) collections? (unlike Python dicts, Swift dictionaries aren't order-preserving so by-index access isn't practical)

// problem here is trying to serve two masters before all requirements are understood; might be best to implement for aelib, then work out how to generalize it


protocol Selectable { // unselected (all) elements // TO DO: rename `Elements`? // TO DO: need default method implementations that throw 'unrecognized reference form' error (only applies to native collections; AE specifiers must permit all legal selector forms, regardless of what app dictionary says, as it's target app's decision whether to accept it or not)
    
    // TO DO: should these take env + coercion arguments, allowing return type to be specified?
    
    func byIndex(_ index: Value) throws -> Value
    
    func byName(_ name: Value) throws -> Value // TO DO: KV lists will use `item named NAME of KV_LIST`
    
    func byID(_ uid: Value) throws -> Value // argument is an opaque identifier previously supplied by target, not a value users would generate themselves; Q. any use outside of aelib? (e.g. a web library might pass URIs here)
    
    // func first()/middle()/last()/any()/every() throws -> Value // TO DO: these need to throw if returning resolved values
    
    // func previous/next(elementType) throws -> Value
    
    //func byRange(from startReference: Value, to endReference: Value) throws -> Value // TO DO: how best to implement generalized by-range? (start and end are con-based specifiers, with integer and string values as shortcuts for by-index and by-name selectors respectively)
    
    func byTest(_ test: Value) throws -> Value

    
    // func before()/after()/()beginning()/end() throws -> InsertionLocation
    
}




/*
 
 
 
class ListItemsReference: CallableValue, Selectable { // `items of LIST` specifier; constructed by `List` extension
 
    // `item` and `items` are effectively synonyms
 
    override var description: String { return "items of \(self.list)" } // TO DO: expressions need to be generated via pretty printer as representation changes depending on what operator tables are loaded (may be best to use `description` for canonical representations only, e.g. for troubleshooting/portable serialization)
 
    override class var nominalType: Coercion { return asList } // TO DO: AsReference(…)

 
    // ordered list's default reference form is by-index, allowing `item at 3 of LIST` to be written as `item 3 of LIST`
    var interface = CallableInterface(
        name: "item",
        parameters: [(name: "at", coercion: asInt)], // `item (INDEX)` is shortcut for `item at INDEX`
        returnType: asAnything
    )
 
    private let list: List // TO DO: IndexedValue protocol
 
    init(_ list: List) {
        self.list = list
    }
 
    func absIndex(_ index: Int) throws -> Int {
        let length = self.list.swiftValue.count
        if index > 0 && index <= length { return index-1 }
        if index < 0 && -index <= length { return length+index }
        throw ConstraintError(value: Text(String(index))) // TO DO: out of range
    }
 
    // TO DO: to support selectors; `call` invokes preferred selector form (`at` for ordered list, `named` for key-value list); define `Selectable` protocol (Q. how to provide default implementations for unsupported forms?)
 
    // TO DO: atRange; Q. how will app selectors implement atIndex, given that anything can be passed there?
 
    func getByIndex(_ index: Int) throws -> Value {
        return try self.list.swiftValue[self.absIndex(index)]
    }
 
    func byIndex(_ index: Value) throws -> Value { // TO DO: probably need to pass env
        switch index {
        case let text as Text:
            if let n = Int(text.swiftValue) { return try self.getByIndex(n) }
        case let range as Command where range.key == "thru" && range.arguments.count == 2: // TO DO: use `'thru'(m,n)` command here? (i.e. should range always be written as a literal, not passed as result of evaluating expression?)
            return try self.getByRange(from: range.arguments[0], to: range.arguments[1])
        default:
            () // fall thru
        }
        throw GeneralError("Invalid index type: \(index)") // TO DO: what error type?
    }
 
    func getByName(_ name: String) throws -> Value {
        throw UnsupportedSelectorError(name: "named", value: self)
    }
 
    func byName(_ name: Value) throws -> Value {
        throw UnsupportedSelectorError(name: "named", value: self)
    }
 
    func byRange(from startIndex: Int, to endIndex: Int) throws -> Value { // TO DO: what return value? `List` or `[Value]`?
        return try List(self.list.swiftValue[self.absIndex(startIndex)...self.absIndex(endIndex)].map{$0}) // shallow copy
    }
 
    func byRange(from startReference: Value, to endReference: Value) throws -> Value { // TO DO: what return value? `List` or `[Value]`?
        // TO DO: currently only supports by-index; need to accept queries as well
        guard let startText = startReference as? Text, let endText = endReference as? Text,
            let startIndex = Int(startText.swiftValue), let endIndex = Int(endText.swiftValue) else {
                throw GeneralError("Invalid index range: \(startReference) thru \(endReference)") // TO DO: what error type?
        }
        // TO DO: consider defining List.swiftValue as RandomAccessCollection, allowing it to hold ArraySlice as well as Array
        return try List(self.list.swiftValue[self.absIndex(startIndex)...self.absIndex(endIndex)].map{$0}) // shallow copy
    }
 
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // `item INDEX` -> `item(at:INDEX)`
        let index = try asInt.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        if command.arguments.count > 1 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return try self.getByIndex(index)
    }
}

 
 */
