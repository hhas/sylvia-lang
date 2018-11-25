//
//  parsefunc.swift
//
//
// custom parsing functions for standard atom, prefix, infix, postfix operators


// TO DO: worth revising entire OperatorDefinition to be enum instead of just parseFunc attribute? would save extra layer of dereferencing + sanity-checking in parser (think the idea behind current arrangement was to avoid unnecessary duplication of other, identical attributes, but those could be grouped into separate tuple, e.g. `.infix(OperatorInfo, InfixParseFunc))`, where `typealias OperatorInfo = (name:precedence:aliases:)`



// TO DO: custom parsefuncs need to be accompanied by corresponding formatfuncs for use by pretty printer (currently AST renders itself to crude pure-command representation for development purposes only)
//
// TO DO: eventually operator syntaxes should be described using a simple substitution pattern that covers both parsing and formatting requirements, e.g.:
//
//      «:a» '+' «:b»
//
//      'to' «: name as primitive(text)» «: parameters as primitive(list of argument)» «optional: 'returning' «: returnType as type» » «: body as block»
//
// Eventually this syntax could be used by library code-generator to look up names of existing parse+format functions, or generate custom functions if not found


enum ParseFunc { // holds an operator parsing function for use by Pratt parser; used in OperatorDefinition
    
    // function signatures
    typealias Prefix = (_ parser: Parser, _ operatorName: String, _ definition: OperatorDefinition) throws -> Value
    typealias Infix  = (_ parser: Parser, _ leftExpr: Value, _ operatorName: String, _ definition: OperatorDefinition) throws -> Value
    
    case atom(Prefix) // TO DO: non-maskable constants (e.g. `nothing`) may be defined as .atom operators, allowing parser to eliminate need for environment lookups by inserting the value directly into AST (caveat: operator-sugared code MUST evaluate exactly the same as command-only code, so any such parse-time substitutions/optimizations must be applied with care)
    case prefix(Prefix)
    case infix(Infix)
    case postfix(Infix)
    
    // TO DO: formatting funcs; if omitted, use default
    
    // TO DO: this won't work unless replacing ParseFunc with OperatorDefinition
    /*
    func format(_ operands: [Value]) -> String {
        switch self {
        case .atom(_): return self.name
        case .prefix(_): return "\(self.name) \(operands[0])"
        case .infix(_): return "\(self.operands[0]) \(name) \(operands[1])"
        case .postfix(_): return "\(self.operands[0]) \(name)"
        }
    }
    */
}


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

func parseAtomOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.next()
    return Command(definition.handlerName ?? operatorName)
}
func parsePrefixOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.next()
    return Command(definition.handlerName ?? operatorName, leftOperand: try parser.parseExpression(definition.precedence))
}
func parseInfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.next()
    return Command(definition.handlerName ?? operatorName, leftOperand: leftExpr, rightOperand: try parser.parseExpression(definition.precedence))
}
func parseRightInfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.next()
    return Command(definition.handlerName ?? operatorName, leftOperand: leftExpr, rightOperand: try parser.parseExpression(definition.precedence-1))
}
func parsePostfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.next()
    return Command(definition.handlerName ?? operatorName, rightOperand: leftExpr)
}



// TO DO: assignment operator (this will map to `store` command; might want to think about naming conventions though)


// TO DO: how best to parse handler definitions? `'to' NAME '(' [PARAM [',' PARAM]*]? ')' ['returning' TYPE] BLOCK`; is it worth making `returning` an infix operator in its own right? (if not, bear in mind it will appear in token stream as an .identifer)
