//
//  lexer.swift
//

// TO DO: a quicker way to check quote and block balancing during code editing is to skip all characters except quote and block delimiters [and their associated escape sequences], which can be done with a very simple Scanner that pushes open delimiters onto a stack and pops them off again when the corresponding close delimiter is found

import Foundation


typealias Token = (type: TokenType, value: String) // TO DO: TokenType enums should contain the tokenized text (which may be slightly different to the original text fragment as the lexer starts to clean things up) plus any additional information the parser might need (e.g. custom parseFuncs); currently `value` contains the original text fragment but might be simpler just to capture substring range (we need the original code during single-line parsing so that the parser can choose which text ranges should appear inside quotes and which should appear outside, and swap if needed [since text literals and annotations can be multi-line, there's no way for a single line to know if its first character is part of code or within a larger quoted section without consulting preceding lines; and even then it may require intelligent guesswork when lexing a script during editing, as user adds/replaces/removes/rearranges parts of that script])



extension CharacterSet { // convenience extension, allows CharacterSet instances to be matched directly in switch cases
    
    static func ~= (a: CharacterSet, b: Unicode.Scalar) -> Bool {
        return a.contains(b)
    }
    static func ~= (a: CharacterSet, c: Character) -> Bool {
        guard let b = c.unicodeScalars.first else { return false } // TO DO: this needs to return false if character contains >1 code point
        return a ~= b
    }
}


// TO DO: messing with Unicode.Scalar just to please CharacterSet is grotty and a pain (since Lexer should only care about Characters); how easy/wise to convert CharacterSets to Set<Character>?

// the following should probably be public static constants on Lexer

// identifiers
let identifierCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
let identifierAdditionalCharacters = identifierCharacters.union(digitCharacters)

// number literals
let signCharacters = CharacterSet(charactersIn: "+-") // TO DO: decide exactly what sign glyphs to include here (be aware that these characters are also in symbolCharacters as they can also be used as arithmetic operators)
let digitCharacters = CharacterSet.decimalDigits // lexer will match decimal and exponent notations itself (note that a leading +/- will be tokenized as prefix/infix operator; it's up to parser to match unary +/- .operator followed by .number and reduce it to a signed number value)
let decimalSeparators = CharacterSet(charactersIn: ".")
let hexadecimalCharacters = digitCharacters.union(CharacterSet(charactersIn: "AaBbCcDdEeFf"))
let hexadecimalSeparators = CharacterSet(charactersIn: "Xx")
let exponentSeparators = CharacterSet(charactersIn: "Ee")

// operators/unknown symbols
let symbolCharacters = CharacterSet.symbols.union(CharacterSet.punctuationCharacters)

// white space
let linebreakCharacters = CharacterSet.newlines
let whitespaceCharacters = CharacterSet.whitespaces


// punctuation (these are hardcoded and non-overrideable)

// quoted text/name literals
let quoteDelimiterTokens: [Character:TokenType] = [
    "\"": .quotedText,
    "“": .quotedText,
    "”": .quotedText,
    "'": .quotedIdentifier,
    "‘": .quotedIdentifier,
    "’": .quotedIdentifier,
    "«": .annotationLiteral,
    "»": .annotationLiteralEnd,
]

let quoteDelimiterCharacters = CharacterSet(quoteDelimiterTokens.keys.map { $0.unicodeScalars.first! })

// collection literal/expression group delimiters, and separators
let punctuationTokens: [Character:TokenType] = [
    "{": .blockLiteral, // while parens could be used for blocks too (lexical context will determine how/when they're evaluated), we're using conservative C-like syntax for familiarity, and using parens for argument/parameter lists and overriding operator precedence only (this leaves us without a literal record [struct] syntax, but we can do without a record type for this exercise)
    "}": .blockLiteralEnd,
    "(": .groupLiteral,
    ")": .groupLiteralEnd,
    "[": .listLiteral,
    "]": .listLiteralEnd,
    ",": .itemSeparator,
]

let punctuationCharacters = CharacterSet(punctuationTokens.keys.map { $0.unicodeScalars.first! })

// characters which are guaranteed to terminate preceding (non-operator) token
let boundaryCharacters = linebreakCharacters.union(whitespaceCharacters).union(quoteDelimiterCharacters).union(punctuationCharacters).union(symbolCharacters)



// Token

