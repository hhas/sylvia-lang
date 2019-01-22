//
//  value protocols.swift
//


// Value subclasses that contain an underlying Swift value in a public let/var named `swiftValue` can adopt this protocol to expose it other protocols and extensions, e.g. see SelfPackingReferenceWrapper in aelib

protocol SwiftWrapper {
    
    associatedtype SwiftType
    
    var swiftValue: SwiftType { get }
    
}


// record keys

// TO DO: define HashableValue as abstract subclass of Value and make Text and Tag concrete subclasses of that? (as usual, Swift's inability to declare methods 'abstract' makes that messier than it ought to be [lots of `fatalError("Subclass needs to override #function")` crap], but it'll be easier to follow than this)

// this is a bit convoluted, but ensures Record's internal Dictionary storage only allows hashable Values (Text and/or Tag) as keys, providing better type safety than using AnyHashable directly (which would allow Swift Strings, Ints, etc to sneak in as well) (in an ideal world we'd just say `typealias HashableValue = Value & Hashable`, but swiftc type checker doesn't allow that as any fule kno)

protocol RecordKeyConvertible: Hashable { } // Values that can be used as record keys (Text, Tag) must adopt this protocol [in addition to implementing the usual Hashable+Equatable methods]

extension RecordKeyConvertible where Self: Value {
    var recordKey: RecordKey { return RecordKey(self) }
}


struct RecordKey: Hashable { // type-safe wrapper around AnyHashable that ensures non-Value types can't get into Record's internal storage by accident, while still allowing mixed-type keys
    
    private let key: AnyHashable
    let value: Value
    
    public init<T: RecordKeyConvertible>(_ value: T) where T: Value {
        self.key = AnyHashable(value)
        self.value = value
    }
    
    public var hashValue: Int { return self.key.hashValue }
    public func hash(into hasher: inout Hasher) { self.key.hash(into: &hasher) }
    public static func == (lhs: RecordKey, rhs: RecordKey) -> Bool { return lhs.key == rhs.key }
}


