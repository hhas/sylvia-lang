//
//  lexer.swift
//

import Foundation


typealias Token = (type: TokenType, value: String) // TO DO: consider storing matched string/operator definition as part of enum



extension CharacterSet { // convenience extension, allows CharacterSet instances to be matched directly in switch cases
    
    static func ~= (a: CharacterSet, b: Unicode.Scalar) -> Bool {
        return a.contains(b)
    }
    static func ~= (a: CharacterSet, c: Character) -> Bool {
        guard let b = c.unicodeScalars.first else { return false } // TO DO: this needs to return false if character contains >1 code point
        return a ~= b
    }
}


// define the language's base punctuation (keeping this separate to other syntax)


enum TokenType { // TO DO: should this be named Token and hold parsed strings (plus formatting flags, operator definitions, etc where applicable)? what about layout hinting, so pretty printer can output normalized (correctly indented, regularly spaced) code while still preserving/improving certain aspects of user's code layout (e.g. explicit line wraps within lists)
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
    
    // what about a line continuation symbol, e.g. "…"? or is line-wrapping lists [] and parens () sufficient to cover common use-cases? (note: don't use backslashes for line continuations, as they're already used as escape modifier in text literals, and making them illegal syntax everywhere else makes it easier for line tokenizer to deduce whether double-quote marks indicate start or end of a text literal)
    
    // TO DO: tokenize everything else by Unicode categories
    
    // everything else: numbers, operators, identifiers (variable/command names; any word that isn't defined as an operator, basically), unparseable text (note: one reason for deferring number matching is that it allows library-defined weights and measures, e.g. `4mm`, `1.5kg`) // TO DO: the lexer will look up library-defined operator tables to decompose interstitial text
    
    // eventually; source code should be able to contain almost any legal Unicode character, but for now let's KISS and just use a convenient subset of characters for which CharacterSet already provides predefined constants
    
    case identifier(value: String, isQuoted: Bool) // .letters
    case number(value: String)     // .decimal // TO DO: this needs to support +/-, decimal point, and exponent notation (what about accepting `.1` as shorthand for `0.1`? should probably disallow `1.` as a syntax error though; note that JS & Python permit both, whereas Swift rejects both; note that if we do accept them, the pretty printer should always canonify them)
    
    
    
    case `operator`(value: String, prefix: OperatorDefinition?, infix: OperatorDefinition?)
    
    case whitespace
    
    case symbol     // any symbols that are are not recognized as operators // TO DO: or just use .unknown?
    
    case unknown // any characters that are not otherwise recognized
    
    case illegal // TO DO: need to decide how invalid unicode is handled (see also CharacterSet.illegalCharacters)
    
    
    
    // Q. any situations where whitespace needs to be known? (e.g. parser should be able to reduce `- 3` [.symbol.number] to `-3` [Value]); what's easiest when reading unbalanced lines
    
    // TO DO: what chars should be disallowed? (e.g. most control chars, invisibles, hairline spaces; how should spoofable characters be treated, both in source code and raw input sanitizing? [Q. what characters are known to be spoofable?] unicode paragraph/line chars should be normalized as LF, CRLF and CR should be normalized as LF; use tabs for indentation [pretty printer should always ensure consistent indents]; control chars, etc within text literals should be pretty printed as character escapes; Q. how to avoid executing scripts containing problem characters until they've been put right?)
    
    // Q. how should pretty printer, input sanitizers handle normalization forms?
    
    // TO DO: bidirectional text support (this'll require proper handling of RTL/LTR markers, especially when mixing Arabic/Hebrew with standard Latin punctuation and library-defined operator symbols)
    
    // TO DO: how best to implement auto-translation of identifiers? (TBH, this is probably something that should only be done at editor level as an assist to users; code as typed should remain canonical, and any on-the-fly pidgin auto-translations done in structure editor only [since translations are neither guaranteed to roundtrip or remain constant over time])
    
    // TO DO: need a set of syntax rules regarding placement of annotations, e.g. `1 «…» +2` is legal in many languages (e.g. `1 /*…*/ +2` in JS)
    
}



let identifierCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
let digitCharacters = CharacterSet.decimalDigits // lexer will match decimal and exponent notations itself (note that a leading +/- will be tokenized as prefix/infix operator; it's up to parser to match unary +/- .operator followed by .number and reduce it to a signed number value)

let signedIntegerCharacters = digitCharacters.union(CharacterSet(charactersIn: "+-")) // TO DO: decide exactly what sign glyphs to include here (be aware that these characters are also in symbolCharacters as they can also be used as arithmetic operators)
let identifierAdditionalCharacters = identifierCharacters.union(digitCharacters)
let symbolCharacters = CharacterSet.symbols.union(CharacterSet.punctuationCharacters)
let linebreakCharacters = CharacterSet.newlines
let whitespaceCharacters = CharacterSet.whitespaces





