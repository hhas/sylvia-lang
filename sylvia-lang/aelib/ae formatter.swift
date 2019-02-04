//
//  ae formatter.swift
//

import Foundation
import SwiftAutomation


class NativeFormatter { // TO DO: see notes on SpecifierFormatter (either make it open to allow subclassing, or define a SpecifierFormatterProtocol)
    
    let appData: NativeAppData
    
    required init(appData: NativeAppData) {
        self.appData = appData
    }
    
    // TO DO: improve naming conventions, e.g. `format(object: Any)`, `format(symbol:Symbol)`
    
    func format(_ object: Any) -> String { // TO DO: optional `nested: Bool = false` parameter
        return String(describing: object)
    }
}
