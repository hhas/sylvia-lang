//
//  boolean.swift
//


class Boolean: Value, Equatable, SwiftWrapper {
    
    override var description: String { return String(describing: self.swiftValue) }
    
    let swiftValue: Bool
    
    init(_ swiftValue: Bool) {
        self.swiftValue = swiftValue
    }
    
    public static func == (lhs: Boolean, rhs: Boolean) -> Bool { return lhs.swiftValue == rhs.swiftValue }
    
    override func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        return self
    }
    
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        return self.swiftValue ? Text("ok") : Text("")
    }
    
    // TO DO: what else?
}




// convenience constants


let falseValue = Boolean(false)
let trueValue = Boolean(true)
