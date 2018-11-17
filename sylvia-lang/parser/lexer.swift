//
//  lexer.swift
//

// TO DO: a quicker way to check quote and block balancing during code editing is to skip all characters except quote and block delimiters [and their associated escape sequences], which can be done with a very simple Scanner that pushes open delimiters onto a stack and pops them off again when the corresponding close delimiter is found


// note: for object specifier syntax, it should be practical to use `NAME1:EXPR of NAME2 of NAME3:EXPR` (combined with `thru` operator for by-range specifiers, which take 2 args), or `NAME at EXPR of NAME2 named EXPR of NAME3` (where all reference forms that take a selector value have a dedicated operator), as syntactic sugar for `NAME3.NAME2[EXPR].NAME[EXPR]` (unless `A[B]` is also used as synonym for `A.B`, in which case it'll be `NAME3.NAME2.named(EXPR).NAME[EXPR]`, c.f. nodeautomation). This could actually get us very close to a familiar "AppleScript-ish" syntax (minus all of its defects), e.g. `documentFile at 1 of folder named "Documents" of home`. (Yet another refinement would be for parser to special-case `WORD NUMBER` sequence as shorthand for `WORD[NUMBER]`, reducing need to use `at` operator to non-number selectors only, as that pattern is otherwise syntactically illegal. BTW, AppleScript uses `index`, not `at`, as explicit selector type, though may be better to use `atIndex`, e.g. `documentFile.atIndex(…)`.)


/* TO DO: need to decide between backslash escapes in text and 'tags', e.g. `"Hello,««name»»!"` is arguably easier to understand than `"Hello,\(name)!"`; in turn, character and unicode escapes would be "foo««return»»bar««0u12AB»»" rather than "foo\nbar\u12AB".
 
 [note: rest of this comment assumes `{EXPR}` escapes, but for sake of regexp compatibility it would be best to avoid using any character already reserved by PCRE; thus `««…»»` is looking likeliest; BTW, the same escape sequences might be employed in annotations, particularly those used as userdoc annotations, where ability for docs to introspect handler's interface, e.g. for parameter types, further reduces unnecessary duplication of information]
 
 Interpolation rules would be to insert text (including numbers and dates) as-is, while lists, etc would use their literal representation. To insert literal text, use `"Hello,{code(name)}!"`. (Obviously, there are risks attached to providing the interpolator full access to all loaded commands and operators, so some sort of language-level sandboxing should be imposed. readQuotedText will also need to do punctuation and quote balancing to determine where the interpolated block ends.)
 
 Another benefit of this approach is that it can be easily adapted for use as general templating engines (obviously this'd require ability to attach automatic codecs, e.g. for HTML templating, default behavior would be to install a code that auto-converts all `&<>"'` chars in a given Text value to HTML entities automatically, and also to accept `RawHTML(Text)` values which bypasses the escape and inserts HTML code directly [this will require care in design to ensure programs can't be spoofed into wrapping Text in RawHTML to slip untrusted text into an HTML document as HTML code]).
 
 The flipside to using `{…}` instead of `\ESCAPE` is that literal text values containing literal braces and quotes are a pain to write (e.g. `"Hello,{'“'}Bob{'”'}!"`, `"foo{'{'}bar{'}'}"`), and something users will tend to screw up on. (Literal quote and brace characters might be handled as special escapes - e.g. `{"}`, `{“}`, `{”}`, `{{`, `}}` - or backslash could still be used purely for literal escapes: `\"`, `\“`, `\”`, `\{`, `\}`, `\\`.)
 
 Yet another option is to use 2-char escape sequences `{{…}}` for interpolation, as it's easy for users to split the literal (`"foo {" & "{ bar"`) in the rare case that a literal "{{" needs to appear in text (avoiding need to have an escape pattern for escapes).
 
 There's no ideal solution to this, although a smart editor should be able to look after much of the details. Just bear in mind the safety implications when using non-literal text as templates.
*/


