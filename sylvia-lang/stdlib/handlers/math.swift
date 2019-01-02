//
//  stdlib/handlers/math.swift
//

import Darwin


// TO DO: should math funcs ever throw, or should outOfRange/divideByZero be captured by Scalar?
//
// TO DO: check how Int/Double signals out-of-range

// TO DO: use Icon-style behavior for comparison operators? this'd allow comparison operations to be chained, e.g. `0 < x <= 10` (on success, returns right-hand operand as-is [this includes empty values]; on failure, returns 'noComparison' flag which causes subequent comparisons to return noComparison as well)


// signature: add(a: primitive(double), b: primitive(double)) returning primitive(double)
// requirements: throws // TO DO: should `throws` be declared as part of return coercion: `errorOr(RETURNTYPE)`? (optionally including list of error coercion[s] where known?)

func exponent(a: Scalar, b: Scalar) throws -> Scalar { return try pow(a, b) }
func positive(a: Scalar) throws -> Scalar { return a }
func negative(a: Scalar) throws -> Scalar { return try -a }
func add(a: Scalar, b: Scalar) throws -> Scalar { return try a + b }
func subtract(a: Scalar, b: Scalar) throws -> Scalar { return try a - b }
func multiply(a: Scalar, b: Scalar) throws -> Scalar { return try a * b }
func divide(a: Scalar, b: Scalar) throws -> Scalar { return try a / b }
func div(a: Double, b: Double) throws -> Double { return Double(a / b) }
func mod(a: Double, b: Double) throws -> Double { return a.truncatingRemainder(dividingBy: b) }

// math comparison

// signature: isEqualTo(a: primitive(double), b: primitive(double)) returning primitive(boolean)

func isLessThan(a: Double, b: Double) -> Bool { return a < b }
func isLessThanOrEqualTo(a: Double, b: Double) -> Bool { return a <= b }
func isEqualTo(a: Double, b: Double) -> Bool { return a == b }
func isNotEqualTo(a: Double, b: Double) -> Bool { return a != b }
func isGreaterThan(a: Double, b: Double) -> Bool { return a > b }
func isGreaterThanOrEqualTo(a: Double, b: Double) -> Bool { return a >= b }

// Boolean logic
func NOT(a: Bool) -> Bool { return !a }
func AND(a: Bool, b: Bool) -> Bool { return a && b }
func  OR(a: Bool, b: Bool) -> Bool { return a || b }
func XOR(a: Bool, b: Bool) -> Bool { return a && !b || !a && b }

