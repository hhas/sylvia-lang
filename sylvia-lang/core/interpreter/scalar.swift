//
//  scalar.swift
//


import Darwin


// TO DO: Text values can represent Scalar, Quantity, Currency, Date/Time; what else? how best to cache? (Scalar has its own ivar for efficiency; other values may go in `attributes`)


enum Scalar { // represents an integer (as Swift Int) or decimal (as Swift Double) number; numbers that are valid but too large to represent using standard Swift types are held as strings // TO DO: BigNum support (e.g. https://github.com/mkrd/Swift-Big-Integer)
    
    case integer(Int, radix: Int)
    case floatingPoint(Double)
    case overflow(String, Any.Type) // TO DO: separate enums for int vs double overflows? also, what about UInt?
    case invalid(String) // not a number
    
    init(_ n: Int, radix: Int = 10) {
        self = .integer(n, radix: radix)
    }
    init(_ n: Double) {
        self = (n == Double.infinity) ? .overflow(String(n), Double.self) : .floatingPoint(n)
    }
    
    init(_ code: String) throws {
        let lexer = Lexer(code: code)
        switch lexer.readNumber() {
        case .number(value: _, scalar: let scalar):
            self = scalar
        default:
            throw CoercionError(value: Text(code), coercion: asScalar)
        }
    }
    
    // initializers primarily intended for use by scalar parsefuncs below // TO DO: should these *only* be used by numeric parsefuncs?
    // note: these constructors use Swift's own Int(String)/Double(String) constructors, thus underscores may be used as thousands separators, leading/trailing whitespace is not allowed, int constructor doesn't accept decimals, double constructor only accepts period (`.`) as decimal separator, fractional exponents aren't allowed, etc.
    
    // TO DO: init(number code: String,...) that chooses best internal representation? this basically means calling readDecimalNumber() parsefunc, so not sure how useful that is really, given that these inits only exist for parsefuncs' use in the first palce
    
    // unwrap Swift primitives
    
    func toInt() throws -> Int {
        switch self {
        case .integer(let n, _): return n
        case .floatingPoint(let n) where n.truncatingRemainder(dividingBy: 1) == 0:
            if n >= Double(Int.min) && n <= Double(Int.max) { return Int(n) }
            throw ConstraintError(value: self, message: "Number is not in allowed range: \(self.literalRepresentation())") // TO DO: what name, arguments?
        case .overflow(_, let t) where t is Int.Type:
            throw ConstraintError(value: self, message: "Number is not in allowed range: \(self.literalRepresentation())")
        default:
            throw ConstraintError(value: self, message: "Not a whole number: \(self.literalRepresentation())")
        }
    }
    
    func toDouble() throws -> Double {
        switch self {
        case .integer(let n, _): return Double(n)
        case .floatingPoint(let n): return n
        default: throw ConstraintError(value: self, message: "Number is too large to use: \(self.literalRepresentation())")
        }
    }
    
    
    // overloaded generic-friendly version of toInt/toDouble; used by numeric coercions' generic base class
    
    private func _toInt(_ min: Int, _ max: Int) throws -> Int {
        let n = try self.toInt()
        if n < min || n > max { throw ConstraintError(value: self, message: "Number is not in allowed range: \(self.literalRepresentation())") }
        return n
    }
    private func _toUInt(_ max: UInt) throws -> UInt {
        let n = try self.toInt()
        if n < 0 || UInt(n) > max { throw ConstraintError(value: self, message: "Number is not in allowed range: \(self.literalRepresentation())") }
        return UInt(n)
    }
    
    //
    
    func literalRepresentation() -> String { // get canonical code representation (note: this is currently implemented as a method to allow for formatting options to be passed in future) // TO DO: check these representations are always correct
        switch self {
        case .integer(let n, _):
            return String(n)
        case .floatingPoint(let n):
            return String(n)
        case .overflow(let s, _):
            return s
        case .invalid(let s):
            return s
        }
    }
    
    // TO DO: implement formattedRepresentation (custom/locale-specific) here? or does that logic belong solely in formatting command? (i.e. all Values should implement API for outputting pretty-printed code representation, but not sure if that API should support all formatting operations)
}



//**********************************************************************
// generic helper functions for basic arithmetic and numerical comparisons


