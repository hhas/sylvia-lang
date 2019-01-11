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
    
    public func escapeName(_ s: String) -> String { return "\(s)_" } // escape any app-defined names that conflict with specifier attributes (this should rarely be needed in practice)
    
    
    func convertName(_ string: String, reservedWords: Set<String>) -> String { // Convert string to identifier
        if let result = self._cache[string] {
            return result
        } else {
            // convert keyword to underscore_name, e.g. "audio CD playlist" -> "audio_CD_playlist"; any other non-identifier characters will require the user/pretty-printer to single-quote the name to use it as an identifier, e.g. Finder's "desktop-object" must be written as `'desktop-object'`
            let result = string.replacingOccurrences(of: " ", with: "_")
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
    
    public func identifierForAppName(_ appName: String) -> String { return "" }
    
    public func prefixForAppName(_ appName: String) -> String { return "" }
    
}