// Q. any situations where whitespace needs to be known? (e.g. parser should be able to reduce `- 3` [.symbol.number] to `-3` [Value]); what's easiest when reading unbalanced lines

// TO DO: what chars should be disallowed? (e.g. most control chars, invisibles, hairline spaces; how should spoofable characters be treated, both in source code and raw input sanitizing? [Q. what characters are known to be spoofable?] unicode paragraph/line chars should be normalized as LF, CRLF and CR should be normalized as LF; use tabs for indentation [pretty printer should always ensure consistent indents]; control chars, etc within text literals should be pretty printed as character escapes; Q. how to avoid executing scripts containing problem characters until they've been put right?)

// Q. how should pretty printer, input sanitizers handle normalization forms?

// TO DO: bidirectional text support (this'll require proper handling of RTL/LTR markers, especially when mixing Arabic/Hebrew with standard Latin punctuation and library-defined operator symbols)

// TO DO: how best to implement auto-translation of identifiers? (TBH, this is probably something that should only be done at editor level as an assist to users; code as typed should remain canonical, and any on-the-fly pidgin auto-translations done in structure editor only [since translations are neither guaranteed to roundtrip or remain constant over time])

// TO DO: need a set of syntax rules regarding placement of annotations, e.g. `1 «…» +2` is legal in many languages (e.g. `1 /*…*/ +2` in JS)

// TO DO: allow native handlers to explicitly declare return types as `NAME(…) returning RETURNTYPE else ERRORTYPE`? (the `else` clause might be mandatory when RETURNTYPE is given; if excluded and an error occurs within handler, this should throw an [unrecoverable?] error [Q. should RETURNTYPE also throw an unrecoverable error when it fails? after all, failure here strongly implies a bug in handler implementation])


 
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

/******************************************************************************/
// character sets for token types

// TO DO: messing with Unicode.Scalar just to please CharacterSet is grotty and a pain (since Lexer should only care about Characters); how easy/wise to convert CharacterSets to Set<Character>?

// the following should probably be public static constants on Lexer


// punctuation (these are hardcoded and non-overrideable)

// quoted text/name literals
let quotedTextDelimiterCharacters = CharacterSet(charactersIn: "\"“”")
let quotedIdentifierDelimiterCharacters = CharacterSet(charactersIn: "'‘’")
let quotedTextEscapeCharacters = CharacterSet(charactersIn: "\\")

// annotation literals (comments, user documentation, TODOs, etc)
let annotationDelimiters = (start: "«", end: "»")
let annotationDelimiterCharacters = CharacterSet(charactersIn: annotationDelimiters.start)
let annotationDelimiterEndCharacters = CharacterSet(charactersIn: annotationDelimiters.end)

let quoteDelimiterCharacters = quotedTextDelimiterCharacters.union(quotedIdentifierDelimiterCharacters)
                                .union(annotationDelimiterCharacters).union(annotationDelimiterEndCharacters)

let punctuationTokens: [Character:TokenType] = [
    "{": .blockLiteral, // while parens could be used for blocks too (lexical context will determine how/when they're evaluated), we're using conservative C-like syntax for familiarity, and using parens for argument/parameter lists and overriding operator precedence only (this leaves us without a literal record [struct] syntax, but we can do without a record type for this exercise)
    "}": .blockLiteralEnd,
    "(": .groupLiteral,
    ")": .groupLiteralEnd,
    "[": .listLiteral,
    "]": .listLiteralEnd,
    ",": .itemSeparator,
    // TO DO: what else?
    // TO DO: if using JS-ish syntax, use "." for .attributeSelector (note: this shouldn't stop us defining `of` operator as well, though need to think how they both bake down to Values; probably want a specific Expression subclass for this)
    // important: backslashes should never be used as punctuation/operators, as they are already reserved for use inside quoted text and their presence anywhere else provides lexer with hint that cursor is inside a multi-line quote (in single-line lexing mode) or syntax error (in full-script mode) // TO DO: delete this comment if/when backslash escapes are replaced by 'tag' escapes (though it's still recommended that backslash chars not be used by language)
]

