//
//  reference.swift
//

import SwiftAutomation


let ofClauseHandler = PrimitiveHandler(interface_ofClause_attribute_value_commandEnv, function_ofClause_attribute_value_commandEnv)



class RemoteCall: CallableValue {
    
    let parent: Reference
    let definition: CommandTerm
    let appData: DynamicAppData
    
    var interface: CallableInterface {
        fatalError() // CallableInterface(name: String, parameters: [(name, asAnything),…], returnType: asIs)
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // TO DO: how to support returnType coercions?
        fatalError()
    }
    
    init(_ parent: Reference, definition: CommandTerm, appData: DynamicAppData) {
        self.parent = parent
        self.definition = definition
        self.appData = appData
    }
}


class Reference: AttributedValue { // abstract base class
    
    // TO DO: callable? (c.f. nodeautomation, where calling a property/elements specifier is shorthand for `get()`); shouldn't be needed, as `get REFERENCE` does the same and is more idiomatic
    
    // similar arrangement to py-appscript/py-aem, where Reference is high-level terminology-based wrapper around low-level four-char-code-based API (one reason for this arrangement, rather than reimplementing entire AE bridge here, is it'll gives native->Swift cross-compiler plenty flexibility when baking scripts as mixed/pure Swift code: pure-Swift bakes can use SwiftAutomation directly, while mixed bakes can wrap and unwrap Reference values when passing them between native and Swift sections); it also [in principle] allows primitive libraries to use SwiftAutomation themselves (even with static glues), although how to re-box these will require some thought (since SA specifiers do not normally contain DynamicAppData instance)
    
    let appData: NativeAppData // TO DO: when unpacking Swift[Automation] Specifiers, use basic AppData? or is DynamicAppData.unpack() guaranteed to return appropriate Swift types for both native and Swift use? (IIRC, py-appscript had to use aem.Codecs to unpack aem specifiers)
    
    init(appData: NativeAppData) {
        self.appData = appData
    }
    
    func set(_ name: String, to value: Value) throws { // TO DO: only implement if using unified 'set' command to cover all all assignment-type operations (currently env assignment uses `store` whereas AE bridge uses `set`)
        fatalError()
    }
    
    func get(_ name: String) throws -> Value {
        if let command = self.appData.glueTable.commandsByName[name] {
            return RemoteCall(self, definition: command, appData: self.appData)
        } else if name == "send_apple_event" {
            fatalError() // TO DO: needs to return callable that takes AE codes + raw params
        } else {
            print(self.appData.glueTable.propertiesByName)
            print(self.appData.glueTable.elementsByName)
            throw UnrecognizedAttributeError(name: name, value: self)
        }
    }
}


class SingleReference: Reference { // property or single element; by-index, by-name, by-id, relative, first/middle/last
    
    // AERoots are defined on AEItem.appData
    
    override var description: String { return "«\(self.swiftValue)»" } // TO DO: native formatting
    
    private let swiftValue: AEItem // a SwiftAutomation ObjectSpecifier containing basic AppData and NSAppleEventDescriptor
    
    init(_ specifier: AEItem, appData: NativeAppData) {
        self.swiftValue = specifier
        super.init(appData: appData)
    }
    
    override func get(_ name: String) throws -> Value {
        switch name {
        case "every":
            fatalError() // TO DO: return MultipleReference(self.swiftValue.all, appData: self.appData); need to implement ObjectSpecifierExtension.all first (this converts existing property specifier to all-elements specifier, allowing user to disambiguate conflicting terminology where a property name and elements name are identical, in which case the property definition would normally take priority [in AS, one exception is `text`, which defaults to all-elements definition by default])
        case "previous": // `ELEMENT_TYPE before ELEMENT_REFERENCE`
            fatalError()
        case "next": // `ELEMENT_TYPE after ELEMENT_REFERENCE`
            fatalError() // TO DO: return RelativeSelector(for: self, position: name) // Callable that takes Symbol (typeClass) as sole argument
        case "before": // `before ELEMENT_REFERENCE`
            return InsertionReference(self.swiftValue.before, appData: self.appData)
        case "after": // `after ELEMENT_REFERENCE`
            return InsertionReference(self.swiftValue.after, appData: self.appData)
        case "property_for_code": // property by four-char-code
            fatalError() // return SingleReference(self.swiftValue.property(0), appData: appData) // TO DO: needs to return `property` callable
        case "elements_for_code": // all-elements by four-char-code
            fatalError() // return MultipleReference(self.swiftValue.elements(0), appData: appData) // TO DO: needs to return `elements` callable
        default:
            if let code = self.appData.glueTable.propertiesByName[name]?.code {
                return SingleReference(self.swiftValue.property(code), appData: appData)
            } else if let code = self.appData.glueTable.elementsByName[name]?.code {
                return MultipleReference(self.swiftValue.elements(code), appData: appData)
            } else {
                return try super.get(name)
            }
        }
    }
}

class MultipleReference: SingleReference, Selectable {
    
    // zero or more elements; by-range, by-test, all
    
    private let swiftValue: AEItems
    
    init(_ specifier: AEItems, appData: NativeAppData) {
        self.swiftValue = specifier
        super.init(specifier, appData: appData)
    }
    
