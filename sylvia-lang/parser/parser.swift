//
//  parser.swift
//

import Foundation



enum ParseFunc {
    
    typealias Prefix = (_ parser: Parser, _ operatorName: String, _ precedence: Int) throws -> Value
    typealias Infix  = (_ parser: Parser, _ leftExpr: Value, _ operatorName: String, _ precedence: Int) throws -> Value
    
    case atom(Prefix)
    case prefix(Prefix)
    case infix(Infix)
    case postfix(Infix)
}





class Parser {
    
}