enum TokenType { // TO DO: rename Token and hold parsed strings (plus formatting flags, operator definitions, etc where applicable); Q. what about layout hinting, so pretty printer can output normalized (correctly indented, regularly spaced) code while still preserving/improving certain aspects of user's code layout (e.g. explicit line wraps within long lists should always appear after item separator commas and before next item)
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




class Lexer {
    
    private let code: String
    private let operatorRegistry: OperatorRegistry?
    private(set) var index: String.Index // cursor position; external code can use this to get current position in order to backtrack to it later, e.g. when identifying operator names by longest match (e.g. `!`, `!=`, `!==`)
    
    // initializer takes source code plus optional operator lookup tables
    
    init(code: String, operatorRegistry: OperatorRegistry? = nil) {
        self.code = code
        self.operatorRegistry = operatorRegistry
        self.index = code.startIndex
    }
    
    // TO DO: messy API
    
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
    
    func next(ifIn characterSet: CharacterSet) -> Character? {
        if let p: Unicode.Scalar = self.peek(), characterSet.contains(p) {
            return self.next()
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
    
    //
    
    // read text/number literals
    
    private var isEndOfWord: Bool { // does the next character (if any) terminate the current [non-symbol] token?
        // caution: do not use this to identify end of operators/symbols as those follow different rules (see OperatorRegistry)
        guard let p: Unicode.Scalar = self.peek() else { return true } // end of code
        return boundaryCharacters.contains(p)
    }
    
    private func readUnknown(_ value: String) -> Token {
        var value = value
        if let p = self.next() { // TO DO: this needs to continue consuming up to next valid boundary char (quote delimiter, punctuation, or white space)
            value.append(p)
        }
        return (.unknown, value)
    }
    
    private func readCharacters(_ characterSet: CharacterSet) -> String {
        var value = ""
        while let p: Unicode.Scalar = self.peek(), characterSet.contains(p) { // consume all characters
            value.append(self.next()!)
        }
        return value
    }
    
    // TO DO: replace `if let p = self.peek(), CHARSET.contains(p) { value.append(self.next()!),… }` with `if let c = self.next(CHARSET) { value.append(c),… }`
    
    private func readNumber(allowHexadecimal: Bool = true, allowDecimal: Bool = true, allowExponent: Bool = true) -> Token { // TO DO: move this to reusable standalone function for canonical number parsing/coercing (might even be an idea to put it on Scalar, similar to how OperatorRegistry works)
        // TO DO: .number enum should include number format (integer/decimal/hexadecimal/exponent) (this is less of an issue if readNumber() emits Scalar/Quantity values, as those can include literal format themselves)
        // note: if `allowHexidecimal` is true and a hexidecimal number (e.g. "0x12AB") is matched, allowDecimal and allowExponent are treated as false
        // first char is already known to be either a digit or a +/- symbol that is followed by a digit // TO DO: can't assume this
        var value = ""
        if let c = self.next(ifIn: signCharacters) { value.append(c) } // read +/- sign, if any
        // TO DO: eventually could match known currency symbols here, returning appropriate 'currency' token (in addition to capturing $/€/etc currency symbol, currency values would also use fixed point/decimal storage instead of Float/Double)
        let digits = self.readCharacters(digitCharacters) // read the digits
        if digits == "" { return self.readUnknown(value) } // (or return .unknown if there weren't any)
        value += digits
        // peek at next char to decide what to do next
        if let p: Unicode.Scalar = self.peek() {
            if allowHexadecimal && hexadecimalSeparators.contains(p) && ["-0", "0", "+0"].contains(value) { // found "0x"
                value.append(self.next()!) // append the 'x' character // TO DO: normalize for readability (lowercase 'x', uppercase A-F)
                let digits = self.readCharacters(hexadecimalCharacters) // get all hexadecimal digits after the 'x'
                if digits == "" { return self.readUnknown(value) } // (or return .unknown if there weren't any)
                value += digits
            } else {
                if allowDecimal && decimalSeparators.contains(p) { // read the fractional part, if found
                    value.append(self.next()!)
                    let digits = self.readCharacters(digitCharacters) // get all digits after the '.'
                    if digits == "" { return self.readUnknown(value) } // (or return .unknown if there weren't any)
                    value += digits
                }
                if allowExponent, let c = self.next(ifIn: exponentSeparators) { // read the exponent part, if found
                    value.append(c)
                    let (token, suffix) = readNumber(allowHexadecimal: false, allowDecimal: false, allowExponent: false)
                    value += suffix // TO DO: what about normalizing the exponent (c.f. AppleScript), e.g. `2e4` -> "2.0E+4"? or is that too pedantic
                    if case .unknown = token { return (.unknown, value) }
                }
                // TO DO: while currency prefixes are a pain, unit suffixes (e.g. `mm`, `g`) are somewhat easier; worth giving it a crack once essentials are all done
            }
        }
        return self.isEndOfWord ? (.number(value: value), value) : self.readUnknown(value)
    }
    
    // TO DO: readLiteralText()
    
    // main
    
    func tokenize() -> [Token] { // note: tokenization should never fail; any issues should be added to token stream for parsers to worry about // TO DO: ensure original lines of source code can be reconstructed from token stream (that will allow ambiguous quoting in per-line reading to be resolved downstream)
        if self.code == "" { return [] }
        var result = [Token]()
        var token: Token = (.startOfCode, "")
        while let c = self.next() {
            
            // TO DO: consider moving body of this loop into `readOneToken()` [making sure, of course, that none of its branches will ever consume <>1 token]
            
            //print("'\(c)'")
            // push previous token onto result list
            result.append(token)
            if let t = punctuationTokens[c] {
                token = (t, String(c))
            } else if let t = quoteDelimiterTokens[c] {
                
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
                default:
                    // TO DO: `self.backtrack(); return self.readTextLiteral()` and move following to function for clarity
                    while let c = self.next(), quoteDelimiterTokens[c] == nil { // TO DO: backslash escapes (initially for \", \n, \t; later for \u0000; eventually for \(…) interpolation too [e.g. convert text literal to a stdlib command]) // TO DO: normalize linebreak characters as LF; how best to treat invisibles, control chars? (best to reject invisible chars, by requiring backslash escapes/converting invisibles to escapes in editing mode)
                        token.value.append(c)
                    }
                }
            } else { // TO DO: this won't handle characters composed of >1 code point
                switch c {
                case identifierCharacters: // TO DO: also accept digits after first char
                    var value = String(c)
                    while let c = self.next(ifIn: identifierAdditionalCharacters) { value.append(c) }
                    let name = String(value)
                    let (prefixOperator, infixOperator) = self.operatorRegistry?.matchWord(name) ?? (nil, nil)
                    if prefixOperator == nil && infixOperator == nil {
                        token = (.identifier(value: name, isQuoted: false), name)
                    } else {
                        token = (.operator(value: name, prefix: prefixOperator, infix: infixOperator), name)
                    }
                case symbolCharacters:
                    self.backtrack() // unconsume symbol char so that operator registry can attempt to match full symbol name
                    let (prefixOperator, infixOperator) = self.operatorRegistry?.matchSymbol(self) ?? (nil, nil)
                    if prefixOperator == nil && infixOperator == nil {
                        let c = self.next()! // reconsume symbol
                        // if std math operators aren't loaded (e.g. pure data structure parsing) then see if symbol is '+'/'-' followed by a digit (i.e. beginning of a signed number), and attempt to match it as a signed number
                        if signCharacters ~= c, let p: Unicode.Scalar = self.peek(), digitCharacters.contains(p) {
                            self.backtrack() // unconsume +/- symbol and let readNumber() [try to] match entire number
                            token = self.readNumber()
                        } else { // it's an unrecognized symbol, which parser will report as syntax error should it appear at top level of code
                            token = (.symbol, String(c))
                        }
                    } else {
                        let name = prefixOperator?.name ?? infixOperator!.name
                        token = (.operator(value: name, prefix: prefixOperator, infix: infixOperator), name) // TO DO: FIX: token.value is wrong here (it's the canonical operator name but should be the original matched text); either matchSymbol needs to return the original substring as well as operator definitions, or (if recording code ranges only) we need to capture the start and end indexes of the token; TBH, it'd probably be best to separate out the raw range recording completely, as the outer repeat loop can take care of that
                    }
                case digitCharacters: // match unsigned number literal; note: assuming stdlib operator tables are loaded, any preceding '+'/'-' symbols will be matched as prefix operators (it's up to parser to optimize these operators away, c.f. AppleScript)
                    self.backtrack() // unconsume digit and let readNumber() [try to] match entire number token
                    token = self.readNumber()
                case linebreakCharacters:
                    token = (.lineBreak, "\n")
                case whitespaceCharacters:
                    token = (.whitespace, String(c))
                    while let c = self.next(ifIn: whitespaceCharacters) { token.value.append(c) }
                default:
                    token = self.readUnknown(String(c))
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