    override func get(_ name: String) throws -> Value {
        switch name {
        case "at":
            return IndexSelector(for: self)
        case "named":
            return NameSelector(for: self)
        case "for_id": // TO DO: need standard naming convention
            return IDSelector(for: self)
        case "where":
            return TestSelector(for: self)
        case "first":
            return SingleReference(self.swiftValue.first, appData: self.appData)
        case "middle":
            return SingleReference(self.swiftValue.middle, appData: self.appData)
        case "last":
            return SingleReference(self.swiftValue.last, appData: self.appData)
        case "any":
            return SingleReference(self.swiftValue.any, appData: self.appData)
        case "every":
            return self
        case "beginning":
            return InsertionReference(self.swiftValue.beginning, appData: self.appData)
        case "end":
            return InsertionReference(self.swiftValue.beginning, appData: self.appData)
        default:
            return try super.get(name)
        }
    }
    
    func byIndex(_ selectorData: Value) throws -> Value {
        // TO DO: could do with explicit methods on SpecifierExtensions
        if let range = selectorData as? Range {
            return MultipleReference(self.swiftValue[range.start, range.stop], appData: self.appData)
        } else {
            return SingleReference(self.swiftValue[selectorData], appData: self.appData)
        }
    }
    
    func byName(_ selectorData: Value) throws -> Value {
        return SingleReference(self.swiftValue.named(selectorData), appData: self.appData)
    }
    
    func byID(_ selectorData: Value) throws -> Value {
        return SingleReference(self.swiftValue.ID(selectorData), appData: self.appData)
    }
    
    func byTest(_ selectorData: Value) throws -> Value {
        fatalError()
        //return MultipleReference(self.swiftValue[test], appData: self.appData)
    }
}

class InsertionReference: Reference { // beginning/end/before/after
    
    private var swiftValue: AEInsertion
    
    init(_ specifier: AEInsertion, appData: NativeAppData) {
        self.swiftValue = specifier
        super.init(appData: appData)
    }
    
}

// note: by-range/by-test handler will supply full terminology and the appropriate relative root, so no need for appscript-style 'generic references' or `app`/`con`/`its` globals


class Application: Reference, Callable {

    // TO DO: want this to be exposed as value which is callable/selectable (need to start thinking in terms of namespaces, c.f. Frontier) // this'll need to be instantiated as current application, with callable interface
    
    override var description: String { return "«\(self.swiftValue)»" } // TO DO: native formatting
    
    override class var nominalType: Coercion { return asReference }
    
    private var swiftValue: AEApplication
    
    init() throws {
        self.swiftValue = AEApplication.currentApplication()
        super.init(appData: try NativeAppData(applicationURL: URL(fileURLWithPath: "/Applications/TextEdit.app"), useTerminology: .sdef)) // cheat
    }
    
    init(name: String) throws { // temporary
        // TO DO: if swiftValue.appData.target != current application then throw as it's already targeted
        guard let url = fileURLForLocalApplication(name) else { throw GeneralError("App not found: \(name)") }
        self.swiftValue = AEApplication(url: url)
        let appData = try NativeAppData(applicationURL: url) // TO DO: need to rework this initializer (might be simpler for it to take an AEApplication instance, in which case it can work out whether to call OSACopyScriptingDefinitionForURL() or send `ascrgdte` event for itself)
        super.init(appData: appData)
    }
    
    /*
     init(name: String, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     
     init(url: URL, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     
     init(bundleIdentifier: String, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     
     init(processIdentifier: pid_t, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     */
    
    override func get(_ name: String) throws -> Value {
        switch name {
        /*
        case "at": // TO DO: callable and/or selector, e.g. `app "TextEdit`, app (named: "TextEdit", options: …) // TO DO: when identifying app by full path, would be better to use namespace rather than path string; TO DO: bear in mind that identifying apps by name/path will be restricted in sandboxed processes (those should generally use bundle ID); if so, get rid of `at` and use `named` for name-only and `for_id` for bundle/process ID; when dealing with local apps by path, navigate the local filesystem subtreel when dealing with remote apps by eppc, create a remote host mount point and use app in a `tell HOST` block (HOST would only know its domain name/IP address, so let them sort out the URL protocol and rest of URL between them [in an ideal world, local client would ask HOST server what services it provides via RESTful GET application/host-services query and get URLs out of that; a sensible system would require server admin to explicitly publish each app they want to make externally visible, in essence managing each desktop app same as it would a web app])
            fatalError()
        case "named":
            fatalError()
        case "for_id":
            fatalError()
        */
        default:
            if let code = self.appData.glueTable.propertiesByName[name]?.code {
                return SingleReference(self.swiftValue.property(code), appData: appData)
            } else if let code = self.appData.glueTable.elementsByName[name]?.code {
                return MultipleReference(self.swiftValue.elements(code), appData: appData)
            } else {
                return try super.get(name)
            }
        }
    }
    
    let interface = CallableInterface(name: "app", parameters: [("name", asString)], returnType: asReference)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let arg_0 = try asString.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        return try Application(name: arg_0)
    }

}





func aelib_loadConstants(env: Env) throws {
    try env.set("app", to: Application()) // instantiate a single Application value for adding to module; this value identifies current application as default, but can be targeted to anything else
}
