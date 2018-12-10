//
//  lexer.swift
//

// TO DO: a quicker way to check quote and block balancing during code editing is to skip all characters except quote and block delimiters [and their associated escape sequences], which can be done with a very simple Scanner that pushes open delimiters onto a stack and pops them off again when the corresponding close delimiter is found


// TO DO: implement 'pipe' symbol (should this be core punctuation or stdlib operator?), allowing commands where result of first is first arg to second to be written in chained rather than nested format; Q. what character to use, e.g. "~", "\", "…", "→" ("->")? e.g. if "\" is used, `bar(foo,1,2)` can be written as `foo()\bar(1,2)` (note: entoli syntax uses semicolon symbol in keeping with English-esque punctuation rules, but sylvia syntax derives from C &co where semicolon has established meaning as statement separator)

// note: for object specifier syntax, it should be practical to use `NAME1:EXPR of NAME2 of NAME3:EXPR` (combined with `thru` operator for by-range specifiers, which take 2 args), or `NAME at EXPR of NAME2 named EXPR of NAME3` (where all reference forms that take a selector value have a dedicated operator), as syntactic sugar for `NAME3.NAME2[EXPR].NAME[EXPR]` (unless `A[B]` is also used as synonym for `A.B`, in which case it'll be `NAME3.NAME2.named(EXPR).NAME[EXPR]`, c.f. nodeautomation). This could actually get us very close to a familiar "AppleScript-ish" syntax (minus all of its defects), e.g. `documentFile at 1 of folder named "Documents" of home`. (Yet another refinement would be for parser to special-case `WORD NUMBER` sequence as shorthand for `WORD[NUMBER]`, reducing need to use `at` operator to non-number selectors only, as that pattern is otherwise syntactically illegal. BTW, AppleScript uses `index`, not `at`, as explicit selector coercion, though may be better to use `atIndex`, e.g. `documentFile.atIndex(…)`.)


/* TO DO: text literals should use `««EXPR»»` "tags", not backslash escapes, for character substitution and interpolation; e.g. `"Hello,««name»»!"` is arguably easier to understand than `"Hello,\(name)!"`; in turn, character and unicode escapes would be "foo««linebreak»»bar««0u12AB»»" rather than "foo\nbar\u12AB". Note that `linebreak`, `tab`, etc would need to be defined as non-maskable identifiers/atom operators in stdlib, and `case digitCharacters` in Lexer.tokenize() (or Lexer.readNumber?) will have to recognize `0uCODE…` syntax (this should use UTF-8 notation, so multiple codepoints will need written as `0uAAAA 0uBBBB 0uCCCC` and combined into one Text token by lexer, with formatting annotation). Q. what limits should be placed on interpolated EXPR when interpolating literal strings, e.g. by evaluating it in restricted Env? (e.g. Side-effects really should be disallowed. One option would be to whitelist stdlib handlers as being safe and relevant for this task; alternatively, allow any stdlib handler but error if any try to perform side effects.) It's probably best to have a single set of rules/limitations for both literal interpolation and text templating (where the format string is supplied at runtime) to avoid confusing users; the only difference would be in how custom identifiers and handlers are made available in latter case. (Whereas string literals can be automatically allowed to any symbol in their lexical scope, a runtime templating function would need all custom resources explicitly passed in, e.g. assuming an Env instance is used to represent a custom object, it would need read locks to permit client code to access its own handlers but not those of its parent scopes, while still allowing those handlers to access parent scopes themselves, plus write locks so that client code can't change anything.)
 
 ««…»» escape sequences might also be employed in [some] annotations, particularly those used as userdoc annotations, allowing docstrings to insert info taken directly from handler's interface, e.g. parameter/return type, instead of user rekeying that info manually (the whole point of declaring handler interfaces being to minimize such duplication of information).
 
 Interpolation rules would be to insert text (which includes numbers and dates) as-is, e.g. `"Hello ««name»»!"` -> "Hello Bob!", while lists, etc would automatically use their literal representation. To insert literal representation of text, use `code(EXPR)`, e.g. `"Hello ««code(name)»»!"` -> "Hello “Bob”!". (Obviously, there are risks attached to providing the interpolator full access to all loaded commands and operators, so some sort of language-level sandboxing should be imposed. readQuotedText will also need to do punctuation and quote balancing to determine where the interpolated block ends.)
 
 Another benefit of this approach is that it can be easily adapted for use as general templating engines (obviously this'd require ability to attach automatic codecs, e.g. for HTML templating, default behavior would be to install a code that auto-converts all `&<>"'` chars in a given Text value to HTML entities automatically, and also to accept `RawHTML(Text)` values which bypasses the escape and inserts HTML code directly [this will require care in design to ensure programs can't be spoofed into wrapping Text in RawHTML to slip untrusted text into an HTML document as HTML code]).
 
 Note that using 2-char escape sequence (`««`) for interpolation enables users to divide the "««" characters across two separate literals (e.g. `"foo «" & "« bar"`) should a non-escaping "««" sequence ever need to appear in text. (It's also possible to define constant names for these patterns which can be inserted by enclosing them in escapes, e.g. `"foo««beginAnnotationSymbol»»bar««endAnnotationSymbol»»"` evals to "foo««bar»»".)
 
 There's no ideal solution to this, although a smart editor should be able to look after much of the details. Just bear in mind the safety implications when using non-literal text as templates.
*/

