//
//  selector protocols.swift
//



// TO DO: separate protocols for ordered (by-index/by-range) and unordered (by-name/by-id) collections? (unlike Python dicts, Swift dictionaries aren't order-preserving so by-index access isn't practical)

// problem here is trying to serve two masters before all requirements are understood; might be best to implement for aelib, then work out how to generalize it


protocol Selectable { // unselected (all) elements // TO DO: rename `Elements`? // TO DO: need default method implementations that throw 'unrecognized reference form' error (only applies to native collections; AE specifiers must permit all legal selector forms, regardless of what app dictionary says, as it's target app's decision whether to accept it or not)
    
    // TO DO: should these take env + coercion arguments, allowing return type to be specified?
    
    func byIndex(_ selectorData: Value) throws -> Value // by-index/by-range
    
    func byName(_ selectorData: Value) throws -> Value // TO DO: KV lists will use `item named NAME of KV_LIST`
    
    func byID(_ selectorData: Value) throws -> Value // argument is an opaque identifier previously supplied by target, not a value users would generate themselves; Q. any use outside of aelib? (e.g. a web library might pass URIs here)
    
    func first() throws -> Value
    func middle() throws -> Value
    func last() throws -> Value
    func any() throws -> Value
    func all() throws -> Value // TO DO: these need to throw if returning resolved values
    
    // func previous/next(elementType) throws -> Value
    
    func byTest(_ selectorData: Value) throws -> Value

    
    // func before()/after()/()beginning()/end() throws -> InsertionLocation
    
}