func scalarArithmeticOperation(_ lhs: Scalar, _ rhs: Scalar, intOperator: ((Int,Int)->(Int,Bool))?, doubleOperator: (Double,Double)->Double) throws -> Scalar {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        if let op = intOperator {
            let (result, isOverflow) = op(leftOp, rightOp)
            // TO DO: how best to deal with integer overflows? switch to Double automatically? (i.e. loses precision, but allows operation to continue)
            return isOverflow ? .overflow(String(doubleOperator(try lhs.toDouble(), try rhs.toDouble())), Int.self) : Scalar(result)
        } else {
            return try Scalar(doubleOperator(lhs.toDouble(), rhs.toDouble()))
        }
    default: // TO DO: this should be improved so that if one number is Int and the other is a Double that can be accurately represented as Int then Int-based operation is tried first; if that overflows then fall back to using Doubles; note that best way to do this may be to implement Scalar.toBestRepresentation() that returns .Integer/.FloatingPoint after first checking if the latter can be accurately represented as an Integer instead
        return try Scalar(doubleOperator(lhs.toDouble(), rhs.toDouble()))
    }
}

func scalarComparisonOperation(_ lhs: Scalar, _ rhs: Scalar, intOperator: (Int,Int)->Bool, doubleOperator: (Double,Double)->Bool) throws -> Bool {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        return intOperator(leftOp, rightOp)
    default:
        return try doubleOperator(lhs.toDouble(), rhs.toDouble()) // TO DO: as above, use Int-based comparison where possible (casting an Int to Double is lossy in 64-bit, which may affect correctness of result when comparing a high-value Int against an almost equivalent Double)
        // TO DO: when comparing Doubles for equality, use almost-equivalence as standard? (e.g. 0.7*0.7=0.49 will normally return false due to rounding errors in FP math, which is likely to be more confusing to users than if the test is fudged)
    }
}


//**********************************************************************
// Arithmetic and comparison operators are defined on Scalar so that primitive procs can perform basic
// numerical operations without having to check or care about underlying representations (Int or Double).


typealias ScalarArithmeticFunction = (Scalar, Scalar) throws -> Scalar
typealias ScalarComparisonFunction = (Scalar, Scalar) throws -> Bool


prefix func -(lhs: Scalar) throws -> Scalar {
    return try scalarArithmeticOperation(Scalar(0), lhs, intOperator: {(l:Int,r:Int) in l.subtractingReportingOverflow(r)}, doubleOperator: -) // TO DO
}

func +(lhs: Scalar, rhs: Scalar) throws -> Scalar {
    return try scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.addingReportingOverflow(r)}, doubleOperator: +)
}
func -(lhs: Scalar, rhs: Scalar) throws -> Scalar {
    return try scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.subtractingReportingOverflow(r)}, doubleOperator: -)
}
func *(lhs: Scalar, rhs: Scalar) throws -> Scalar {
    return try scalarArithmeticOperation(lhs, rhs, intOperator: {(l:Int,r:Int) in l.multipliedReportingOverflow(by: r)}, doubleOperator: *)
}
func /(lhs: Scalar, rhs: Scalar) throws -> Scalar {
    return try scalarArithmeticOperation(lhs, rhs, intOperator: nil, doubleOperator: /)
}
//func %(lhs: Scalar, rhs: Scalar) throws -> Scalar { // TO DO: truncatingRemainder
//    return try scalarArithmeticOperation(lhs, rhs, intOperator: nil, doubleOperator: %)
//}
func pow(_ lhs: Scalar, _ rhs: Scalar) throws -> Scalar {
    return Scalar(try pow(lhs.toDouble(), rhs.toDouble()))
}
func integerDivision(_ lhs: Scalar, rhs: Scalar) throws -> Scalar {
    switch (lhs, rhs) {
    case (.integer(let leftOp, _), .integer(let rightOp, _)):
        return Scalar(leftOp / rightOp)
    default:
        let n = try (lhs / rhs).toDouble()
        return Scalar((n >= Double(Int.min) && n <= Double(Int.max)) ? Int(n) : lround(n))
    }
}



func <(lhs: Scalar, rhs: Scalar) throws -> Bool {
    return try scalarComparisonOperation(lhs, rhs, intOperator: <, doubleOperator: <)
}
func <=(lhs: Scalar, rhs: Scalar) throws -> Bool {
    return try scalarComparisonOperation(lhs, rhs, intOperator: <=, doubleOperator: <=)
}
func ==(lhs: Scalar, rhs: Scalar) throws -> Bool {
    return try scalarComparisonOperation(lhs, rhs, intOperator: ==, doubleOperator: ==)
}
func !=(lhs: Scalar, rhs: Scalar) throws -> Bool {
    return try scalarComparisonOperation(lhs, rhs, intOperator: !=, doubleOperator: !=)
}
func >(lhs: Scalar, rhs: Scalar) throws -> Bool {
    return try scalarComparisonOperation(lhs, rhs, intOperator: >, doubleOperator: >)
}
func >=(lhs: Scalar, rhs: Scalar) throws -> Bool {
    return try scalarComparisonOperation(lhs, rhs, intOperator: >=, doubleOperator: >=)
}