// Q. should symbols have their own literal syntax (c.f. Ruby Symbol class, which uses `:NAME` syntax), or should they be written as attributes of a global [abstract] 'symbol' namespace (c.f. appscript, which uses `k.NAME`)?
//
// ~name
//
// k.name


// Q. any situations where whitespace needs to be known? (e.g. parser should be able to reduce `- 3` [.symbol.number] to `-3` [Value]); what's easiest when reading unbalanced lines

// TO DO: what chars should be disallowed? (e.g. most control chars, invisibles, hairline spaces; how should spoofable characters be treated, both in source code and raw input sanitizing? [Q. what characters are known to be spoofable?] unicode paragraph/line chars should be normalized as LF, CRLF and CR should be normalized as LF; use tabs for indentation [pretty printer should always ensure consistent indents]; control chars, etc within text literals should be pretty printed as character escapes; Q. how to avoid executing scripts containing problem characters until they've been put right?)

// Q. how should pretty printer, input sanitizers handle normalization forms?

// TO DO: bidirectional text support (this'll require proper handling of RTL/LTR markers, especially when mixing Arabic/Hebrew with standard Latin punctuation and library-defined operator symbols)

// TO DO: how best to implement auto-translation of identifiers? (TBH, this is probably something that should only be done at editor level as an assist to users; code as typed should remain canonical, and any on-the-fly pidgin auto-translations done in structure editor only [since translations are neither guaranteed to roundtrip or remain constant over time])

// TO DO: need a set of syntax rules regarding placement of annotations, e.g. `1 «…» +2` is legal in many languages (e.g. `1 /*…*/ +2` in JS)

// TO DO: allow native handlers to explicitly declare return types as `NAME(…) returning RETURNTYPE else ERRORTYPE`? (the `else` clause might be mandatory when RETURNTYPE is given; if excluded and an error occurs within handler, this should throw an [unrecoverable?] error [Q. should RETURNTYPE also throw an unrecoverable error when it fails? after all, failure here strongly implies a bug in handler implementation])

// TO DO: define `?` as atom/postfix operator that pauses interpreter and enters introspection/interactive/debug mode? e.g. `foo()?` `(do stuff) catching ?`; note that if this is part of core punctuation then parser can treat it differently according to need (e.g. for development, enter debug mode; for deployment, ignore/throw/rethrow according to context); similarly, potentially destructive handlers could enter IID mode by default during debug mode, except where the invoking command is postfixed with `!` to indicate it should always go ahead without prompting

// TO DO: `#WORD` and `@WORD` (hashtags and universal identifiers); hash modifier may be applied to any normal identifier (or text literal?) or annotation text to indicate it should be indexed as searchable term; 'at' modifier would provide a globally defined shortcut to any [local and/or remote?] resource (Q. how close in purpose are 'at' tags to URNs? could/should they 'bake' as URNs for portability/durability?)

// TO DO: should search indexes be generated by tokenizer and/or by parser? how/where should they be stored? Bear in mind that code may include sensitive info that should not be leakable, e.g. via search facilities, so only public interfaces (handler signatures and userdoc annotations) and #/@ words should be indexed.

// TO DO: Q. what about layout hinting, so pretty printer can output normalized (correctly indented, regularly spaced) code while still preserving/improving certain aspects of user's code layout (e.g. explicit line wraps within long lists should always appear after item separator commas and before next item)


// TO DO: skip first line if it has `#!` prefix