let punctuationCharacters = CharacterSet(punctuationTokens.keys.map { $0.unicodeScalars.first! })

// identifiers
let identifierCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
let identifierAdditionalCharacters = identifierCharacters.union(digitCharacters)

// number literals
let signCharacters = CharacterSet(charactersIn: "+-") // TO DO: decide exactly what sign glyphs to include here (be aware that these characters are also in symbolCharacters as they can also be used as arithmetic operators)
let digitCharacters = CharacterSet.decimalDigits // lexer will match decimal and exponent notations itself (note that when stdlib operators are loaded, any +/- symbols before number will be read as a separate .operator; it's up to parser to match unary +/- .operators followed by .number and reduce it to a signed number value for efficiency [note that in AppleScript, multiple +/- symbols before a number are collapsed down by pretty printer])
let decimalSeparators = CharacterSet(charactersIn: ".")
let hexadecimalCharacters = digitCharacters.union(CharacterSet(charactersIn: "AaBbCcDdEeFf"))
let hexadecimalSeparators = CharacterSet(charactersIn: "Xx")
let exponentSeparators = CharacterSet(charactersIn: "Ee")

// operators/unknown symbols
let symbolCharacters = CharacterSet.symbols.union(CharacterSet.punctuationCharacters).subtracting(punctuationCharacters) // note: `+` and `-` appear in both signCharacters and symbolCharacters as they are used both in numbers and as operators (lexer and parser will perform further analysis to figure out which)

// white space
let linebreakCharacters = CharacterSet.newlines
let whitespaceCharacters = CharacterSet.whitespaces

// characters which are guaranteed to terminate the preceding token (unless it's an operator/symbol token, as those have their own boundary rules)
let boundaryCharacters = linebreakCharacters.union(whitespaceCharacters).union(quoteDelimiterCharacters).union(punctuationCharacters).union(symbolCharacters)



/******************************************************************************/
// Token

enum TokenType { // TO DO: rename Token and hold parsed strings (plus formatting flags, operator definitions, etc where applicable); Q. what about layout hinting, so pretty printer can output normalized (correctly indented, regularly spaced) code while still preserving/improving certain aspects of user's code layout (e.g. explicit line wraps within long lists should always appear after item separator commas and before next item)
    
    
    // what about #WORD and @WORD (hashtags and 'super global' identifiers)?
    
    // what about EXPR? and EXPR! as debugging/introspection modifiers?
    
    
    // TO DO: identifier and operator names should be able to contain almost any legal Unicode character, but for now let's KISS and just use a convenient subset of characters for which CharacterSet already provides predefined constants, and treat any other characters [that aren't known punctuation chars] as .unknown
    
    case startOfCode
    case endOfCode
    
    // Punctuation
    case annotationLiteral          // atomic; the lexer automatically reads everything between `«` and corresponding `»`, including nested annotations; Q. how to use annotations for docstrings, comments, TODO, TOFIX, metainfo, etc?
    case annotationLiteralEnd       // this will only appear in token stream if not balanced by an earlier .annotationLiteral
    case listLiteral                // "[" an ordered collection (array)
    case listLiteralEnd             // "]"
    case blockLiteral               // "{"
    case blockLiteralEnd            // "}"
    case groupLiteral               // "("
    case groupLiteralEnd            // ")"
    case itemSeparator              // ","
    case lineBreak                  // "\n", etc // CharacterSet.newLines
    
    // Literals
    case textLiteral(value: String)         // atomic; the lexer automatically reads everything between `"` and corresponding `"`, including `\CHARACTER` escapes (curly quotes are also accepted, and are used as standard when pretty printing text literals)
    case number(value: String)     // .decimal // TO DO: this needs to support +/-, decimal point, and exponent notation (what about accepting `.1` as shorthand for `0.1`? should probably disallow `1.` as a syntax error though; note that JS & Python permit both, whereas Swift rejects both; note that if we do accept them, the pretty printer should always canonify them)
    
