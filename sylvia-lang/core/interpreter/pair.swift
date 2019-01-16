//
//  pair.swift
//
//
// colon-separated key-value pair
//
// like Identifier, this is generally only used in AST
//

class Pair: Value {
    
    override var description: String { return "\(self.swiftKey):\(self.swiftValue)" }
    
    override class var nominalType: Coercion { return asSymbol }
    
    let key: String
    
    let swiftKey: Value
    let swiftValue: Value
    
    init(_ swiftKey: Value, _ swiftValue: Value) {
        self.swiftKey = swiftKey
        self.swiftValue = swiftValue
        self.key = "" // TO DO: if swiftKey is Identifier
    }
}