import Foundation


struct TokenInfo: CustomDebugStringConvertible {
    let coercion: Token
    let start: String.Index
    let end: String.Index
    
    var debugDescription: String { return "\(self.start.encodedOffset)…\(self.end.encodedOffset) \(self.coercion)" }
    
    // TO DO: consider always using single-line Lexer, and store line number here as well
}


extension CharacterSet { // convenience extension, allows CharacterSet instances to be matched directly in switch cases
    
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
    // TO DO: ":" for KEY:VALUE pairs (used in key-value list literals and argument/parameter lists to declare field labels; might also be used in blocks to declare name-value bindings instead of `let/var NAME=VALUE` syntax;)
    // TO DO: if using JS-ish syntax, use "." for .attributeSelector (note: this shouldn't stop us defining `of` operator as well, though need to think how they both bake down to Values; probably want a specific Expression subclass for this)
    // TO DO: what else? (e.g. 'pipe')
]

let punctuationCharacters = CharacterSet(punctuationTokens.keys.map { $0.unicodeScalars.first! })

// unquoted identifiers
// TO DO: identifier and operator names should be able to contain almost any legal Unicode character, but for now let's KISS and just use a convenient subset of characters for which CharacterSet already provides predefined constants, and treat any other characters [that aren't known punctuation chars] as .unknown
let identifierCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
let identifierAdditionalCharacters = identifierCharacters.union(digitCharacters)

