//
//  operator.swift
//

//  registry for all library-defined operator definitions; used by Lexer when matching words and symbols to determine if they're operators or not, and obtain the appropriate parsing details for use by Pratt parser

// - whole-word matching: word-based operator names (e.g. `AND`, `as`) must be bounded by non-word characters (whitespace/punctuation/symbol/linebreak/etc)
// - longest match: symbol-based operators (e.g. `==`, `&`) can be bounded by anything, including other symbols

//
// note: if underscore_names are used as standard, that would allow all code to be case-insensitive (though possibly still case-preserving) - worth considering as it allows single standard naming rule that works across all languages and eliminates case as potential source of 'unknown identifier' bugs; if bridging to foreign APIs, e.g. Cocoa, where camelCase is the norm, names would need to be mapped from one to other (any existing underscores would need escaping); another benefit of using underscores is that GUI editor can format `_` characters at ~30% opacity, so displayed code scans more like written text while remaining syntactically and semantically clear (c.f. the old AppleScripter trick of setting keywords to pretty print with underscores, or 60s languages (IMP?) that used underscoring to indicate identifiers); given a glossary of known terms, an editor could allow such identifiers to be typed using spacebar instead of underscore for convenience (space is the easier key to hit), automatically replacing spaces with underscores where unambiguous or prompting user to correct manually (c.f. Word's squiggly underscores on spelling and grammar issues) - done sufficiently well, this may obviate need for true 'multi word identifiers' (c.f. entoli)


import Foundation


typealias OperatorDefinition = (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName], handlerName: String?)


enum OperatorName : ExpressibleByStringLiteral, Hashable { // advantage of defining OperatorName as enum rather than simple string is that code-generated operator tables can specify operator form in advance, avoiding need to call init(_:) at load-time
    
    case word(String, String)   // e.g. `lt`, `is_before`
    case symbol(String, String) // e.g. `+`, `>=`
    
    init(stringLiteral: String) { self.init(stringLiteral) }
    
    init(_ name: String) {
        if let p = name.first?.unicodeScalars.first { // TO DO: as elsewhere, this won't work right if first character is composed of >1 codepoint
            let chars = CharacterSet(charactersIn: name)
            if identifierCharacters.contains(p) && chars.subtracting(identifierAdditionalCharacters).isEmpty {
                self = .word(name, name.lowercased())
                return
            } else if chars.subtracting(symbolicCharacters).isEmpty {
                self = .symbol(name, name.lowercased())
                return
            }
        }
        // following will only happen on operator tables hand-coded in Swift
        fatalError("Invalid operator name (contains illegal characters): \(name.debugDescription)")
    }
    
    var name: String {
        switch self {
        case .word(let name, _), .symbol(let name, _): return name
        }
    }
    
    var key: String { // TO DO: rename 'key' throughout
        switch self {
        case .word(_, let name), .symbol(_, let name): return name
        }
    }
}


//

class SymbolSearchTree: CustomDebugStringConvertible { // performs longest-match identification of symbol-based operator names // TO DO: probably make this private once development/debugging is done (OperatorRegistry should provide a better `debugDescription` implementation that returns hierarchical representation of loaded symbol-matching tables and the operators to which they match for troubleshooting purposes)
    
    // TO DO: for stdlib, consider serializing this entire data structure, avoiding need to populate it from scratch during interpreter startup (operator definitions supplied by other libraries would still need to be added to it)
    
    typealias SymbolTable = [Character: SymbolSearchTree]
    
    private var symbols = SymbolTable()
    internal var isComplete: Bool = false
    
    var debugDescription: String { return "\(self.isComplete ? "X" : "")\(self.symbols)" } // quick-n-nasty; get rid of this once OperatorRegistry provides improved description strings
    
    func add(_ name: String) {
        if let c = name.first {
            let rest = String(name.dropFirst())
            if let table = self.symbols[c] {
                table.add(rest)
            } else {
                let table = SymbolSearchTree()
                self.symbols[c] = table
                table.add(rest)
            }
        } else {
            self.isComplete = true
        }
    }
    
