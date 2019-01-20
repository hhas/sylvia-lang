//
//  reference.swift
//


/* AS compatibility notes:
 
 - where property name and element name collide (e.g. 'document' in TextEdit), it is packed as property specifier unless an explicit selector (`named`, `every`, etc) is applied
 
 - one exception to above is 'text', which is packed as all-elements specifier by default (presumably because AS's own definition of this term as class/element name takes precedence over the app's own); in practice, while TextEdit defines 'text' as a property, it accepts an all-elements specifier (other apps may depend on AS's quirk so for compatibility this should be mimicked)
 
 */

// by-range/by-test handlers supply full terminology and the appropriate relative root when evaluating selectorData, so no need for appscript-style 'generic references' or `app`/`con`/`its` globals // TO DO: as with `tell` blocks, still need to decide how to chain lookups (in this case it should be easy: just create custom sub-scope of command env and 'populate' that)

// TO DO: need to decide class naming convention, as core/stdlib will presumably implement its own Reference class for chunk expressions (also, should aelib references present as same type as core references?)

// TO DO: watch out for mutable lists being used in a specifier, e.g. `…where REFERENCE is_in MUTABLE_LIST`; ideally all Values used in specifiers should be evaluated immediately with `AsImmutable(…)` coercion


import SwiftAutomation


/******************************************************************************/


protocol SelfPackingReferenceWrapper: SelfPacking, PrimitiveWrapper {
    
    associatedtype SpecifierType where SpecifierType: SelfPacking
    
    var swiftValue: SpecifierType { get }
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor
}

extension SelfPackingReferenceWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        return try swiftValue.SwiftAutomation_packSelf(appData)
    }
}

typealias SelfPackingReference = Reference & SelfPackingReferenceWrapper


//


class Reference: AttributedValue { // abstract base class
    
    override class var nominalType: Coercion { return asReference }
    
    var specifier: Specifier { fatalError("Subclasses must override.") }
    
    // TO DO: callable? (c.f. nodeautomation, where calling a property/elements specifier is shorthand for `get()`); shouldn't be needed, as `get REFERENCE` does the same and is more idiomatic -- A. NO, as calling a reference is shorthand for by-index/by-name element selector
    
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
                //print("`\(key)` not found in \(self)") // DEBUG
                throw ValueNotFoundError(name: key, env: self) // TO DO: would it be safe to delegate to commandEnv here? (bearing in mind that it'll need set first? Or can we trust)
            }
        }
    }
}


/******************************************************************************/
// concrete reference classes
//
// - single-object specifier (attribute or one-to-one relationship)
// - multiple-object specifier (one-to-many reationship)
// - insertion location


class SingleReference: SelfPackingReference, SelfPacking, Selectable, HandlerProtocol {

    // TO DO: implement toTYPE methods which perform standard `get` (i.e. coercing a native/remote Reference to anything except `reference`/`lazy` should de-reference it and coerce the result) [Q. what about `value`/`anything`, as `reference` is a subtype of those? inclined to treat references like thunks, in which case coercing to anything/value forces it]
    
    // property or single element; by-index, by-name, by-id, relative, first/middle/last
    
    // TO DO: in order to deal with ambiguous property/element names (e.g. `document` in TextEdit, which is both property and singular element name), this class needs to be selectable and callable, in which case it should check if property name is also a singular element name, and if so convert to all-elements specifier and perform selection on that, else throw 'not an element' error
    
    // AERoots are defined on AEItem.appData
    
    override var description: String { return "«\(self.swiftValue)»" } // TO DO: native formatting
    
    override var specifier: Specifier { return swiftValue }
    
    let swiftValue: AEItem // a SwiftAutomation ObjectSpecifier containing basic AppData and NSAppleEventDescriptor
    internal let attributeName: String
    
    init(_ specifier: AEItem, attributeName: String, appData: NativeAppData) { // TO DO: take [property] name as argument
        self.swiftValue = specifier
        self.attributeName = attributeName // this is only used when converting property reference to elements reference of same name; do not use for anything else
        super.init(appData: appData)
    }
    
    override func get(_ key: String) throws -> Value {
        switch key {
        case "every":
            return try self.toMultipleReference() // TO DO: return MultipleReference(self.swiftValue.all, appData: self.appData); need to implement ObjectSpecifierExtension.all first (this converts existing property specifier to all-elements specifier, allowing user to disambiguate conflicting terminology where a property name and elements name are identical, in which case the property definition would normally take priority [in AS, one exception is `text`, which defaults to all-elements definition by default])
        case "previous": // `ELEMENT_TYPE before ELEMENT_REFERENCE`
            fatalError()
        case "next": // `ELEMENT_TYPE after ELEMENT_REFERENCE`
            fatalError() // TO DO: return RelativeSelector(for: self, position: name) // HandlerProtocol that takes Symbol (typeClass) as sole argument
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
                return SingleReference(self.swiftValue.property(code), attributeName: key, appData: appData)
            } else if let code = self.appData.glueTable.elementsByName[key]?.code {
                return MultipleReference(self.swiftValue.elements(code), attributeName: key, appData: appData)
            } else {
                return try super.get(key)
            }
        }
    }
    
    // property names may be identical to [singular] element names, in which case we need to treat a property specifier as an all-elements specifier instead
    
    private func toMultipleReference() throws -> MultipleReference {
        if let code = self.appData.glueTable.elementsByName[self.attributeName]?.code {
            if let parent = self.swiftValue.parentQuery as? AEItem {
                return MultipleReference(parent.elements(code), attributeName: self.attributeName, appData: appData)
            } else if let parent = self.swiftValue.parentQuery as? AERoot {
                return MultipleReference(parent.elements(code), attributeName: self.attributeName, appData: appData)
            }
        }
        // TO DO: if self.attributeName is empty string?
        throw ValueNotFoundError(name: self.attributeName, env: self) // TO DO: what error? (should maybe have argument that takes description: "property/element/command" or "element")
    }
    
    func byIndex(_ selectorData: Value) throws -> Value {
        return try toMultipleReference().byIndex(selectorData)
    }
    
    func byName(_ selectorData: Value) throws -> Value {
        return try toMultipleReference().byIndex(selectorData)
    }
    
    func byID(_ selectorData: Value) throws -> Value {
        return try toMultipleReference().byIndex(selectorData)
    }
    
    func byTest(_ selectorData: Value) throws -> Value {
        return try toMultipleReference().byIndex(selectorData)
    }
    
    let interface = CallableInterface(name: "", parameters: [("selector_data", "", asValue)], returnType: asReference) // TO DO: what should name be?
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        return try toMultipleReference().call(command: command, commandEnv: commandEnv, handlerEnv: handlerEnv, coercion: coercion)
    }
}



