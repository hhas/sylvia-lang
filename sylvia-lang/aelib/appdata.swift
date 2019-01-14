//
//  aelib.swift
//

import SwiftAutomation


// TO DO: cache glue tables for reuse


// TO DO: singular element names also need to be added to elementsByName table, e.g. `document at 1` currently doesn't work (also need elementsByCode Singular/Plural tables for pretty printer to use); either add extra elementsSingular dict to AETE/SDEF parsers or subclass KeywordTerm to hold both singular and plural names for elements



protocol SelfPackingWrapper: SelfPacking {
    
    associatedtype SpecifierType where SpecifierType: SelfPacking
    
    var swiftValue: SpecifierType { get }
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor
}

extension SelfPackingWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        return try swiftValue.SwiftAutomation_packSelf(appData)
    }
}

typealias SelfPackingReference = Reference & SelfPackingWrapper



//


class NativeAppData: AppData {
    
    let glueTable: GlueTable
    
    public required init(applicationURL: URL, useTerminology: TerminologyType = .sdef) throws {
        // TO DO: GlueSpec is not helpful for dynamic bridges
        let glueSpec = GlueSpec(applicationURL: applicationURL, useSDEF: useTerminology == .sdef) // TO DO: GlueSpec should be protocol //  `useSDEF` arg should be TerminologyType, avoiding need for conditional below (just call buildGlueTable each time)
        if useTerminology == .none { // TO DO: get rid of this conditional
            self.glueTable = GlueTable(keywordConverter: glueSpec.keywordConverter) // default terms only
        } else {
            self.glueTable = try glueSpec.buildGlueTable() // TO DO: caution: this currently requires applicationURL (having originally been written for static glue generation)
        }
        let specifierFormatter = SpecifierFormatter(applicationClassName: "Application",
                                                    classNamePrefix: "",
                                                    typeNames: glueTable.typesByCode,
                                                    propertyNames: glueTable.propertiesByCode,
                                                    elementsNames: glueTable.elementsByCode)

        let glueClasses = GlueClasses(insertionSpecifierType: AEInsertion.self, objectSpecifierType: AEItem.self,
                                      multiObjectSpecifierType: AEItems.self, rootSpecifierType: AERoot.self,
                                      applicationType: AERoot.self, symbolType: AESymbol.self, formatter: specifierFormatter) // TO DO: check how this unpacks (c.f. py-appscript, should be fine as long as there's a native wrapper around specifier and a formatter that knows how to navigate and format both native and Swift values)
        
        //self.init(target: TargetApplication.url(applicationURL), launchOptions: DefaultLaunchOptions,
        //          relaunchMode: DefaultRelaunchMode, glueClasses: glueClasses, glueSpec: glueSpec, glueTable: glueTable)
        
        super.init(target: TargetApplication.url(applicationURL),
                  launchOptions: DefaultLaunchOptions, relaunchMode: DefaultRelaunchMode, glueClasses: glueClasses)
    }
    
    
    required init(target: TargetApplication, launchOptions: LaunchOptions, relaunchMode: RelaunchMode, glueClasses: GlueClasses) { // TO DO: nasty
        fatalError()
    }
    
    // TO DO: use following AppData initializer:
    //
    // public required init(target: TargetApplication, launchOptions: LaunchOptions, relaunchMode: RelaunchMode, glueClasses: GlueClasses) {

}



// TO DO: watch out for mutable lists being used in a specifier, e.g. `…where REFERENCE is_in MUTABLE_LIST`; ideally all Values used in specifiers should be evaluated immediately with `AsImmutable(…)` coercion




// TO DO: implement extensions for Text, List, Nothing (what else?) that implement SelfPacking

// public protocol SelfPacking {
//    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor
// }
