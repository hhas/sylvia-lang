//
//  lexer.swift
//

import Foundation

typealias OperatorName = String

typealias OperatorDefinition = (name: OperatorName, precedence: Int, parseFunc: ParseFunc, aliases: [OperatorName])

typealias PrefixOperatorDefinition = (name: OperatorName, precedence: Int, parseFunc: ParseFunc.Prefix, aliases: [OperatorName])
typealias InfixOperatorDefinition  = (name: OperatorName, precedence: Int, parseFunc: ParseFunc.Infix,  aliases: [OperatorName])



typealias OperatorTable = [String: OperatorDefinition] // keys are operator names, including aliases


// define the language's base punctuation (keeping this separate to other syntax)

// Q. how should string interpolation work? this partly depends on choice of escape syntax: backslashes are flexible but always flummox newbies; doubled-quotes are simpler but can't escape anything but themselves (e.g. kiwi uses doubled quotes and interpolates adjacent text and tags - “""Hello, ”{name}“!""” - but that is less likely to work effectively here as it's hard for parser to determine if mixed text and identifiers are intentional or syntax errors); another possibility is to call `format` method on text values (c.f. Python) passing the values to interpolate, but that tends to degenerate into complicated, unintuitive string-formatting mini-languages (c.f. Python); an approach kiwi was careful to avoid. Might be simplest just to use concatenation operator and rely on coercion to concatenate atomic types into a string, e.g. "Hello, " & name & "!" (lists will need to be pre-flattened using an explicit `join()`/`code()`/etc command, of course)

enum TokenType { // TO DO: should this be named Token and hold parsed strings (and, in case of operators, fixity, precedence, and associativity)? what about layout hinting, so pretty printer can output normalized (correctly indented, regularly spaced) code while still preserving/improving certain aspects of user's code layout (e.g. explicit line wraps within lists)
    case startOfCode
    case endOfCode
    // Punctuation
    case quotedText             // atomic; the lexer automatically reads everything between `"` and corresponding `"`, including `\CHARACTER` escapes (curly quotes are also accepted, and are used as standard when pretty printing text literals)
    case quotedIdentifier       // atomic; the lexer automatically reads everything between `'` and corresponding `'`; this allows identifier names that are otherwise masked by operator names to be used in quoted form (e.g. `'AND'(a,b)` = `a AND b`)
    case annotationLiteral      // atomic; the lexer automatically reads everything between `«` and corresponding `»`, including nested annotations; Q. how to use annotations for docstrings, comments, TODO, TOFIX, metainfo, etc?
    case annotationLiteralEnd   // this will only appear in token stream if not balanced by an earlier .annotationLiteral
    case listLiteral            // "[" an ordered collection (array)
    case listLiteralEnd         // "]"
    case blockLiteral           // "{"
    case blockLiteralEnd        // "}"
    case groupLiteral           // "("
    case groupLiteralEnd        // ")"
    case itemSeparator          // ","
    case lineBreak              // "\n", etc // CharacterSet.newLines
    
    // what about #WORD and @WORD (hashtags and 'super global' identifiers)?
    
    // what about EXPR? and EXPR! as debugging/introspection modifiers?
    
    // TO DO: tokenize everything else by Unicode categories
    
    // everything else: numbers, operators, identifiers (variable/command names; any word that isn't defined as an operator, basically), unparseable text (note: one reason for deferring number matching is that it allows library-defined weights and measures, e.g. `4mm`, `1.5kg`) // TO DO: the lexer will look up library-defined operator tables to decompose interstitial text
    
    // eventually; source code should be able to contain almost any legal Unicode character, but for now let's KISS and just use a convenient subset of characters for which CharacterSet already provides predefined constants
    
    case word   // .letters
    case number // .decimal
    case symbol // .symbols
    
    // Q. any situations where whitespace needs to be known?
    
    // TO DO: what chars should be disallowed? (e.g. most control chars, invisibles, hairline spaces; how should spoofable characters be treated, both in source code and raw input sanitizing? [Q. what characters are known to be spoofable?] unicode paragraph/line chars should be normalized as LF, CRLF and CR should be normalized as LF; use tabs for indentation [pretty printer should always ensure consistent indents]; control chars, etc within text literals should be pretty printed as character escapes; Q. how to avoid executing scripts containing problem characters until they've been put right?)
    
    // Q. how should pretty printer, input sanitizers handle normalization forms?
    
    // TO DO: bidirectional text support (this'll require proper handling of RTL/LTR markers, especially when mixing Arabic/Hebrew with standard Latin punctuation and library-defined operator symbols)
    
    // TO DO: how best to implement auto-translation of identifiers? (TBH, this is probably something that should only be done at editor level as an assist to users; code as typed should remain canonical, and any on-the-fly pidgin auto-translations done in structure editor only [since translations are neither guaranteed to roundtrip or remain constant over time])
    
}




let wordCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
let numberCharacters = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
let symbolCharacters = CharacterSet.symbols
let linebreakCharacters = CharacterSet.newlines
let whitespaceCharacters = CharacterSet.whitespaces




class Lexer {
    
    // Punctuation tokens (these are hardcoded and non-overrideable)
    
    // quoted text/name literals
    static let quoteDelimiters: [Character:TokenType] = [
        "\"": .quotedText,
        "“": .quotedText,
        "”": .quotedText,
        "'": .quotedIdentifier,
        "‘": .quotedIdentifier,
        "’": .quotedIdentifier,
        ]
    
    // annotation literals
    static let annotationDelimiters: [Character:Int] = [ // when consuming annotations, only '«' and '»' are considered
        "«": 1,
        "»": -1,
        ]
    
    // collection literal/expression group delimiters, and separators
    static let punctuation: [Character:TokenType] = [
        "[": .listLiteral,
        "]": .listLiteralEnd,
        "{": .blockLiteral, // while parens could be used for blocks too (lexical context will determine how/when they're evaluated), we're using conservative C-like syntax for familiarity, and using parens for argument/parameter lists and overriding operator precedence only (this leaves us without a literal record [struct] syntax, but we can do without a record type for this exercise)
        "}": .blockLiteralEnd,
        "(": .groupLiteral,
        ")": .groupLiteralEnd,
        ",": .itemSeparator,
        ]
    
    // TO DO: any benefit to using CharacterSet([Unicode.Scalar])? (e.g. SubString provides Scalar view)
    static let reservedCharacters = Set(quoteDelimiters.keys).union(Set(annotationDelimiters.keys)).union(Set(punctuation.keys))
    
    // TO DO: word-based operators (e.g. `and`, `of`) must be bounded by non-word characters; symbol-based operators can be bounded by anything
    
    init(code: String, operatorTable: OperatorTable) {
        
    }
    
}