// number literals
let numericSigns = Set(["+", "-"])
let signCharacters = CharacterSet(charactersIn: numericSigns.joined()) // TO DO: decide exactly what sign glyphs to include here (be aware that these characters are also in symbolCharacters as they can also be used as arithmetic operators)
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
    case lineBreak                  // "\n", etc // CharacterSet.newLines
    // TO DO: also allow ";" as expression separator? (TBH, period would be preferable, but not if it's already symbol for attribute selection)
    
    // literals
    case textLiteral(value: String)         // atomic; the lexer automatically reads everything between `"` and corresponding `"`, including `\CHARACTER` escapes (curly quotes are also accepted, and are used as standard when pretty printing text literals)
    case number(value: String, scalar: Scalar)     // .decimal // TO DO: readNumber should also output Int/Double/decimal/fixed point/etc representation (e.g. output Scalar enum rather than String, c.f. entoli's numeric-parser.swift); when implementing UnitTypeRegistry (MeasurementRegistry?) also decide if .measurement(Measurement) should be a distinct Token, or if .number should include a `unit:UnitType?` slot (TBH it's probably worth going the whole hog and having lexer delegate all number reading to dedicated module which can also be used elsewhere, e.g. by numeric coercions and parsing/formatting libraries)
    
    // names
    case identifier(value: String, isQuoted: Bool) // .letters // atomic; the lexer automatically reads everything between `'` and corresponding `'`; this allows identifier names that are otherwise masked by operator names to be used in quoted form (e.g. `'AND'(a,b)` = `a AND b`)
    case operatorName(value: String, prefix: OperatorDefinition?, infix: OperatorDefinition?) // `value` contains operator's canonical name; should it be the name that appeared in source code? (issue is how to report syntax errors: the error message needs to show the name that appears in source code)
    
    // interstitials (i.e. everything that doesn't appear to be valid code)
    case whitespace(String)
    case symbol(Character)     // any symbols that are are not recognized as operators // TO DO: or just use .unknown?
    case unknown(description: String) // any characters that are not otherwise recognized // TO DO: this should also capture matched part, if any (e.g. number), and unknown part (e.g. unknown suffix), allowing tools to provide better assistance (each part might also have its own description text, e.g. for display in editor tooltips, and the whole lot can be automatically composed into complete error message)
    case illegal // TO DO: currently unused; decide how invalid unicode chars are handled (see also CharacterSet.illegalCharacters); for now, everything just gets stuffed into `unknown`
    
    
    var precedence: Int {
        switch self {
        case .annotationLiteral:                                    return 100000 // '«...»'
        case .itemSeparator:                                        return -3 // TO DO: what should precedences be?
        case .listLiteralEnd, .blockLiteralEnd, .groupLiteralEnd:   return -2   // ','
        case .operatorName(let definition):                         return definition.infix?.precedence ?? 0 // only infix/postfix ops are of relevance (atom/prefix ops do not take a left operand [i.e. leftExpr], so return 0 for those to finish the previous expression and start a new one)
        case .lineBreak:                                            return -100
        case .endOfCode:                                            return -99999
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


class Lexer {
    
    private let code: String // TO DO: need a protocol that allows either String or SubString (avoids unnecessary string copying during single-line processing; that said, a structural/outlining editor will probably store scripts as an array of single lines anyway, in which case it's more useful to hide all source code access behind a protocol that allows editor to feed a single line, tokenize it, and potentially pull and consume next line as well to see what happens)
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
    
    @discardableResult func next() -> Character? {
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
        var suffix = ""
        while let p: Character = self.peek(), !boundaryCharacters.contains(p.unicodeScalars.first!) { // continue consuming up to next valid boundary char (quote delimiter, punctuation, or white space)
            suffix.append(p)
            self.next()
        }
//        print("Found unknown: \(value.debugDescription)") // TO DO
        return .unknown(description: "\(description): \(value)\(suffix)")
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
    
    func readNumber(allowHexadecimal: Bool = true, allowDecimal: Bool = true, allowExponent: Bool = true) -> Token {
        // note: if `allowHexidecimal` is true and a hexidecimal number (e.g. "0x12AB") is matched, allowDecimal and allowExponent are treated as false
        // first char is already known to be either a digit or a +/- symbol that is followed by a digit // TO DO: can't assume this
        var value = ""
        var scalar: Scalar
        if let sign = self.next(ifIn: signCharacters) { value.append(sign) } // read +/- sign, if any
        // TO DO: eventually could match known currency symbols here, returning appropriate 'currency' token (in addition to capturing $/€/etc currency symbol, currency values would also use fixed point/decimal storage instead of Float/Double)
        let digits = self.readCharacters(ifIn: digitCharacters) // read the digits
        if digits == "" { return self.readUnknown(value, description: "missing number") } // (or return .unknown if there weren't any)
        value += digits
        // peek at next char to decide what to do next
        if let p: Unicode.Scalar = self.peek() {
            // TO DO: `0u…` codepoint matching (this should consume one or more whitespace-delimited UTF-8 code points, e.g. `0u34 0u12A 0u34BC56` and return corresponding `.codepointText(String)` token; this will be particularly useful if/when quoted text changes from using backslash escapes to 'tag' interpolation, and more reusable than `\u0123` escape sequences that only work within literals)
            
            // TO DO: `0b…` for binary numbers?
            
            if allowHexadecimal && hexadecimalSeparators.contains(p) && ["-0", "0", "+0"].contains(value) { // found "0x"
                value.append(self.next()!) // append the 'x' character // TO DO: normalize for readability (lowercase 'x', uppercase A-F)
                let digits = self.readCharacters(ifIn: hexadecimalCharacters) // get all hexadecimal digits after the '0x'
                if digits == "" { return self.readUnknown(value, description: "missing hexadecimal value after \(value.description)") }
                value += digits
                if let n = Int(digits, radix: 16) {
                    scalar = .integer(n, radix: 16)
                } else {
                    scalar = .overflow(value, Int.self) // TO DO: consider using .floatingPoint, with approximate:true flag
                }
            } else {
                var isInteger = true
                var exponent: Scalar?
                if allowDecimal && decimalSeparators.contains(p) { // read the fractional part, if found
                    isInteger = false
                    value.append(self.next()!)
                    let digits = self.readCharacters(ifIn: digitCharacters) // get all digits after the '.'
                    if digits == "" { return self.readUnknown(value, description: "missing digits after \(value.description)") }
                    value += digits
                }
                if allowExponent, let c = self.next(ifIn: exponentSeparators) { // read the exponent part, if found
                    isInteger = false
                    value.append(c)
                    switch readNumber(allowHexadecimal: false, allowDecimal: false, allowExponent: false) {
                    case .number(let exponentString, let scalarExponent):
                        value += exponentString // TO DO: what about normalizing the exponent (c.f. AppleScript), e.g. `2e4` -> "2.0E+4"? or is that too pedantic
                        exponent = scalarExponent
                    default:
                        return .unknown(description: "missing digits after \(value.description)")
                    }
                }
                if isInteger {
                    if let n = Int(digits) {
                        scalar = .integer(n, radix: 10)
                    } else {
                        scalar = .overflow(value, Int.self) // TO DO: consider using .floatingPoint, with approximate:true flag
                    }
                } else {
                    if let n = Double(value) {
                        scalar = .floatingPoint(n)
                        if let e = exponent {
                            do {
                                scalar = try pow(scalar, e)
                            } catch {
                                scalar = .overflow(value, Double.self)
                            }
                        }
                    } else {
                        scalar = .overflow(value, Int.self) // TO DO: consider using .double, with approximate:true flag
                    }
                }
                if !self.isEndOfWord {
                    // TO DO: while currency prefixes are a pain, unit suffixes (e.g. `mm`, `g`) are somewhat easier to deal with, so implement a UnitTypeRegistry (similar to OperatorRegistry) that readNumber() can hand off lexing to here
                }
            }
        } else {
            if let n = Int(value) {
                scalar = .integer(n, radix: 10)
            } else {
                scalar = .invalid(value)
            }
        }
        return self.isEndOfWord ? .number(value: value, scalar: scalar) : self.readUnknown(value, description: "a number with unrecognized characters at the end")
    }
    
    // caution tokenize() calls readQuotedText() and readQuotedIdentifer() after consuming the opening quote itself, e.g. given script `"ABC"`, readQuotedText() begins at `A` and continues until the closing quote/end of code is reached; the closing quote is also discarded, or .unknown returned if it wasn't found
    
    // TO DO: rethink how readQuoted… funcs are implemented to better support per-line lexing (TBH, there may not be much we can do here; it's really up to line analyzer to tell the lexer what its starting point is when feeding it a single line to read)
    
    private func readQuotedText() -> Token {
        // TO DO: move all this stuff into its own LiteralText enum
        // TO DO: currently uses conventional backslash escapes, but `««EXPR»»` escapes would work better for users
        
        // TO DO: problem we have here is that in single-line mode the lexer has little idea if it's inside or outside quoted text; it can make some educated guesses on % likelihood by analyzing opening quote coercion (`“` = probably inside, `”` = probably outside, `"` = either), presence of any backslash escapes (since backslashes are _only_ used inside quoted literals), and/or presence of known words (operator names); this will enable interactive editing tools to better assist user in writing valid code, and can provide more helpful SyntaxErrors when non-interactively parsing scripts for evaluation
        var value = ""
        while true {
            // TO DO: consider inverting following charset and subtracting illegal chars, and using readCharacters(ifIn:)
            value += self.readCharacters(ifNotIn: quotedTextDelimiterCharacters.union(quotedTextEscapeCharacters)) // TO DO: need to include backslash escapes in charset (initially for \", \n, \t; later for \u0000; eventually for \(…) interpolation too [e.g. convert text literal to a stdlib command]) // TO DO: normalize linebreak characters as LF; how best to treat invisibles, control chars? (best to reject invisible chars, by requiring backslash escapes/converting invisibles to escapes in editing mode)
            guard let c = self.next() else { return .unknown(description: "literal text is missing end quote") } // end of code
            if quotedTextDelimiterCharacters ~= c { return .textLiteral(value: value) } // found closing quote
            // backslash escape
            guard let escapeType = self.next() else { return .unknown(description: "literal text is missing character after backslash") }
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
        return self.next() == nil ? .unknown(description: "quoted identifier is missing end quote") : .identifier(value: value, isQuoted: true) // check for end of code or closing quote
    }
        
    // main
    
    // TO DO: consider making this lazy (see Sequence and IteratorProtocol), e.g. quote balancing analyzer could lazily read start of a line, and if it doesn't look like it's syntactically legal code (e.g. if it finds `IDENTIFIER IDENTIFIER` sequences), it could quickly discard and start over on assumption that line already starts inside quoted text and see how well that works. e.g Each Line analyzer starts by guessing likelihood of being inside or outside quoted text (indentation, recognized operator names, illegal code token sequences, opening/closing typographers quotes, etc can all help generate a % score); if it looks like code([i.e. not inside quotes), it counts any unbalanced closing braces on assumption preceding lines will contain balancing open braces, and counts unbalanced opening braces on expectation that subsequent lines will close those; once all lines are read and imbalances tallied, it can make determination about whether entire program is syntactically correct (and if it is, how likely is that intentional vs accidentally/deliberately misplaced quotes) and, if not, identify where the imbalances occur and make a rough guess at where user most likely needs to add/remove braces to correct this (e.g. if a top-level closing brace is missing near start of script, it *really* doesn't help user to suggest they insert it right at end of script; instead, if unindented handler-like token patterns can be detected on subsequent lines, it is highly likely that the missing brace should be inserted somewhere before the first of those).
    
    func tokenize() -> [TokenInfo] { // note: tokenization should never fail; any issues should be added to token stream for parsers to worry about // TO DO: ensure original lines of source code can be reconstructed from token stream (that will allow ambiguous quoting in per-line reading to be resolved downstream)
        var start = self.index
        var result: [TokenInfo] = [TokenInfo(coercion: .startOfCode, start: start, end: start)]
        if self.code != "" {
            // TO DO: backtrack() calls is ugly; consider using separate `var char:Character?` and `func next()->()`
            while let c = self.next() {
                let token: Token
                if let t = punctuationTokens[c] {
                    token = t
                } else { // TO DO: this won't handle characters composed of >1 code point; will this be an issue?
                    switch c {
                    case quotedTextDelimiterCharacters:
                        token = self.readQuotedText()
                    case quotedIdentifierDelimiterCharacters:
                        token = self.readQuotedIdentifier()
                    case annotationDelimiterCharacters:
                        // TO DO: if depth <> 0 need to handle unbalanced .annotationLiteral (bear in mind that unbalanced block & quote delimiters will be normal in per-line parsing; solution might be to add before and after tally cases to Token so that imbalances are passed on to parser [think double-entry bookkeeping, where each tokenized line is a ledger and the parser's job is to perform a trial balance; once everything balances it can output the final AST])
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
                        token = .annotationLiteral(value) // TO DO: how best to capture value? (for now, just grab the entire "«…»" substring; eventually we should move this to AnnotationType which can process annotation's syntax itself, c.f. OperatorRegistry, and return .comment, .todo, .userdoc, etc)
                    case annotationDelimiterEndCharacters: // found unbalanced "»"
                        token = .annotationLiteralEnd
                    case identifierCharacters: // TO DO: also accept digits after first char
                        var value = String(c)
                        while let c = self.next(ifIn: identifierAdditionalCharacters) { value.append(c) }
                        let name = String(value)
                        let (prefixOperator, infixOperator) = self.operatorRegistry?.matchWord(name) ?? (nil, nil)
                        if prefixOperator == nil && infixOperator == nil {
                            token = .identifier(value: name, isQuoted: false)
                        } else {
                            token = .operatorName(value: name, prefix: prefixOperator, infix: infixOperator)
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
                                token = .symbol(c)
                            }
                        } else {
                            let name = prefixOperator?.name ?? infixOperator!.name
                            token = .operatorName(value: name, prefix: prefixOperator, infix: infixOperator) // TO DO: FIX: token.value is wrong here (it's the canonical operator name but should be the original matched text; it's up to consumer to choose whether to canonicize or not, e.g. when pretty printing); either matchSymbol needs to return the original substring as well as operator definitions, or (if recording code ranges only) we need to capture the start and end indexes of the token; TBH, it'd probably be best to separate out the raw range recording completely, as the outer repeat loop can take care of that
                        }
                    case digitCharacters: // match unsigned number literal; note: assuming stdlib operator tables are loaded, any preceding '+'/'-' symbols will be matched as prefix operators (it's up to parser to optimize these operators away, c.f. AppleScript)
                        self.backtrack() // unconsume digit and let readNumber() [try to] match entire number token
                        token = self.readNumber()
                    case linebreakCharacters: // TO DO: need initializer flag that tells lexer to process entire script or first line only
                        token = .lineBreak
                    case whitespaceCharacters:
                        let value = String(c) + self.readCharacters(ifIn: whitespaceCharacters) // TO DO: should be sufficient to skipCharacters(ifIn:)
                        token = .whitespace(value) // TO DO: is there any situation where the whitespace itself needs to be known? (e.g. indentation)
                    default:
                        token = self.readUnknown(String(c)) // TO DO: is there any value in readUnknown capturing the extracted text? (actually, would be better if .unknown captured the token it had started to parse, if any [e.g. in readNumber()], followed by rest of text up to boundary; editing tools/error reporting can then use that to provide helpful suggestions on how to correct code, including auto-suggest, auto-correct, etc)
                    }
                }
                let end = self.index
                assert(start < end, "Invalid token (cannot be zero length): \(token)") // only .startOfCode/.endOfCode markers are zero-length
                result.append(TokenInfo(coercion: token, start: start, end: end))
                start = end
            }
        }
        result.append(TokenInfo(coercion: .endOfCode, start: self.index, end: self.index))
        return result
    }
}

