//
//  aelib.swift
//

import SwiftAutomation


// TO DO: subclass AppData or not? // what about using AppleEventFormatter.swift's existing DynamicAppData class? (there is already a TODO on this)


//let appData = try DynamicAppData(applicationURL: URL(fileURLWithPath: "/Applications/TextEdit.app"), useTerminology: .aete)

class NativeAppData: DynamicAppData {
    
    public convenience init(applicationURL: URL, useTerminology: TerminologyType = .sdef) throws {
        let glueSpec = GlueSpec(applicationURL: applicationURL, useSDEF: useTerminology == .sdef) // TO DO: GlueSpec should be protocol
        var specifierFormatter: SpecifierFormatter
        var glueTable: GlueTable
        if useTerminology == .none {
            glueTable = GlueTable(keywordConverter: glueSpec.keywordConverter) // default terms only
            specifierFormatter = SpecifierFormatter(applicationClassName: "AEApplication", classNamePrefix: "AE") // TO DO: needs to use native formatter
        } else {
            glueTable = try glueSpec.buildGlueTable()
            specifierFormatter = SpecifierFormatter(applicationClassName: glueSpec.applicationClassName,
                                                    classNamePrefix: glueSpec.classNamePrefix,
                                                    typeNames: glueTable.typesByCode,
                                                    propertyNames: glueTable.propertiesByCode,
                                                    elementsNames: glueTable.elementsByCode)
        }
        let glueClasses = GlueClasses(insertionSpecifierType: AEInsertion.self, objectSpecifierType: AEItem.self,
                                      multiObjectSpecifierType: AEItems.self, rootSpecifierType: AERoot.self,
                                      applicationType: AERoot.self, symbolType: AESymbol.self, formatter: specifierFormatter) // TO DO: check how this unpacks (c.f. py-appscript, should be fine as long as there's a native wrapper around specifier and a formatter that knows how to navigate and format both native and Swift values)
        self.init(target: TargetApplication.url(applicationURL), launchOptions: DefaultLaunchOptions,
                  relaunchMode: DefaultRelaunchMode, glueClasses: glueClasses, glueSpec: glueSpec, glueTable: glueTable)
    }
    
}



// TO DO: watch out for mutable lists being used in a specifier, e.g. `…where REFERENCE is_in MUTABLE_LIST`; ideally all Values used in specifiers should be evaluated immediately with `AsImmutable(…)` coercion

