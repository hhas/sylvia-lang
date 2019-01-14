//
//  reference.swift
//


/* AS compatibility notes:
 
 - where property name and element name collide (e.g. 'document' in TextEdit), it is packed as property specifier unless an explicit selector (`named`, `every`, etc) is applied
 
 - one exception to above is 'text', which is packed as all-elements specifier by default (presumably because AS's own definition of this term as class/element name takes precedence over the app's own); in practice, while TextEdit defines 'text' as a property, it accepts an all-elements specifier (other apps may depend on AS's quirk so for compatibility this should be mimicked)
 
 */

import SwiftAutomation

// TO DO: implement extensions for Text, List, Nothing (what else)

// public protocol SelfPacking {
//    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor
// }



class RemoteCall: CallableValue {
    
    let parent: Reference
    let definition: CommandTerm
    let appData: NativeAppData
    
    var interface: CallableInterface {
        fatalError() // CallableInterface(name: String, parameters: [(name, asAnything),…], returnType: asIs)
    }
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // TO DO: how to support returnType coercions?
        fatalError()
    }
    
    init(_ parent: Reference, definition: CommandTerm, appData: NativeAppData) {
        self.parent = parent
        self.definition = definition
        self.appData = appData
    }
}


//


class Reference: AttributedValue { // abstract base class
    
    // TO DO: callable? (c.f. nodeautomation, where calling a property/elements specifier is shorthand for `get()`); shouldn't be needed, as `get REFERENCE` does the same and is more idiomatic
    
    // similar arrangement to py-appscript/py-aem, where Reference is high-level terminology-based wrapper around low-level four-char-code-based API (one reason for this arrangement, rather than reimplementing entire AE bridge here, is it'll gives native->Swift cross-compiler plenty flexibility when baking scripts as mixed/pure Swift code: pure-Swift bakes can use SwiftAutomation directly, while mixed bakes can wrap and unwrap Reference values when passing them between native and Swift sections); it also [in principle] allows primitive libraries to use SwiftAutomation themselves (even with static glues), although how to re-box these will require some thought (since SA specifiers do not normally contain NativeAppData instance)
    
    let appData: NativeAppData // TO DO: when unpacking Swift[Automation] Specifiers, use basic AppData? or is NativeAppData.unpack() guaranteed to return appropriate Swift types for both native and Swift use? (IIRC, py-appscript had to use aem.Codecs to unpack aem specifiers)
    
    init(appData: NativeAppData) {
        self.appData = appData
    }
    
    func set(_ key: String, to value: Value) throws { // TO DO: only implement if using unified 'set' command to cover all all assignment-type operations (currently env assignment uses `store` whereas AE bridge uses `set`)
        fatalError()
    }
    
    func get(_ key: String) throws -> Value {
        switch key {
        // this is counter-intuitive, but `at`, `named`, etc handlers are looked up on parent object
        case "at":
            return IndexSelector(for: self)
        case "named":
            return NameSelector(for: self)
        case "for_id": // TO DO: need standard naming convention
            return IDSelector(for: self)
        case "where":
            return TestSelector(for: self)
        case "send_apple_event":
            fatalError() // TO DO: needs to return callable that takes AE codes + raw params
        default:
            if let command = self.appData.glueTable.commandsByName[key] {
                return RemoteCall(self, definition: command, appData: self.appData)
            } else {
                print(self.appData.glueTable.propertiesByName)
                print(self.appData.glueTable.elementsByName)
                throw UnrecognizedAttributeError(name: key, value: self)
            }
        }
    }
}



class SingleReference: SelfPackingReference, SelfPacking { // property or single element; by-index, by-name, by-id, relative, first/middle/last
    
    // AERoots are defined on AEItem.appData
    
    override var description: String { return "«\(self.swiftValue)»" } // TO DO: native formatting
    
    let swiftValue: AEItem // a SwiftAutomation ObjectSpecifier containing basic AppData and NSAppleEventDescriptor
    
    init(_ specifier: AEItem, appData: NativeAppData) {
        self.swiftValue = specifier
        super.init(appData: appData)
    }
    
    override func get(_ key: String) throws -> Value {
        switch key {
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
            if let code = self.appData.glueTable.propertiesByName[key]?.code {
                return SingleReference(self.swiftValue.property(code), appData: appData)
            } else if let code = self.appData.glueTable.elementsByName[key]?.code {
                return MultipleReference(self.swiftValue.elements(code), appData: appData)
            } else {
                return try super.get(key)
            }
        }
    }
}

