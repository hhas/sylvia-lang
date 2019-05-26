//
//  tag.swift
//

// hashtag/symbol


class Tag: Value, SwiftWrapper, RecordKeyConvertible {
    
    override var description: String { return "\(tagLiteralPrefix)‘\(self.swiftValue)’" }
    
    override class var nominalType: Coercion { return asTag }
    
    let key: String
    
    let swiftValue: String
    
    init(_ swiftValue: String) {
        self.swiftValue = swiftValue
        self.key = swiftValue.lowercased()
    }
    
    // hashing
    
    public func hash(into hasher: inout Hasher) { self.key.hash(into: &hasher) }
    public static func == (lhs: Tag, rhs: Tag) -> Bool { return lhs.key == rhs.key }
    
    // expansion
    
    override func toTag(env: Scope, coercion: Coercion) throws -> Tag {
        return self
    }
    
    override func toRecordKey(env: Scope, coercion: Coercion) throws -> RecordKey {
        return self.recordKey
    }
}


