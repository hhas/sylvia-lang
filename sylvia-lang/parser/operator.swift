//
//  operator.swift
//

//  registry for all library-defined operator definitions; used by Lexer when matching words and symbols to determine if they're operators or not, and obtain the appropriate parsing details for use by Pratt parser

// - whole-word matching: word-based operator names (e.g. `AND`, `as`) must be bounded by non-word characters (whitespace/punctuation/symbol/linebreak/etc)
// - longest match: symbol-based operators (e.g. `==`, `&`) can be bounded by anything, including other symbols


import Foundation



typealias OperatorName = String
typealias OperatorDefinition = (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName], command: String?)


//

enum OperatorNameType { // TO DO: merge into `OperatorName` type and implement init(stringLiteral:) (ExpressibleByStringLiteral)
    case word
    case symbol
    case invalid
    
    init(_ name: String) {
        if let p = name.first?.unicodeScalars.first { // TO DO: as elsewhere, doesn't support multiple glyphs
            let chars = CharacterSet(charactersIn: name)
            if identifierCharacters.contains(p) && chars.subtracting(identifierAdditionalCharacters).isEmpty {
                self = .word
            } else if chars.subtracting(symbolCharacters).isEmpty {
                self = .symbol
            } else {
                self = .invalid
            }
        } else {
            self = .invalid
        }
    }
}


//

class SymbolSearchTree: CustomDebugStringConvertible { // performs longest-match identification of symbol-based operator names // TO DO: probably make this private once development/debugging is done (OperatorRegistry should provide a better `debugDescription` implementation that returns hierarchical representation of loaded symbol-matching tables and the operators to which they match for troubleshooting purposes)
    
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

    typealias OperatorTable = [OperatorName: OperatorDefinition]
    
    // all operator definitions by name/alias (each operator definition appears once under its canonical name, and once for each of its aliases, e.g. `(name:"÷",…,aliases:["/"])` inserts two entries)
    // note that the pretty printer will normally replace aliases with canonical names for consistency, e.g. `2/3` would prettify as `2 ÷ 3`
    private var prefixOperators = OperatorTable()
    private var infixOperators = OperatorTable()
    
    private(set) var symbolLookup = SymbolSearchTree() // tree structure used to perform longest match of symbol-based operator names; topmost node matches 1st character of symbol name, 2nd level matches 2nd character (if any), and so on
    
    private func add(_ definition: OperatorDefinition, named name: String, to table: inout OperatorTable) {
        let normalizedName = name.lowercased() // operator names are case-insensitive // TO DO: TBC
        guard table[normalizedName] == nil else {
            print("Can't redefine existing operator: \(name.debugDescription)") // TO DO: how to report error if already defined in table? (e.g. pass error info to a callback function/delegate supplied by caller; from UX POV, typically want to deal with all problem operators on completion at once rather than one at a time as they're encountered; e.g. a code editor would prompt user to fix whereas CLI would just abort)
            return
        }
        // need to distinguish symbol-based name from word-based name (operator names must be all symbols or all letters)
        switch OperatorNameType(normalizedName) {
        case .word: () // whole word matching
        case .symbol:
            self.symbolLookup.add(normalizedName) // symbol operators can consist of one or more characters, with or without delimiting text, so need to build longest-match tables, e.g. `let x=+1+-2==-1` contains 6 operators (= + + - == -) only partially delimited by code
        case .invalid:
            print("Invalid operator name: \(name.debugDescription)")
            return
        }
        table[normalizedName] = definition
    }
    
    private func add(_ definition: OperatorDefinition, to table: inout OperatorTable) {
        self.add(definition, named: definition.name, to: &table)
        for alias in definition.aliases { self.add(definition, named: alias, to: &table) }
        if let name = definition.command { self.add(definition, named: name, to: &table) }
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
        let normalizedName = name.lowercased()
        return (self.prefixOperators[normalizedName], self.infixOperators[normalizedName])
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
