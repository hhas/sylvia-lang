//
//  aelib_keywords.swift
//

import Foundation
import SwiftAutomation



let reservedNativeKeywords: Set<String> = [] // TO DO: SDEF-defined names that collide with operator names should normally be disambiguated using standard single-quoting mechanism; however, frequently-used names that are known to collide might be easier dealt with by



// Swift glue methods

public let reservedSpecifierMethods: Set<String> = [ // TO DO: revise
    // custom property/element specifiers // TBC
    // Specifier
    // TO DO: `property(CODE)`, `elements(CODE)`, `send_apple_event(CODES,…)` are functionally equivalent to using raw chevron syntax in AS, so might want to be named more descriptively (e.g. `raw_property`, `raw_elements`; `raw_property` might come in two versions, one for AE code, the other for identifier name, avoiding need to define separate 'user_property' [TBH, formUserProperty and kASSubroutineEvent are only really used when sending AEs to traditional AppleScript applets])
    "property",
    "user_property",
    "elements",
    "send_apple_event",
    "call_user_subroutine",
    // Application
    "current_application",
    "custom_root",
    "is_running",
    "launch",
    "do_transaction",
    // Selectors // note: some/all of these will need to be defined as operators for readability, e.g. `document named "README"` rather than `document.named("README")`; need to figure how to inject library-defined operators safely (although some/all of these selectors will be defined in stdlib for use in native chunk expressions, e.g. for filtering lists, which might let us dodge the issue at least for this library)
    "at",
    "named",
    "id", // TO DO: `id` is also used as a property name, so might want to rename selector to (e.g.) `with_ID`
    "where",
    "beginning",
    "end",
    "before",
    "after",
    "previous",
    "next",
    "first",
    "middle",
    "last",
    "any",
    "all",
    // Test clauses
    "begins_with",
    "ends_with",
    "contains",
    "is_in",
    // Symbol (class methods only)
    "symbol",
]


public let reservedParameterNames: Set<String> = [
    // standard parameter/attribute names used in commands // TBC
    "direct_parameter",
    "wait_reply", // TO DO: how practical to support async out of the box? (in which case, pass a completion callback as separate argument?)
    "with_timeout",
    "considering", // TO DO: can this be reliably inferred from Coercions? (see TODO below)
    "result_type", // TO DO: can this be reliably inferred from Coercions? (as with considering/ignoring, transactions, and unit types, this part of AE API is poorly specced and underpowered, so may be best to stick with 'dumb' implementation for now)
]




/******************************************************************************/
// Identifiers (legal characters, reserved names, etc)

// TO DO: while SDEFs normally use C-style naming conventions, this ought to support non-ASCII characters for completeness/future-proofing; probably best to use same CharacterSets as Lexer

let uppercaseChars    = Set<Character>("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
let lowercaseChars    = Set<Character>("abcdefghijklmnopqrstuvwxyz")
let numericChars      = Set<Character>("0123456789")
let interstitialChars = Set<Character>("_")
let whitespaceChars   = Set<Character>(" \t\n\r")



let legalFirstChars = uppercaseChars.union(lowercaseChars).union(interstitialChars)
let legalOtherChars = uppercaseChars.union(lowercaseChars).union(interstitialChars).union(numericChars)
let reservedWordSeparators = whitespaceChars.union("-/") // some AETEs may include hyphens and other non-C-identifier/non-space characters in their keyword names, which are problematic in AppleScript (which [e.g.] compiles `trash-object` to `trash - object`) and a PITA in traditionally C-like languages, so we just bite the bullet and treat them all as if they were just simple spaces between words




class NativeKeywordConverter: KeywordConverterProtocol {
    
    private var _cache = [String:String]()
    
    public func escapeName(_ s: String) -> String { // note: names don't need to be escaped if quoted instead
        return "\(s)_"
    }
    
    
    func convertName(_ string: String, reservedWords: Set<String>) -> String { // Convert string to identifier
        if let result = self._cache[string] {
            return result
        } else {
            // convert keyword to underscore_name, e.g. "audio CD playlist" -> "audio_CD_playlist"
            var result = ""
            var i = string.startIndex
            var charSet = legalFirstChars
            while i < string.endIndex {
                while i < string.endIndex && reservedWordSeparators.contains(string[i]) { // skip whitespace, hyphen, slash
                    i = string.index(after: i)
                }
                while i < string.endIndex {
                    let c = string[i]
                    if charSet.contains(c) { // TO DO: AETE/SDEF resources generally stick to C-style naming convention, although there's no restriction on using non-ASCII characters
                        result += String(c)
                    } else if reservedWordSeparators.contains(c) {
                        result += "_"
                    } else if numericChars.contains(c) { // first character in name is a digit (this should never be encountered in practice, but there's no validation or enforcement of naming conventions in SDEF, so we protect ourselves)
                        result += "_\(String(c))"
                    } else if c == "&" {
                        result += "_and_"
                    } else {
                        result += String(c)
                        // TO DO: set an 'alwaysQuoteIdentifier' flag as hint to pretty printer?
                    }
                    i = string.index(after: i)
                    charSet = legalOtherChars
                    willCapitalize = false
                }
                willCapitalize = true
            }
            if reservedWords.contains(result) || result.hasPrefix("_") || result == "" {
                result = self.escapeName(result)
            }
            self._cache[string] = String(result)
            return result
        }
    }
    
    
    
    
    private static var _defaultTerminology: ApplicationTerminology?
    
    public var defaultTerminology: ApplicationTerminology { // initialized on first use
        if type(of: self)._defaultTerminology == nil {
            type(of: self)._defaultTerminology = DefaultTerminology(keywordConverter: self)
        }
        return type(of: self)._defaultTerminology!
    }
    
    private let _reservedSpecifierWords = reservedNativeKeywords.union(reservedSpecifierMethods)
    private let _reservedParameterWords = reservedNativeKeywords.union(reservedParameterNames)
    private let _reservedPrefixes = reservedNativeKeywords.union(reservedPrefixes)
    
    public func convertSpecifierName(_ s: String) -> String {
        return self.convertName(s, reservedWords: self._reservedSpecifierWords)
    }
    
    public func convertParameterName(_ s: String) -> String {
        return self.convertName(s, reservedWords: self._reservedParameterWords)
    }
    
    public func identifierForAppName(_ appName: String) -> String {
        return ""
    }
    
    public func prefixForAppName(_ appName: String) -> String {
        return ""
    }
    
}