    func matchLongestSymbol(_ lexer: Lexer) -> String? {
        if let c = lexer.next() { // advance lexer by one character
            if let table = self.symbols[c] { // could this + preceding characters be the start (or all) of an symbol-based operator name?
                if let result = table.matchLongestSymbol(lexer) { // recursively see if the next character(s) continue the match
                    return String(c) + result // as recursive calls return, add preceding characters to give the full operator name
                } else if table.isComplete {
                    return String(c) // found end of longest match, so return the last character of full operator name
                }
            }
            lexer.backtrack() // if the character wasn't part of a known operator name, return cursor to previous position
        }
        return nil // character was not matched/end of code
    }
}




class OperatorRegistry { // once populated, a single OperatorRegistry instance can be used by multiple Lexer instances (as long as they're all using the same operator definitions)

    typealias OperatorTable = [String: OperatorDefinition] // key is normalized name
    
    // all operator definitions by name/alias (each operator definition appears once under its canonical name, and once for each of its aliases, e.g. `(name:"÷",…,aliases:["/"])` inserts two entries)
    // note that the pretty printer will normally replace aliases with canonical names for consistency, e.g. `2/3` would prettify as `2 ÷ 3`
    private var prefixOperators = OperatorTable()
    private var infixOperators = OperatorTable()
    
    private(set) var symbolLookup = SymbolSearchTree() // tree structure used to perform longest match of symbol-based operator names; topmost node matches 1st character of symbol name, 2nd level matches 2nd character (if any), and so on
    
    private func add(_ definition: OperatorDefinition, named operatorName: OperatorName, to table: inout OperatorTable) {
        guard table[operatorName.key] == nil else {
            print("Can't redefine existing operator: \(operatorName.name.debugDescription)") // TO DO: how to report error if already defined in table? (e.g. pass error info to a callback function/delegate supplied by caller; from UX POV, typically want to deal with all problem operators on completion at once rather than one at a time as they're encountered; e.g. a code editor would prompt user to fix whereas CLI would just abort)
            return
        }
        // need to distinguish symbol-based name from word-based name (operator names must be all symbols or all letters)
        switch operatorName {
        case .word:   () // whole word matching
        case .symbol: self.symbolLookup.add(operatorName.key) // symbol operators can consist of one or more characters, with or without delimiting text, so need to build longest-match tables, e.g. `let x=+1+-2==-1` contains 6 operators (= + + - == -) only partially delimited by code
        }
        table[operatorName.key] = definition
    }
    
    private func add(_ definition: OperatorDefinition, to table: inout OperatorTable) {
        self.add(definition, named: definition.name, to: &table)
        for alias in definition.aliases { self.add(definition, named: alias, to: &table) }
    }

    private func add(_ definition: OperatorDefinition) {
        switch definition.parseFunc {
        case .atom, .prefix:
            self.add(definition, to: &self.prefixOperators)
        case .infix, .postfix:
            self.add(definition, to: &self.infixOperators)
        }
    }
    
    // add zero or more operator definitions to registry
    func add(_ definitions: [OperatorDefinition]) {
        for definition in definitions { self.add(definition) }
    }
    
    // get definition(s) for a word-based operator, if it exists (e.g. `matchWord("mod")` returns infix operator definition for modulus handler)
    func matchWord(_ name: String) -> (OperatorDefinition?, OperatorDefinition?) { // note: this can also match explicitly delimited symbol operators
        let key = name.lowercased()
        return (self.prefixOperators[key], self.infixOperators[key])
    }
    
    // get definition(s) for a symbol-based operator, if it exists (e.g. `matchSymbol("==")` returns infix operator definition for equality handler)
    func matchSymbol(_ lexer: Lexer) -> (OperatorDefinition?, OperatorDefinition?) {
        // TO DO: tell operator registry to find longest possible match and return it, [re]positioning lexer's cursor at end of it (caution: if operators `ABC`, `AB`, `CD` are defined and code is `ABCD`, this will match `ABC` and report `D` is unknown; it is not smart enough to deal with such ambiguity by backtracking to end of `AB` and then trying to match `CD` [which may be just as well, as it keeps the rules simple to understand]; if the user wants `AB` and `CD` operators matched they must be explicitly delimited by [e.g.] a space or parens)
        if let name = self.symbolLookup.matchLongestSymbol(lexer) {
            return self.matchWord(name)
        } else {
            return (nil, nil)
        }
    }
}