class MultipleReference: SingleReference, Selectable, Callable {
    
    // zero or more elements; by-range, by-test, all
    
    let _swiftValue: AEItems
    
    init(_ specifier: AEItems, appData: NativeAppData) {
        self._swiftValue = specifier
        super.init(specifier, appData: appData)
    }
    
    override func get(_ key: String) throws -> Value {
        switch key {
        case "first":
            return SingleReference(self._swiftValue.first, appData: self.appData)
        case "middle":
            return SingleReference(self._swiftValue.middle, appData: self.appData)
        case "last":
            return SingleReference(self._swiftValue.last, appData: self.appData)
        case "any":
            return SingleReference(self._swiftValue.any, appData: self.appData)
        case "every":
            return self
        case "beginning":
            return InsertionReference(self._swiftValue.beginning, appData: self.appData)
        case "end":
            return InsertionReference(self._swiftValue.beginning, appData: self.appData)
        default:
            return try super.get(key)
        }
    }
    
    func byIndex(_ selectorData: Value) throws -> Value {
        // TO DO: could do with explicit methods on SpecifierExtensions
        if let range = selectorData as? Range {
            return MultipleReference(self._swiftValue[range.start, range.stop], appData: self.appData)
        } else {
            return SingleReference(self._swiftValue[selectorData], appData: self.appData)
        }
    }
    
    func byName(_ selectorData: Value) throws -> Value {
        return SingleReference(self._swiftValue.named(selectorData), appData: self.appData)
    }
    
    func byID(_ selectorData: Value) throws -> Value {
        return SingleReference(self._swiftValue.ID(selectorData), appData: self.appData)
    }
    
    func byTest(_ selectorData: Value) throws -> Value {
        fatalError()
        //return MultipleReference(self.swiftValue[test], appData: self.appData)
    }
    
    
    let interface = CallableInterface(name: "XXXX", parameters: [("selector_data", asValue)], returnType: asReference)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        let arg_0 = try asValue.unboxArgument(at: 0, command: command, commandEnv: commandEnv, handler: self)
        if (try? asInt.unbox(value: arg_0, env: commandEnv)) != nil {
            return try self.byIndex(arg_0)
        } else if (try? asString.unbox(value: arg_0, env: commandEnv)) != nil {
            return try self.byName(arg_0)
        }
        return try self.byIndex(arg_0)
    }

}



class InsertionReference: SelfPackingReference, SelfPacking { // beginning/end/before/after
    
    let swiftValue: AEInsertion
    
    init(_ specifier: AEInsertion, appData: NativeAppData) {
        self.swiftValue = specifier
        super.init(appData: appData)
    }
    
}

// note: by-range/by-test handler will supply full terminology and the appropriate relative root, so no need for appscript-style 'generic references' or `app`/`con`/`its` globals


class Application: SelfPackingReference, Callable {

    // TO DO: want this to be exposed as value which is callable/selectable (need to start thinking in terms of namespaces, c.f. Frontier) // this'll need to be instantiated as current application, with callable interface
    
    override var description: String { return "«\(self.swiftValue)»" } // TO DO: native formatting
    
    override class var nominalType: Coercion { return asReference }
    
    let swiftValue: AEApplication
    
    init() throws {
        self.swiftValue = AEApplication.currentApplication()
        super.init(appData: try NativeAppData(applicationURL: URL(fileURLWithPath: "/Applications/TextEdit.app"), useTerminology: .sdef)) // cheat
    }
    
    init(name: String) throws { // temporary
        // TO DO: if swiftValue.appData.target != current application then throw as it's already targeted
        
        guard let url = fileURLForLocalApplication(name) else { throw GeneralError("App not found: \(name)") }
        
        let appData = try NativeAppData(applicationURL: url) // TO DO: pass target, launchOptions, relaunchMode, useTerminology arguments

        self.swiftValue = AEApplication(rootObject: AppRootDesc, appData: appData)
        super.init(appData: appData)
    }
    
    /*
     init(name: String, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     
     init(url: URL, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     
     init(bundleIdentifier: String, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     
     init(processIdentifier: pid_t, launchOptions: LaunchOptions = DefaultLaunchOptions, relaunchMode: RelaunchMode = DefaultRelaunchMode)
     */
    
    override func get(_ name: String) throws -> Value {
        //print("\(self) looking up \(name)")
        switch name {
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
