//
//  values.swift
//

import SwiftAutomation


// native Value subclasses that wrap an already-bridged Swift type as `swiftType` ivar

protocol SelfPackingValueWrapper: SelfPacking, SwiftWrapper { }

extension SelfPackingValueWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        return try appData.pack(self.swiftValue)
    }
}


// extend standard Value subclasses to pack themselves where practical


extension Boolean: SelfPackingValueWrapper { }


extension Text: SelfPackingValueWrapper { } // TO DO: Text needs smarter behavior to distinguish 'actual' numbers from strings (incl. numeric strings); safest to check for *existing* scalar representation


extension List: SelfPackingValueWrapper { }


extension Record: SelfPackingValueWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        let resultDesc = NSAppleEventDescriptor.record()
        var userFieldsDesc: NSAppleEventDescriptor? = nil
        for (key, value) in self.swiftValue {
            let valueDesc = try appData.pack(value)
            switch key.value {
            case let text as Text:
                if userFieldsDesc == nil { userFieldsDesc = NSAppleEventDescriptor.list() }
                userFieldsDesc!.insert(NSAppleEventDescriptor(string: text.swiftValue), at: 0)
                userFieldsDesc!.insert(valueDesc, at: 0)
            case let tag as Tag:
                let keyDesc = try tag.SwiftAutomation_packSelf(appData)
                resultDesc.setParam(valueDesc, forKeyword: keyDesc.typeCodeValue)
            default:
                throw CoercionError(value: key.value, coercion: asRecordKey)
            }
        }
        return try appData.pack(self.swiftValue)
    }
    
}




private let missingValueDescriptor = NSAppleEventDescriptor(typeCode: 0x6D736E67) // 'msng'

extension Nothing: SelfPacking {
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        return missingValueDescriptor
    }
}




extension Tag: SelfPackingValueWrapper {
    
    // TO DO: use hex if code will contain non visible-ASCII chars (TBH, might be simpler just to use hex codes anyway; FCCs are nasty and archaic, and best treated as such)
    
    convenience init(_ code: OSType) {
        self.init("«\(UTCreateStringForOSType(code).takeRetainedValue() as String)»") // TO DO: distinguish typeType/typeEnumerated?
    }
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        // can't self-pack without upcasting AppData to NativeAppData, throwing if that fails, which is not ideal -- Q. is this going to be an issue for packing Specifiers? (e.g. `#document after document 1`, `ELEMENTS where PROPERTY eq TAG`)
        if self.key.hasPrefix("«") && self.key.hasSuffix("»") {
            return NSAppleEventDescriptor(typeCode: UTGetOSTypeFromString(code as CFString)) // TO DO: distinguish typeType/typeEnumerated?
        }
        if let desc = (appData as? NativeAppData)?.glueTable.typesByName[self.key] { return desc }
        throw GeneralError("Can't pack \(self)")
    }
}
