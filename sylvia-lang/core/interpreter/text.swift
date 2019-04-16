//
//  text.swift
//


class Text: Value, SwiftWrapper, RecordKeyConvertible { // note that Identifier and Command may appear as keys in table literals, but are not themselves valid keys so must be coerced via asRecordKey at runtime
    
    override var description: String { return "“\(self.swiftValue)”" } // TO DO: pretty printing
    
    override class var nominalType: Coercion { return asText }
    
    internal(set) public var scalar: Scalar? // TO DO: any way to make this lazily self-initialize if not set by init?
    
    // hash key // TO DO: what about case-insensitivity?
    
    public var hashValue: Int { return self.swiftValue.hashValue }
    public func hash(into hasher: inout Hasher) { self.swiftValue.hash(into: &hasher) }
    public static func == (lhs: Text, rhs: Text) -> Bool { return lhs.swiftValue == rhs.swiftValue } // TO DO: what about `rhs:Value`? (and, for that matter, what about normalizing case as standard? right now only Tag is case-insensitive, although there are cons to case-insensitive keys in a mutable dictionary, as the keys that go in are not guaranteed to preserve case; e.g. consider `d["Bob"]=1` followed by `d["bob"]=1`; which case gets kept and which gets discarded?)
    
    // TO DO: need ability to capture raw Swift value in case of numbers, dates, etc; while this could be done in annotations, it might be quicker to have a dedicated private var containing enum of standard raw types we want to cache (.int, .double, .scalar, .date, whatever); another option is for annotations to be linked list/B-tree where entries are ordered according to predefined importance or frequency of use (would need to see how this compares to a dictionary, which should be pretty fast out of the box with interned keys)
    
    private(set) var swiftValue: String // TO DO: restricted mutability; e.g. perform appends in-place only if refcount==1, else copy self and append to that
    
    init(_ swiftValue: String, scalar: Scalar? = nil) { // TO DO: what constraints are appropriate here? e.g. nonEmpty, minLength, maxLength, pattern, etc are all possibilities; simplest from API perspective is regexp, although that's also the most complex (unless standard patterns for describing the other constraints - e.g. "."/".+"/"\A.+\Z" are common patterns for indicating 'nonEmpty:true' - are recognized and optimized away)
        self.swiftValue = swiftValue
        self.scalar = scalar
    }
    
    override func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        return self.swiftValue == "" ? falseValue : trueValue
    }
    
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        return self
    }
    
    override func toRecordKey(env: Scope, coercion: Coercion) throws -> RecordKey {
        return self.recordKey
    }
}




extension Text {
    
    convenience init(_ scalar: Scalar)  { self.init(scalar.literalRepresentation(), scalar: scalar) }
    convenience init(_ n: Int)          { self.init(Scalar(n)) }
    convenience init(_ n: Double)       { self.init(Scalar(n)) }
    
    func toScalar() throws -> Scalar { // initializes scalar property on first use
        if let scalar = self.scalar { return scalar }
        do {
            let scalar = try Scalar(self.swiftValue)
            self.scalar = scalar
            return scalar
        } catch {
            self.scalar = .invalid(self.swiftValue) // set Text.scalar property to .invalid, which will always throw when used
            throw error
        }
    }
    func toInt() throws -> Int { return try self.toScalar().toInt() }
    func toDouble() throws -> Double { return try self.toScalar().toDouble() }
}



// convenience constants

let emptyText = Text("")

let piValue = Text(Double.pi)
