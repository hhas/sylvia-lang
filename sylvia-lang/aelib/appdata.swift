//
//  aelib.swift
//

import SwiftAutomation


// TO DO: cache glue tables for reuse (TO DO: how practical to have a global on-disk cache? this'd need to know each app's bundle ID and version so that it can reload correct terms for target app, and invalidate old entries when a newer version of app is found; caveat some [pro] apps, e.g. Adobe CC/MS Office, may have multiple versions installed)


// TO DO: singular element names also need to be added to elementsByName table, e.g. `document at 1` currently doesn't work (also need elementsByCode Singular/Plural tables for pretty printer to use); either add extra elementsSingular dict to AETE/SDEF parsers or subclass KeywordTerm to hold both singular and plural names for elements



/******************************************************************************/
// application command


class RemoteCall: CallableValue {
    
    override var description: String { return "«\(self.definition) of \(self.parent)»" } // TO DO: native formatting

    
    let parent: Reference
    let definition: CommandTerm
    let appData: NativeAppData
    
    var interface: CallableInterface {
        fatalError() // CallableInterface(name: String, parameters: [(name, asAnything),…], returnType: asIs)
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // TO DO: how to support returnType coercions? (they should drive unpacking, which means reply AE needs to present as Value wrapper with toTYPE methods that drive the actual AE unpacking, e.g. by coercing the wrapped descriptor to the appropriate AE type; presumably AEList [and AERecord?] descs will need to be custom-unpacked)
        
        // TO DO: time to implement labeled parameters in handlers: AsParameter needs to accept Pair(Identifier,EXPR), where EXPR may be 'as' command
        
        fatalError()
    }
    
    init(_ parent: Reference, definition: CommandTerm, appData: NativeAppData) {
        self.parent = parent
        self.definition = definition
        self.appData = appData
    }
}


/******************************************************************************/
// target address, terminology tables, codecs


class NativeAppData: AppData {
    
    let glueTable: GlueTable
    
    public required init(applicationURL: URL, useTerminology: TerminologyType = .sdef) throws {
        let glueTable = GlueTable(keywordConverter: nativeKeywordConverter, allowSingularElements: true)
        // temporary; TO DO: if .aete or URL not available, use getAETE, else if .sdef use SDEF
        switch useTerminology {
        case .sdef: try glueTable.add(SDEF: applicationURL)
        case .aete: try glueTable.add(AETE: AEApplication(url: applicationURL).getAETE())
        default: ()
        }
        self.glueTable = glueTable
        let specifierFormatter = SpecifierFormatter(applicationClassName: "Application",
                                                    classNamePrefix: "",
                                                    typeNames: glueTable.typesByCode,
                                                    propertyNames: glueTable.propertiesByCode,
                                                    elementsNames: glueTable.elementsByCode)

        let glueClasses = GlueClasses(insertionSpecifierType: AEInsertion.self, objectSpecifierType: AEItem.self,
                                      multiObjectSpecifierType: AEItems.self, rootSpecifierType: AERoot.self,
                                      applicationType: AERoot.self, symbolType: AESymbol.self, formatter: specifierFormatter) // TO DO: check how this unpacks (c.f. py-appscript, should be fine as long as there's a native wrapper around specifier and a formatter that knows how to navigate and format both native and Swift values)
        super.init(target: TargetApplication.url(applicationURL),
                  launchOptions: DefaultLaunchOptions, relaunchMode: DefaultRelaunchMode, glueClasses: glueClasses)
    }
    
    
    required init(target: TargetApplication, launchOptions: LaunchOptions, relaunchMode: RelaunchMode, glueClasses: GlueClasses) { // TO DO: nasty
        fatalError()
    }

    //
    
    override func pack(_ value: Any) throws -> NSAppleEventDescriptor {
        switch value {
        case let symbol as Symbol:
            guard let desc = self.glueTable.typesByName[symbol.key] else { return try super.pack(value) } // TO DO: throw 'unknown symbol' error here
            return desc
        default:
            return try super.pack(value)
        }
    }
    
}



