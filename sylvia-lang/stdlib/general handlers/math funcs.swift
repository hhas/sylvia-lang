//
//  stdlib/handlers/math.swift
//

import Darwin


// TO DO: should math funcs ever throw, or should outOfRange/divideByZero be captured by Scalar?
//
// TO DO: check how Int/Double signals out-of-range

// TO DO: use Icon-style behavior for comparison operators? this'd allow comparison operations to be chained, e.g. `0 < x <= 10` (on success, returns right-hand operand as-is [this includes empty values]; on failure, returns 'noComparison' flag which causes subequent comparisons to return noComparison as well)


// signature: add(left: primitive(double), right: primitive(double)) returning primitive(double)
// requirements: throws // TO DO: should `throws` be declared as part of return coercion: `errorOr(RETURNTYPE)`? (optionally including list of error coercion[s] where known?)

func exponent(left: Scalar, right: Scalar) throws -> Scalar { return try pow(left, right) }
func positive(left: Scalar) throws -> Scalar { return left }
func negative(left: Scalar) throws -> Scalar { return try -left }
func add(left: Scalar, right: Scalar) throws -> Scalar { return try left + right }
func subtract(left: Scalar, right: Scalar) throws -> Scalar { return try left - right }
func multiply(left: Scalar, right: Scalar) throws -> Scalar { return try left * right }
func divide(left: Scalar, right: Scalar) throws -> Scalar { return try left / right }
func div(left: Double, right: Double) throws -> Double { return Double(left / right) }
func mod(left: Double, right: Double) throws -> Double { return left.truncatingRemainder(dividingBy: right) }

// math comparison

// signature: isEqualTo(left: primitive(double), right: primitive(double)) returning primitive(boolean)

func isLessThan(left: Double, right: Double) -> Bool { return left < right }
func isLessThanOrEqualTo(left: Double, right: Double) -> Bool { return left <= right }
func isEqualTo(left: Double, right: Double) -> Bool { return left == right }
func isNotEqualTo(left: Double, right: Double) -> Bool { return left != right }
func isGreaterThan(left: Double, right: Double) -> Bool { return left > right }
func isGreaterThanOrEqualTo(left: Double, right: Double) -> Bool { return left >= right }

// Boolean logic
func NOT(right: Bool) -> Bool { return !right }
func AND(left: Bool, right: Bool) -> Bool { return left && right }
func  OR(left: Bool, right: Bool) -> Bool { return left || right }
func XOR(left: Bool, right: Bool) -> Bool { return left && !right || !left && right }

