//
//  operator.swift
//

//  registry for all library-defined operator definitions; used by Lexer when matching words and symbols to determine if they're operators or not, and obtain the appropriate parsing details for use by Pratt parser

import Foundation



enum ParseFunc { // defines an operator parsing function for use by Pratt parser; used in OperatorDefinition
    
    typealias Prefix = (_ parser: Parser, _ operatorName: String, _ precedence: Int) throws -> Value
    typealias Infix  = (_ parser: Parser, _ leftExpr: Value, _ operatorName: String, _ precedence: Int) throws -> Value
    
    case atom(Prefix)
    case prefix(Prefix)
    case infix(Infix)
    case postfix(Infix)
}

typealias OperatorName = String
typealias OperatorDefinition = (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName])





class SymbolSearchTree: CustomDebugStringConvertible { // used to perform longest match on symbol-based operators
    
    typealias SymbolTable = [Character: SymbolSearchTree]
    
    private var symbols = SymbolTable()
    internal var isComplete: Bool = false
    
    var debugDescription: String { return "\(self.isComplete ? "X" : "")\(self.symbols)" }
    
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
        guard let c = lexer.next() else { return nil }
        //print("READ: '\(c)'")
        if let table = self.symbols[c] {
            if let result = table.matchLongestSymbol(lexer) {
                return String(c) + result
            } else if table.isComplete {
                return String(c)
            }
        }
        lexer.backtrack()
        return nil
    }
    
}



typealias OperatorTable = [OperatorName: OperatorDefinition]



class OperatorRegistry { // once populated, a single OperatorRegistry instance can be used by multiple Lexer instances (as long as they're all using the same operator definitions)
    
    
    private var prefixOperators = OperatorTable()
    private var infixOperators = OperatorTable() // keys are operator names, including aliases; i.e. each operator definition will appear once in table under its canonical name, and once for each of its aliases, e.g. `(name:"÷", …, aliases: ["/"])` will create two entries; the pretty printer will normally replace aliases with canonical names for consistency, e.g. `2/3` would prettify as `2 ÷ 3` // TO DO: make this a class as keyword and symbol operators require different matching algorithms (whole word case-insensitive vs longest exact match; the first can be done with a flat dictionary, but the second requires a dictionary tree where keys are characters and values are dictionaries of next characters to match [if any]; FWIW, the keyword dictionary could also contain the symbol operators by full name)
    
    private(set) var symbolLookup = SymbolSearchTree()
    
    
    
    private func add(_ definition: OperatorDefinition, named name: String, to table: inout OperatorTable) {
        let normalizedName = name.lowercased() // operator names are case-insensitive // TO DO: TBC
        guard table[normalizedName] == nil else {
            print("Can't redefine existing operator: \(name.debugDescription)") // TO DO: how to report error if already defined in table? (e.g. pass error info to a callback function/delegate supplied by caller; from UX POV, typically want to deal with all problem operators on completion at once rather than one at a time as they're encountered; e.g. a code editor would prompt user to fix whereas CLI would just abort)
            return
        }
        // need to distinguish symbol-based name from word-based name (operator names must be one or other)
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

    }

    func add(_ definition: OperatorDefinition) {
        
        switch definition.parseFunc {
        case .atom, .prefix:
            self.add(definition, to: &self.prefixOperators)
        case .infix, .postfix:
            self.add(definition, to: &self.infixOperators)
        }
    }
    
    func add(_ definitions: [OperatorDefinition]) {
        for definition in definitions { self.add(definition) }
    }
    
    
    func matchWord(_ name: String) -> (OperatorDefinition?, OperatorDefinition?) { // note: this can also match explicitly delimited symbol operators
        let normalizedName = name.lowercased()
        return (self.prefixOperators[normalizedName], self.infixOperators[normalizedName])
    }
    
    func matchSymbol(_ lexer: Lexer) -> (OperatorDefinition?, OperatorDefinition?) {
        // TO DO: tell operator registry to find longest possible match and return it, [re]positioning lexer's cursor at end of it (caution: if operators `ABC`, `AB`, `CD` are defined and code is `ABCD`, this will match `ABC` and report `D` is unknown; it is not smart enough to deal with such ambiguity by backtracking to end of `AB` and then trying to match `CD` [which may be just as well, as it keeps the rules simple to understand]; if the user wants `AB` and `CD` operators matched they must be explicitly delimited by [e.g.] a space or parens)
        
        if let name = self.symbolLookup.matchLongestSymbol(lexer) {
            return self.matchWord(name)
        } else {
            return (nil, nil)
        }
    }
}
