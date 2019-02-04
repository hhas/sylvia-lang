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
//      'to' «: name as primitive(text)» «: parameters as primitive(list of argument)» «optional: 'returning' «: returnType as coercion» » «: body as block»
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


// convenience initializers for constructing the underlying commands // TO DO: what about self.annotating? what about preserving operatorName?

extension Command {
    
    convenience init(_ operatorDefinition: OperatorDefinition) {
        self.init(operatorDefinition.handlerName ?? operatorDefinition.name.name, [])
    }
    convenience init(_ operatorDefinition: OperatorDefinition, leftOperand: Value) {
        self.init(operatorDefinition.handlerName ?? operatorDefinition.name.name, [leftOperand])
    }
    convenience init(_ operatorDefinition: OperatorDefinition, leftOperand: Value, rightOperand: Value) {
        self.init(operatorDefinition.handlerName ?? operatorDefinition.name.name, [leftOperand, rightOperand])
    }
    convenience init(_ operatorDefinition: OperatorDefinition, rightOperand: Value) {
        self.init(operatorDefinition.handlerName ?? operatorDefinition.name.name, [rightOperand])
    }
}


// operator parsing functions (e.g. arithmetic, comparision, coercion, concatenation operators)

func parseAtomOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.advance()
    return Command(definition)
}
func parsePrefixOperator(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.advance()
    return Command(definition, leftOperand: try parser.parseExpression(definition.precedence))
}
func parseInfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.advance()
    return Command(definition, leftOperand: leftExpr, rightOperand: try parser.parseExpression(definition.precedence))
}
func parseRightInfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.advance()
    return Command(definition, leftOperand: leftExpr, rightOperand: try parser.parseExpression(definition.precedence-1))
}
func parsePostfixOperator(_ parser: Parser, leftExpr: Value, operatorName: String, definition: OperatorDefinition) throws -> Value {
    parser.advance()
    return Command(definition, rightOperand: leftExpr)
}



// TO DO: assignment operator (this will map to `store` command; might want to think about naming conventions though)


// TO DO: how best to parse handler definitions? `'to' NAME '(' [PARAM [',' PARAM]*]? ')' ['returning' TYPE] BLOCK`; is it worth making `returning` an infix operator in its own right? (if not, bear in mind it will appear in token stream as an .identifer)



// parse prefix operator with two right-hand operands: an expression and a block (e.g. `if EXPR BLOCK`)

func parsePostfixOperatorWithBlock(_ parser: Parser, operatorName: String, definition: OperatorDefinition) throws -> Value {
    // TO DO: what about expr coercion? e.g. in loops and conditionals, any expression that evaluates to true/false (with some exceptions, e.g. blocks should probably be disallowed, and silliness such as `if to HANDLER(){} {}` would ideally be discouraged); Q. what about insisting that opening brace appear on same line as [end of] EXPR - e.g. `if EXPR { LF …` but not `if EXPR LF {…` - in order to reduce room for ambiguous-looking code [see .linebreak discussion in general])
    parser.advance()
    let expr = try parser.parseExpression(definition.precedence)
    // 2nd operand is required to be a block to avoid syntactic ambiguity (including token patterns such as `WORD WORD` that per-line parsing can use to distinguish probable quoted text from probable code)
    parser.advance()
    let action = try parser.parseExpression(definition.precedence) // T|O DO: implement Parser.parseIfBlock, which returns nil if non-block is found, giving caller choice of what to do next [this is preferable to throwing SyntaxError, as errors occuring while parsing contents of block aren't trivially distinguished from error raised when expected block isn't found])
    // TO DO: how best to support 'code' formatting style in error messages? (one option is to treat all error strings as Markdown, and format/escape interpolated values when inserting; may be best to leave this until native 'tagged' text interpolation is implemented, then allow that to be used when constructing error messages in both native and Swift code)
    if !(action is Block) { throw SyntaxError("Expected a block after `\(operatorName) \(expr)`, but found: \(action)") } // TO DO: long code needs elided for readability
    let command = Command(definition, leftOperand: expr, rightOperand: action)
    command.annotations[operatorAnnotation] = (operatorName: operatorName, definition: definition) // TO DO: error messages should render this Command using its operator syntax
    return command
}
