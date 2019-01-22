//
//  pair.swift
//
//
// colon-separated key-value pair
//
// like Identifier, this is generally only used in AST
//

class Pair: Value {
    
    override var description: String { return "\(self.swiftValue.0):\(self.swiftValue.1)" }
    
    override class var nominalType: Coercion { return asTag }
    
    var key: Value { return self.swiftValue.name }
    var value: Value { return self.swiftValue.value }
    
    let swiftValue: (name: Value, value: Value)
    
    init(_ swiftName: Value, _ swiftValue: Value) {
        self.swiftValue = (swiftName, swiftValue)
    }
}

