//
//  token.swift
//


// TO DO: decide on `#` vs `\` for Symbol prefix; currently `#SYMBOL`, but advantage of `\SYMBOL` is that is frees up `#` for use in hashtags (assuming that symbols aren't already conceptually close enough to hashtags to cover both roles?)

// TO DO: FIX: problem with lexer binding positive/negative symbol to subsequent numeric literal: `1 - 1` -> `“1” - “1”`, but `1-1` -> `“1” LF “-1”` which is very wrong; suspect this may have been a bad idea and need to move this decision back to parser, with caveat that it will probably need special-cased when it appear in numeric argument of a parens-less `IDENTIFIER ARGUMENT` command, e.g. parsing `item -2 of LIST` can deduce intent by checking if whitespace was present on one/both/neither side of the '-'


import Foundation



extension CharacterSet { // convenience extension, allows CharacterSet instances to be matched directly by 'switch' cases
    
    static func ~= (a: CharacterSet, b: Unicode.Scalar) -> Bool {
        return a.contains(b)
    }
    static func ~= (a: CharacterSet, c: Character) -> Bool {
        guard let b = c.unicodeScalars.first, c.unicodeScalars.count == 1 else { return false }
        return a ~= b
    }
}


/******************************************************************************/
// character sets for token types

// TO DO: messing with Unicode.Scalar just to please CharacterSet is grotty and a pain (since Lexer should only care about Characters); how easy/wise to convert CharacterSets to Set<Character>?

// the following should probably be public static constants on Lexer (some are used by sub-lexers such as OperatorRegistry.match… functions)

// punctuation (these are hardcoded and non-overrideable)

// quoted text/identifier literals
let quotedTextDelimiterCharacters = CharacterSet(charactersIn: "\"“”")
let quotedIdentifierDelimiterCharacters = CharacterSet(charactersIn: "'‘’")
let quotedTextEscapeCharacters = CharacterSet(charactersIn: "\\")

// annotation literals (comments, user documentation, TODOs, etc)
let annotationDelimiters = (start: "«", end: "»")
let annotationDelimiterCharacters = CharacterSet(charactersIn: annotationDelimiters.start)
let annotationDelimiterEndCharacters = CharacterSet(charactersIn: annotationDelimiters.end)

let quoteDelimiterCharacters = quotedTextDelimiterCharacters.union(quotedIdentifierDelimiterCharacters)
    .union(annotationDelimiterCharacters).union(annotationDelimiterEndCharacters)

let punctuationTokens: [Character:Token] = [
    "{": .blockLiteral, // while parens could be used for blocks too (lexical context will determine how/when they're evaluated), we're using conservative C-like syntax for familiarity, and using parens for argument/parameter lists and overriding operator precedence only (this leaves us without a literal record [struct] syntax, but we can do without a record coercion for this exercise)
    "}": .blockLiteralEnd,
    "(": .groupLiteral,
    ")": .groupLiteralEnd,
    "[": .listLiteral,
    "]": .listLiteralEnd,
    ",": .itemSeparator,
    ":": .pairSeparator, // TO DO: implement ":" builtin for defining KEY:VALUE pairs (used in key-value list literals and argument/parameter lists to declare field labels; might also be used in blocks to declare name-value bindings)
    ";": .pipeSeparator, // TO DO: implement 'pipeline' symbol, allowing commands to be chained so that result of first command is passed as first arg to second command

    // TO DO: if using JS-ish syntax, use "." for .attributeSelector (note: this shouldn't stop us defining `of` operator as well, though need to think how they both bake down to Values; probably want a specific Expression subclass for this)
]

let punctuationCharacters = CharacterSet(punctuationTokens.keys.map { $0.unicodeScalars.first! })

// unquoted identifiers
// TO DO: identifier and operator names should be able to contain almost any legal Unicode character, but for now let's KISS and just use a convenient subset of characters for which CharacterSet already provides predefined constants, and treat any other characters [that aren't known punctuation chars] as .unknown
let identifierCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
let identifierAdditionalCharacters = identifierCharacters.union(digitCharacters)

let symbolLiteralPrefix = "#"
let symbolPrefixCharacters = CharacterSet(charactersIn: symbolLiteralPrefix)

// number literals
let numericSigns = Set(["+", "-"])
let signCharacters = CharacterSet(charactersIn: numericSigns.joined()) // TO DO: decide exactly what sign glyphs to include here (be aware that these characters are also in symbolicCharacters as they can also be used as arithmetic operators)
let digitCharacters = CharacterSet.decimalDigits // lexer will match decimal and exponent notations itself (note that when stdlib operators are loaded, any +/- symbols before number will be read as a separate .operator; it's up to parser to match unary +/- .operators followed by .number and reduce it to a signed number value for efficiency [note that in AppleScript, multiple +/- symbols before a number are collapsed down by pretty printer])
let decimalSeparators = CharacterSet(charactersIn: ".")
let hexadecimalCharacters = digitCharacters.union(CharacterSet(charactersIn: "AaBbCcDdEeFf"))
let hexadecimalSeparators = CharacterSet(charactersIn: "Xx")
let exponentSeparators = CharacterSet(charactersIn: "Ee")

// operators/unknown symbols
let symbolicCharacters = CharacterSet.symbols.union(CharacterSet.punctuationCharacters).subtracting(punctuationCharacters) // note: `+` and `-` appear in both signCharacters and symbolicCharacters as they are used both in numbers and as operators (lexer and parser will perform further analysis to figure out which)

// white space
let linebreakCharacters = CharacterSet.newlines
let whitespaceCharacters = CharacterSet.whitespaces