    // Names
    case identifier(value: String, isQuoted: Bool) // .letters // atomic; the lexer automatically reads everything between `'` and corresponding `'`; this allows identifier names that are otherwise masked by operator names to be used in quoted form (e.g. `'AND'(a,b)` = `a AND b`)
    case operatorName(value: String, prefix: OperatorDefinition?, infix: OperatorDefinition?)
    
    // Interstitials
    case whitespace
    case symbol(Character)     // any symbols that are are not recognized as operators // TO DO: or just use .unknown?
    case unknown(description: String) // any characters that are not otherwise recognized
    case illegal // TO DO: currently unused; decide how invalid unicode chars are handled (see also CharacterSet.illegalCharacters); for now, everything just gets stuffed into `unknown`
}


/******************************************************************************/


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
    
    private func readUnknown(_ value: String, description: String = "unknown characters") -> Token {
        var value = value
        if let p = self.next() { // TO DO: FIX: this needs to continue consuming up to next valid boundary char (quote delimiter, punctuation, or white space)
            value.append(p)
        }
        return (.unknown(description: description), value)
    }
    
    private func readCharacters(ifIn characterSet: CharacterSet) -> String {
        var value = ""
        while let p: Unicode.Scalar = self.peek(), characterSet.contains(p) {
            value.append(self.next()!)
        }
        return value
    }
    
    private func readCharacters(ifNotIn characterSet: CharacterSet) -> String {
        var value = ""
        while let p: Unicode.Scalar = self.peek(), !characterSet.contains(p) {
            value.append(self.next()!)
        }
        return value
    }
    
    //
    
    private func readNumber(allowHexadecimal: Bool = true, allowDecimal: Bool = true, allowExponent: Bool = true) -> Token { // TO DO: move this to reusable standalone function for canonical number parsing/coercing (might even be an idea to put it on Scalar, similar to how OperatorRegistry works)
        // TO DO: .number enum should include number format (integer/decimal/hexadecimal/exponent) (this is less of an issue if readNumber() emits Scalar/Quantity values, as those can include literal format themselves)
        // note: if `allowHexidecimal` is true and a hexidecimal number (e.g. "0x12AB") is matched, allowDecimal and allowExponent are treated as false
        // first char is already known to be either a digit or a +/- symbol that is followed by a digit // TO DO: can't assume this
        var value = ""
        if let c = self.next(ifIn: signCharacters) { value.append(c) } // read +/- sign, if any
        // TO DO: eventually could match known currency symbols here, returning appropriate 'currency' token (in addition to capturing $/€/etc currency symbol, currency values would also use fixed point/decimal storage instead of Float/Double)
        let digits = self.readCharacters(ifIn: digitCharacters) // read the digits
        if digits == "" { return self.readUnknown(value, description: "missing number") } // (or return .unknown if there weren't any)
        value += digits
        // peek at next char to decide what to do next
        if let p: Unicode.Scalar = self.peek() {
            if allowHexadecimal && hexadecimalSeparators.contains(p) && ["-0", "0", "+0"].contains(value) { // found "0x"
                value.append(self.next()!) // append the 'x' character // TO DO: normalize for readability (lowercase 'x', uppercase A-F)
                let digits = self.readCharacters(ifIn: hexadecimalCharacters) // get all hexadecimal digits after the '0x'
                if digits == "" { return self.readUnknown(value, description: "missing hexadecimal value after \(value.debugDescription)") }
                value += digits
            } else {
                if allowDecimal && decimalSeparators.contains(p) { // read the fractional part, if found
                    value.append(self.next()!)
                    let digits = self.readCharacters(ifIn: digitCharacters) // get all digits after the '.'
                    if digits == "" { return self.readUnknown(value, description: "missing digits after \(value.debugDescription)") }
                    value += digits
                }
                if allowExponent, let c = self.next(ifIn: exponentSeparators) { // read the exponent part, if found
                    value.append(c)
                    let (token, suffix) = readNumber(allowHexadecimal: false, allowDecimal: false, allowExponent: false)
                    value += suffix // TO DO: what about normalizing the exponent (c.f. AppleScript), e.g. `2e4` -> "2.0E+4"? or is that too pedantic
                    if case .unknown = token { return (.unknown(description: "missing digits after \(value.debugDescription)"), value) }
                }
                // TO DO: while currency prefixes are a pain, unit suffixes (e.g. `mm`, `g`) are somewhat easier; worth giving it a crack once essentials are all done
            }
        }
        return self.isEndOfWord ? (.number(value: value), value) : self.readUnknown(value, description: "unexpected characters after \(value.debugDescription)")
    }
    
    // TO DO: rethink how readQuoted… funcs are implemented to better support per-line lexing
    private func readQuotedText() -> Token {
        // TO DO: move all this stuff into its own LiteralText enum
        // TO DO: currently uses conventional backslash escapes, but `««EXPR»»` escapes would work better for users
        
        // TO DO: problem we have here is that in single-line mode the lexer has little idea if it's inside or outside quoted text; it can make some educated guesses on % likelihood by analyzing opening quote type (`“` = probably inside, `”` = probably outside, `"` = either), presence of any backslash escapes (since backslashes are _only_ used inside quoted literals), and/or presence of known words (operator names); this will enable interactive editing tools to better assist user in writing valid code, and can provide more helpful SyntaxErrors when non-interactively parsing scripts for evaluation
        let q = String(self.next()!) // TO DO: do we really need to capture opening quote here? (we just need to shift raw substring crap out of here)
        var value = ""
        while true {
            // TO DO: consider inverting following charset and subtracting illegal chars, and using readCharacters(ifIn:)
            value += self.readCharacters(ifNotIn: quotedTextDelimiterCharacters.union(quotedTextEscapeCharacters)) // TO DO: need to include backslash escapes in charset (initially for \", \n, \t; later for \u0000; eventually for \(…) interpolation too [e.g. convert text literal to a stdlib command]) // TO DO: normalize linebreak characters as LF; how best to treat invisibles, control chars? (best to reject invisible chars, by requiring backslash escapes/converting invisibles to escapes in editing mode)
            guard let c = self.next() else { return (.unknown(description: "literal text is missing end quote"), q + value) } // end of code
            if quotedTextDelimiterCharacters ~= c { return (.textLiteral(value: value), value) } // found closing quote
            // backslash escape
            guard let escapeType = self.next() else { return (.unknown(description: "literal text is missing character after backslash"), q + value + String(c)) }
            switch escapeType {
            case "n", "r":
                value += "\n"
            case "t":
                value += "\n"
            default: // TO DO: "\uXXXX", "\(…)" escapes
                print("Found unknown escape character in text: “\\\(escapeType)”")
                value += "\\\(escapeType)"
            }
        }
    }
    
    private func readQuotedIdentifier() -> Token {
        // TO DO: should opening quote be captured?
        // TO DO: should probably disallow digits at start of name, even when quoted (e.g. if `A[B]` becomes synonym for `A.B`, allowing B to start with a digit would prevent `[…]` being used as by-index selector, e.g. `A[3]`, c.f. JS; also need to consider what could go wrong allowing identifier and text values to be used mostly interchangeably)
        let value = self.readCharacters(ifNotIn: quotedIdentifierDelimiterCharacters) // TO DO: is there any possible use case where escaping `'` would be needed? if not, don't provide escape support; it may also be best to restrict characters that can appear within quoted identifiers to word, symbol [and potentially spaces], to avoid excessive flexibility (re. spaces: while Latin-based identifiers can be transformed between camelCase and all-lowercase representations for display purposes, identifiers in languages that use whitespace separation but do not have uppercase representation would not support such transformations so will require some other joining character; conventions on use of underscores in names would also need to be worked out—one option is always to use underscores, not camelcase, which would also be safer in event that identifiers are case-insensitive [plus need to consider how native identifiers might map to foreign ones, e.g. ObjC class and method names])
        return self.next() == nil ? (.unknown(description: "quoted identifier is missing end quote"), value) : (.identifier(value: value, isQuoted: true), value) // check for end of code or closing quote
    }
        
    // main
    
    func tokenize() -> [Token] { // note: tokenization should never fail; any issues should be added to token stream for parsers to worry about // TO DO: ensure original lines of source code can be reconstructed from token stream (that will allow ambiguous quoting in per-line reading to be resolved downstream)
        if self.code == "" { return [] }
        var result: [Token] = [(.startOfCode, "")]
        // TO DO: backtrack() calls is ugly; consider using separate `var char:Character?` and `func next()->()`
        while let c = self.next() {
            let token: Token
            if let t = punctuationTokens[c] {
                token = (t, String(c))
            } else { // TO DO: this won't handle characters composed of >1 code point; will this be an issue?
                switch c {
                case quotedTextDelimiterCharacters:
                    self.backtrack()
                    token = self.readQuotedText()
                case quotedIdentifierDelimiterCharacters:
                    //self.backtrack()
                    token = self.readQuotedIdentifier()
                case annotationDelimiterCharacters:
                    var value = annotationDelimiters.start
                    var depth = 1
                    while let c = self.next(), depth > 0 {
                        value.append(c)
                        switch c {
                        case annotationDelimiterCharacters: depth += 1
                        case annotationDelimiterEndCharacters: depth -= 1
                        default: ()
                        }
                    }
                    token = (.annotationLiteral, value)
                    // TO DO: if depth <> 0 need to handle unbalanced .annotationLiteral (bear in mind that unbalanced block & quote delimiters will be normal in per-line parsing; solution might be to add before and after tally cases to TokenType so that imbalances are passed on to parser [think double-entry bookkeeping, where each tokenized line is a ledger and the parser's job is to perform a trial balance; once everything balances it can output the final AST])
                case annotationDelimiterEndCharacters:
                    token = (.annotationLiteralEnd, annotationDelimiters.end)
                case identifierCharacters: // TO DO: also accept digits after first char
                    var value = String(c)
                    while let c = self.next(ifIn: identifierAdditionalCharacters) { value.append(c) }
                    let name = String(value)
                    let (prefixOperator, infixOperator) = self.operatorRegistry?.matchWord(name) ?? (nil, nil)
                    if prefixOperator == nil && infixOperator == nil {
                        token = (.identifier(value: name, isQuoted: false), name)
                    } else {
                        token = (.operatorName(value: name, prefix: prefixOperator, infix: infixOperator), name)
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
                            token = (.symbol(c), String(c))
                        }
                    } else {
                        let name = prefixOperator?.name ?? infixOperator!.name
                        token = (.operatorName(value: name, prefix: prefixOperator, infix: infixOperator), name) // TO DO: FIX: token.value is wrong here (it's the canonical operator name but should be the original matched text); either matchSymbol needs to return the original substring as well as operator definitions, or (if recording code ranges only) we need to capture the start and end indexes of the token; TBH, it'd probably be best to separate out the raw range recording completely, as the outer repeat loop can take care of that
                    }
                case digitCharacters: // match unsigned number literal; note: assuming stdlib operator tables are loaded, any preceding '+'/'-' symbols will be matched as prefix operators (it's up to parser to optimize these operators away, c.f. AppleScript)
                    self.backtrack() // unconsume digit and let readNumber() [try to] match entire number token
                    token = self.readNumber()
                case linebreakCharacters:
                    token = (.lineBreak, "\n")
                case whitespaceCharacters:
                    let value = String(c) + self.readCharacters(ifIn: whitespaceCharacters) // TO DO: should be sufficient to skipCharacters(ifIn:)
                    token = (.whitespace, value)
                default:
                    token = self.readUnknown(String(c)) // TO DO: is there any value in readUnknown capturing the extracted text? (actually, would be better if .unknown captured the token it had started to parse, if any [e.g. in readNumber()], followed by rest of text up to boundary; editing tools/error reporting can then use that to provide helpful suggestions on how to correct code, including auto-suggest, auto-correct, etc)
                }
            }
            result.append(token)
        }
        result.append((.endOfCode, ""))
        return result
    }
}