class Lexer {
    
    // Punctuation tokens (these are hardcoded and non-overrideable)
    
    // quoted text/name literals
    let quoteDelimiters: [Character:TokenType] = [
        "\"": .quotedText,
        "“": .quotedText,
        "”": .quotedText,
        "'": .quotedIdentifier,
        "‘": .quotedIdentifier,
        "’": .quotedIdentifier,
        "«": .annotationLiteral,
        "»": .annotationLiteralEnd,
        ]
    
    // collection literal/expression group delimiters, and separators
    let punctuation: [Character:TokenType] = [
        "{": .blockLiteral, // while parens could be used for blocks too (lexical context will determine how/when they're evaluated), we're using conservative C-like syntax for familiarity, and using parens for argument/parameter lists and overriding operator precedence only (this leaves us without a literal record [struct] syntax, but we can do without a record type for this exercise)
        "}": .blockLiteralEnd,
        "(": .groupLiteral,
        ")": .groupLiteralEnd,
        "[": .listLiteral,
        "]": .listLiteralEnd,
        ",": .itemSeparator,
        ]
    
    let decimalSeparator: Character = "."
    let exponentSeparators: Set<Character> = ["e", "E"]
    
    
    // TO DO: any benefit to using CharacterSet([Unicode.Scalar])? (e.g. SubString provides Scalar view)
    private(set) lazy var reservedCharacters = Set(quoteDelimiters.keys).union(Set(punctuation.keys))
    
    
    // TO DO: word-based operators (e.g. `and`, `of`) must be bounded by non-word characters; symbol-based operators can be bounded by anything
    
    let code: String
    let operatorRegistry: OperatorRegistry
    private(set) var index: String.Index // cursor position; external code can use this to get current position in order to backtrack to it later, e.g. when identifying operator names by longest match (e.g. `!`, `!=`, `!==`)
    
    init(code: String, operatorRegistry: OperatorRegistry = OperatorRegistry()) {
        self.code = code
        self.operatorRegistry = operatorRegistry
        self.index = code.startIndex
    }
    
    func peek() -> Character? {
        return self.index < self.code.endIndex ? self.code[self.index] : nil
    }
    
    func peek() -> Unicode.Scalar? {
        return self.peek()?.unicodeScalars.first
    }
    
    func next() -> Character? {
        if self.index < self.code.endIndex {
            let c = self.code[self.index]
            self.index = self.code.index(after: self.index)
            return c
        } else {
            return nil
        }
    }
    
    func backtrack(to index: String.Index? = nil) {
        if let i = index {
            self.index = i
        } else {
            self.index = self.code.index(before: self.index)
        }
    }
    
