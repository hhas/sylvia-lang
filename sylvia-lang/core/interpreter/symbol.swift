//
//  symbol.swift
//



class Symbol: Value {
    
    override var description: String { return "\(symbolLiteralPrefix)‘\(self.swiftValue)’" }
    
    override class var nominalType: Coercion { return asSymbol }
    
    let key: String
    
    let swiftValue: String
    
    init(_ swiftValue: String) {
        self.swiftValue = swiftValue
        self.key = swiftValue.lowercased()
    }
    
    override func toSymbol(env: Scope, coercion: Coercion) throws -> Symbol {
        return self
    }
}