class MultipleReference: SingleReference {
    
    // zero or more elements; by-range, by-test, all
    
    let _swiftValue: AEItems
    
    init(_ specifier: AEItems, attributeName: String, appData: NativeAppData) {
        self._swiftValue = specifier
        super.init(specifier, attributeName: attributeName, appData: appData)
    }
    
    override func get(_ key: String) throws -> Value {
        switch key {
        // TO DO: these are wrong: ordinal names are defined as prefix operators, so need to return a closure that takes element name as argument
        case "first": // `first ELEMENT_TYPE of ELEMENTS_REFERENCE`
            return SingleReference(self._swiftValue.first, attributeName: key, appData: self.appData)
        case "middle":
            return SingleReference(self._swiftValue.middle, attributeName: key, appData: self.appData)
        case "last":
            return SingleReference(self._swiftValue.last, attributeName: key, appData: self.appData)
        case "any":
            return SingleReference(self._swiftValue.any, attributeName: key, appData: self.appData)
        case "every":
            return self
        // these are okay though as 'beginning' and 'end' are defined as atom operators to be used in `of` clause
        // TO DO: also put these on SingleReference.get(), with toMultipleReference call
        case "beginning": // `beginning of ELEMENTS_REFERENCE`
            return InsertionReference(self._swiftValue.beginning, appData: self.appData)
        case "end": // `end of ELEMENTS`
            return InsertionReference(self._swiftValue.end, appData: self.appData)
        default:
            return try super.get(key)
        }
    }
    
    override func byIndex(_ selectorData: Value) throws -> Value {
        // TO DO: could do with explicit methods on SpecifierExtensions
        if let range = selectorData as? Range {
            return MultipleReference(self._swiftValue[range.start, range.stop], attributeName: self.attributeName, appData: self.appData)
        } else {
            return SingleReference(self._swiftValue[selectorData], attributeName: self.attributeName, appData: self.appData)
        }
    }
    
    override func byName(_ selectorData: Value) throws -> Value {
        return SingleReference(self._swiftValue.named(selectorData), attributeName: self.attributeName, appData: self.appData)
    }
    
    override func byID(_ selectorData: Value) throws -> Value {
        return SingleReference(self._swiftValue.ID(selectorData), attributeName: self.attributeName, appData: self.appData)
    }
    
    override func byTest(_ selectorData: Value) throws -> Value {
        fatalError()
        // let test = selectorData as? Reference // TO DO: should be TestReference; any way to verify that here? how do we get TestClause?
        // return MultipleReference(self.swiftValue[test], appData: self.appData)
    }
    
    override func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {
        var arguments = command.arguments
        let arg_0 = try asValue.unboxArgument("selector_data", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        if (try? asInt.unbox(value: arg_0, env: commandEnv)) != nil {
            return try self.byIndex(arg_0)
        } else if (try? asString.unbox(value: arg_0, env: commandEnv)) != nil {
            return try self.byName(arg_0)
        }
        return try self.byIndex(arg_0)
    }

}



class InsertionReference: SelfPackingReference, SelfPacking { // beginning/end/before/after
    
    override var specifier: Specifier { return swiftValue }
    
    let swiftValue: AEInsertion
    
    init(_ specifier: AEInsertion, appData: NativeAppData) {
        self.swiftValue = specifier
        super.init(appData: appData)
    }
    
}


/******************************************************************************/


class Application: SelfPackingReference, HandlerProtocol {

    // TO DO: want this to be exposed as value which is callable/selectable (need to start thinking in terms of namespaces, c.f. Frontier) // this'll need to be instantiated as current application, with callable interface
    
    override var description: String { return "«\(self.swiftValue)»" } // TO DO: native formatting
    
    override var specifier: Specifier { return swiftValue }
    
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
    
    override func get(_ key: String) throws -> Value {
        if let code = self.appData.glueTable.propertiesByName[key]?.code {
            return SingleReference(self.swiftValue.property(code), attributeName: key, appData: appData)
        } else if let code = self.appData.glueTable.elementsByName[key]?.code {
            return MultipleReference(self.swiftValue.elements(code), attributeName: key, appData: appData)
        } else {
            return try super.get(key)
        }
    }
    
    let interface = CallableInterface(name: "app", parameters: [("name", "", asString)], returnType: asReference)
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value {        
        var arguments = command.arguments
        let arg_0 = try asString.unboxArgument("name", in: &arguments, commandEnv: commandEnv, command: command, handler: self)
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        return try Application(name: arg_0)

    }

}


/******************************************************************************/


func aelib_loadConstants(env: Env) throws {
    try env.set("app", to: Application()) // instantiate a single Application value for adding to module; this value identifies current application as default, but can be targeted to anything else
}