    func tokenize() -> [Token] { // note: tokenization should never fail; any issues should be added to token stream for parsers to worry about // TO DO: ensure original lines of source code can be reconstructed from token stream (that will allow ambiguous quoting in per-line reading to be resolved downstream)
        if self.code == "" { return [] }
        var result = [Token]()
        var token: Token = (.startOfCode, "")
        while let c = self.next() {
            //print("'\(c)'")
            // push previous token onto result list
            result.append(token)
            if let t = self.punctuation[c] {
                token = (t, String(c))
            } else if let t = self.quoteDelimiters[c] {
                
                // TO DO: see above notes re. single-line lexing, where it's impossible for lexer to know if cursor is inside or outside literal text/annotation quotes at any time (one possibility is to collect two outputs: a raw token stream where everything is broken down to tokens without regard to quotedness, and a lookup list of every chunk of text found between quotes [the latter being faster than reconstituting quoted content from token runs; capturing the substring ranges into the original code string would also do])
                
                // TO DO: this needs more work to support per-line reading, as non-annotation quote marks are inherently unbalanced so it's impossible to tell from `c` alone if indicates the start or end a text/identifier literal (it is possible to guess likehood of being inside/outside a text literal by examing “”‘’ quotes, as while those can't be trusted [as users aren't guaranteed to type them correctly] they are more likely to be right than wrong [particularly when pretty printed], and by looking for backslash escapes [`\"`, `\\`, `\n`, etc] which are known only to appear inside text literals)
                token = (t, "")
                // TO DO: how to handle t==.annotationLiteralEnd? in per-line reading, that implies preceding text is all within an annotation, in which case capture both preceding token array and string as an 'either-or' token (since it's impossible to know at Line level if it's the tail end of an annotation started on a previous line or a misplaced '»' that should be treated as a typo, i.e. syntax error)
                switch t {
                case .annotationLiteral:
                    // TO DO: for now, nested `«` and `»` must be balanced within annotations; how practical to allow escaping? (need to be wary of using backslash escapes, as we don't users having to type double backslashes everywhere; simplest might be to use double «« and »», taking care to disallow nested annotations from appearing immediately at start or end of another, e.g. `« «…» »` and `« «« »` would be legal, `««…»»` would not be legal unless within another annotation, in which case it's treated as escaped, e.g. `«a««b»»c»` would produce an Annotation containing the content string "a«b»c"; TBH, it all really depends on whether we want nested annotations to themselves be annotations, or simply treat top-level annotations as flat text; e.g. one advantage of live annotations that they can be used within user documentation text as tags, e.g. `«content=copyrightMessage()»` for substitution, `«level=advanced»` for hiding portions of documentation not relevant to beginners)
                    token.value.append("«")
                    var depth = 1
                    while let c = self.next(), depth > 0 {
                        token.value.append(c)
                        switch c {
                        case "«": depth += 1
                        case "»": depth -= 1
                        default: ()
                        }
                    }
                    // TO DO: 'expected end of annotation but found end of code' error if depth > 0 (bearing in mind that unbalanced block & quote delimiters will be normal in per-line parsing; solution might be to add before and after tally cases to TokenType so that imbalances are passed on to parser [think double-entry bookkeeping, where each tokenized line is a ledger and the parser's job is to perform a trial balance; once everything balances it can output the final AST])
                    token.value.append("»")
                default:
                    while let c = self.next(), self.quoteDelimiters[c] == nil { // TO DO: backslash escapes (initially for \", \n, \t; later for \u0000; eventually for \(…) interpolation too [e.g. convert text literal to a stdlib command]) // TO DO: normalize linebreak characters as LF; how best to treat invisibles, control chars? (best to reject invisible chars, by requiring backslash escapes/converting invisibles to escapes in editing mode)
                        token.value.append(c)
                    }
                }
            } else { // TO DO: this won't handle characters composed of >1 code point
                switch c {
                case identifierCharacters: // TO DO: also accept digits after first char
                    var chars = String(c)
                    while let p: Unicode.Scalar = self.peek(), identifierAdditionalCharacters.contains(p) {
                        chars.append(self.next()!)
                    }
                    let name = String(chars)
                    let (prefixOperator, infixOperator) = self.operatorRegistry.matchWord(name)
                    if prefixOperator == nil && infixOperator == nil {
                        token = (.identifier(value: name, isQuoted: false), name)
                    } else {
                        token = (.operator(value: name, prefix: prefixOperator, infix: infixOperator), name)
                    }
                // TO DO: need to match [case-insensitively] against word operators table; if found, it's an .operator; if not, it's an .identifier (note: OperatorRegistry may return prefix and/or infix operator descriptions)
                case symbolCharacters:
                    
                    // TO DO: need to do longest match against symbol operators; if found, it's an .operator; if not, it's an .unknown
                    self.backtrack()
                    let (prefixOperator, infixOperator) = self.operatorRegistry.matchSymbol(self)
                    if prefixOperator == nil && infixOperator == nil {
                        token = (.symbol, String(self.next()!))
                    } else {
                        let name = prefixOperator?.name ?? infixOperator!.name
                        token = (.operator(value: name, prefix: prefixOperator, infix: infixOperator), name)
                    }
                    
                case digitCharacters: // TO DO: also match +/- for signed numbers (backtracking if not followed by digit); this will only be invoked if std math operators aren't loaded (e.g. pure data structure parsing)
                    // note: assuming operator tables are loaded, leading +/- will be matched as prefix operator and left for parser to optimize away; it would be better to match operators before digits so that lexer can be used to read data only
                    token = (.number(value: String(c)), String(c))
                    while let p: Unicode.Scalar = self.peek(), digitCharacters.contains(p) {
                        token.value.append(self.next()!)
                    }
                    // TO DO: fraction, exponent; 0x… hexadecimal
                    if self.peek() == decimalSeparator {
                        
                    }
                    if let c: Character = self.peek(), exponentSeparators.contains(c) {
                        
                    }
                case linebreakCharacters:
                    token = (.lineBreak, "\n")
                case whitespaceCharacters:
                    token = (.whitespace, String(c))
                    while let p: Unicode.Scalar = self.peek(), whitespaceCharacters.contains(p) {
                        token.value.append(self.next()!)
                    }
                default:
                    token = (.unknown, String(c))
                }
            }
        }
        result.append(token)
        result.append((.endOfCode, ""))
        return result
    }
}



enum OperatorNameType {
    case word
    case symbol
    case invalid
    
    init(_ name: String) {
        if let p = name.first?.unicodeScalars.first { // TO DO: as elsewhere, doesn't support multiple glyphs
            let chars = CharacterSet(charactersIn: name)
            if identifierCharacters.contains(p) && chars.subtracting(identifierAdditionalCharacters).isEmpty {
                self = .word
            } else if chars.subtracting(symbolCharacters).isEmpty {
                self = .symbol
            } else {
                self = .invalid
            }
        } else {
            self = .invalid
        }
    }
}


