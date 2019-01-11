//
//  aelib.swift
//

import SwiftAutomation




class DynamicAppData: AppData { // TO DO: subclass AppData or not?
    
    
    
}


class Reference: AttributedValue { // TO DO: callable?
    
    // similar arrangement to py-appscript/py-aem, where Reference is high-level terminology-based wrapper around low-level four-char-code-based API
    
    private var appData: DynamicAppData? // TO DO: when unpacking ObjectSpecifier, use basic AppData;
    
    func set(_ name: String, to value: Value) throws { // TO DO: only implement if using unified 'set' command to cover all all assignment-type operations (currently env assignment uses `store` whereas AE bridge uses `set`)
        fatalError()
    }
    
    func get(_ name: String) throws -> (value: Value, scope: Scope) { // TO DO: still to sort out Scope vs Attributed
        fatalError()
    }
}


class SingleReference: Reference { // property or single element; by-index, by-name, by-id, relative, first/middle/last
    
    // AERoots are defined on AEItem.appData
    
    private var specifier: AEItem? // a SwiftAutomation ObjectSpecifier containing basic AppData and NSAppleEventDescriptor
    
}

class MultipleReference: SingleReference { // zero or more elements; by-range, by-test, all
    
    //private var specifier: AEItems?
    
}

class InsertionReference: Reference { // beginning/end/before/after
    
    private var specifier: AEInsertion?
    
}

// note: by-range/by-test handler will supply full terminology and the appropriate relative root, so no need for appscript-style 'generic references' or `app`/`con`/`its` globals


class Application: Value {
    
    private var specifier: AEApplication?
    
}



func applicationforBundleID(_ bundleID: String) {

    //GlueTable()
    
}


/*
public class _AEInsertion: InsertionSpecifier, AECommand {}


// property/by-index/by-name/by-id/previous/next/first/middle/last/any
public class AEItem: ObjectSpecifier, AEObject {
    public typealias InsertionSpecifierType = AEInsertion
    public typealias ObjectSpecifierType = AEItem
    public typealias MultipleObjectSpecifierType = AEItems
}

// by-range/by-test/all
public class _AEItems: AEItem, MultipleObjectSpecifierExtension {}

// App/Con/Its
public class AERoot: RootSpecifier, AEObject, RootSpecifierExtension {
    public typealias InsertionSpecifierType = AEInsertion
    public typealias ObjectSpecifierType = AEItem
    public typealias MultipleObjectSpecifierType = AEItems
    public override class var untargetedAppData: AppData { return _untargetedAppData }
}

// Application
public class _AEApplication: AERoot, Application {}

// App/Con/Its root objects used to construct untargeted specifiers; these can be used to construct specifiers for use in commands, though cannot send commands themselves

public let _AEApp = _untargetedAppData.app as! AERoot
public let _AECon = _untargetedAppData.con as! AERoot
public let _AEIts = _untargetedAppData.its as! AERoot
*/