// characters which are guaranteed to terminate the preceding token (unless it's an operator/symbol token, as those have their own boundary rules)
let boundaryCharacters = linebreakCharacters.union(whitespaceCharacters).union(quoteDelimiterCharacters).union(punctuationCharacters).union(symbolicCharacters)


/******************************************************************************/
// TokenInfo


enum Token {
    
    case startOfCode
    case endOfCode
    
    // annotations
    case annotationLiteral(String)  // atomic; the lexer automatically reads everything between `«` and corresponding `»`, including nested annotations; Q. how to use annotations for docstrings, comments, TODO, TOFIX, change notes, metadata, etc? (probably use standard prefixes, e.g. `«?…»` might indicate user documentation, i.e. "help" [or should `«?` be used to indicate notes that appear in debug mode, given `?` operator is used to invoke interactive debug mode?], `«TODO:…»` is self-explanatory, etc); Q. how practical to attach change notes from code versioning system when pretty printing? (TBH, this sort of capability should probably be applied as map/filter/reduce operations between lexer and parser or parser and formatter, or handled by code editor)
    case annotationLiteralEnd       // this will only appear in token stream if not balanced by an earlier .annotationLiteral
    
    // block structures
    case listLiteral                // "[" an ordered collection (array)
    case listLiteralEnd             // "]"
    case blockLiteral               // "{"
    case blockLiteralEnd            // "}"
    case groupLiteral               // "("
    case groupLiteralEnd            // ")"
    
    // separators
    case itemSeparator              // ","
    case pairSeparator              // ":"
    case pipeSeparator              // ";"
    case lineBreak                  // "\n", etc // CharacterSet.newLines
    // TO DO: also allow ";" as expression separator? (TBH, period would be preferable, but not if it's already symbol for attribute selection)
    
    // literals
    case textLiteral(value: String)         // atomic; the lexer automatically reads everything between `"` and corresponding `"`, including `\CHARACTER` escapes (curly quotes are also accepted, and are used as standard when pretty printing text literals)
    case number(value: String, scalar: Scalar)     // .decimal // TO DO: readNumber should also output Int/Double/decimal/fixed point/etc representation (e.g. output Scalar enum rather than String, c.f. entoli's numeric-parser.swift); when implementing UnitTypeRegistry (MeasurementRegistry?) also decide if .measurement(Measurement) should be a distinct Token, or if .number should include a `unit:UnitType?` slot (TBH it's probably worth going the whole hog and having lexer delegate all number reading to dedicated module which can also be used elsewhere, e.g. by numeric coercions and parsing/formatting libraries)
    case symbolLiteral(value: String)
    
    // names
    case identifier(value: String, isQuoted: Bool) // .letters // atomic; the lexer automatically reads everything between `'` and corresponding `'`; this allows identifier names that are otherwise masked by operator names to be used in quoted form (e.g. `'AND'(a,b)` = `a AND b`)
    case operatorName(value: String, prefix: OperatorDefinition?, infix: OperatorDefinition?) // `value` contains operator's canonical name; should it be the name that appeared in source code? (issue is how to report syntax errors: the error message needs to show the name that appears in source code)
    
    // interstitials (i.e. everything that doesn't appear to be valid code)
    case whitespace(String)
    case unknown(description: String) // any characters that are not otherwise recognized // TO DO: this should also capture matched part, if any (e.g. number), and unknown part (e.g. unknown suffix), allowing tools to provide better assistance (each part might also have its own description text, e.g. for display in editor tooltips, and the whole lot can be automatically composed into complete error message)
    case illegal // TO DO: currently unused; decide how invalid unicode chars are handled (see also CharacterSet.illegalCharacters); for now, everything just gets stuffed into `unknown`
    
    
    var precedence: Int { // higher precedence binds more tightly // caution: precedence values must be even (odd values indicate right-associativity)
        switch self {
        case .annotationLiteral:                                    return 100000 // '«...»'
        case .operatorName(let definition):                         return definition.infix?.precedence ?? 0 // only infix/postfix ops are of relevance (atom/prefix ops do not take a left operand [i.e. leftExpr], so return 0 for those to finish the previous expression and start a new one)
        case .pipeSeparator:                                        return 4
        case .pairSeparator:                                        return 2
        case .listLiteralEnd, .blockLiteralEnd, .groupLiteralEnd:   return -2   // TO DO: what value? this smells
        case .itemSeparator:                                        return -4   // ','
        case .lineBreak:                                            return -100
        case .endOfCode:                                            return -10000
        default:                                                    return 0
        }
    }
    
    // TO DO: `var tokenDescription:String` that describes what each token is (for use in syntax error messages, GUI editor tooltips, etc)
}

// kludgy workaround for inability to parameterize both operands in `if case ENUM = VALUE`; used by Parser.readDelimitedValues()

// TO DO: put these into TokenInfo tuples along with corresponding "]"/")"/"}"/nil character for error reporting

func isEndOfList(_ token: Token) -> Bool {
    if case .listLiteralEnd = token { return true } else { return false }
}
func isEndOfGroup(_ token: Token) -> Bool {
    if case .groupLiteralEnd = token { return true } else { return false }
}
func isEndOfBlock(_ token: Token) -> Bool {
    if case .blockLiteralEnd = token { return true } else { return false }
}
func isEndOfCode(_ token: Token) -> Bool {
    if case .endOfCode = token { return true } else { return false }
}



/******************************************************************************/


struct TokenInfo: CustomDebugStringConvertible {
    let token: Token
    let start: String.Index
    let end: String.Index
    
    var debugDescription: String { return "\(self.start.encodedOffset)…\(self.end.encodedOffset) \(self.token)" }
    
    // TO DO: consider always using single-line Lexer, and store line number here as well
}

