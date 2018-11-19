//
//  parsefunc.swift
//
//
// custom parsing functions for standard atom, prefix, infix, postfix operators


// convenience initializers for constructing the underlying commands

extension Command {
    
    convenience init(_ operatorName: String) {
        self.init(operatorName, [])
    }
    convenience init(_ operatorName: String, leftOperand: Value) {
        self.init(operatorName, [leftOperand])
    }
    convenience init(_ operatorName: String, leftOperand: Value, rightOperand: Value) {
        self.init(operatorName, [leftOperand, rightOperand])
    }
    convenience init(_ operatorName: String, rightOperand: Value) {
        self.init(operatorName, [rightOperand])
    }
}


// operator parsing functions (e.g. arithmetic, comparision, coercion, concatenation operators)

func parseAtomOperator(_ parser: Parser, operatorName: String, precedence: Int) throws -> Value {
    return Command(operatorName)
}
func parsePrefixOperator(_ parser: Parser, operatorName: String, precedence: Int) throws -> Value {
    return Command(operatorName, leftOperand: try parser.parseExpression(precedence))
}
func parseInfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, precedence: Int) throws -> Value {
    return Command(operatorName, leftOperand: leftExpr, rightOperand: try parser.parseExpression(precedence))
}
func parseRightInfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, precedence: Int) throws -> Value {
    return Command(operatorName, leftOperand: leftExpr, rightOperand: try parser.parseExpression(precedence-1))
}
func parsePostfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, precedence: Int) throws -> Value {
    return Command(operatorName, rightOperand: leftExpr)
}



// TO DO: assignment operator (this will map to `store` command; might want to think about naming conventions though)


// TO DO: how best to parse handler definitions? `'to' NAME '(' [PARAM [',' PARAM]*]? ')' ['returning' TYPE] BLOCK`; is it worth making `returning` an infix operator in its own right? (if not, bear in mind it will appear in token stream as an .identifer)
