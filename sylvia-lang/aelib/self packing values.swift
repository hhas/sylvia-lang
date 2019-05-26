//
//  values.swift
//

import Foundation
import AppleEvents
import SwiftAutomation


// native Value subclasses that wrap an already-bridged Swift type as `swiftType` ivar

protocol SelfPackingValueWrapper: SelfPacking, SwiftWrapper { }

extension SelfPackingValueWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return try appData.pack(self.swiftValue)
    }
}


// extend standard Value subclasses to pack themselves where practical


extension Boolean: SelfPackingValueWrapper { }


extension Text: SelfPackingValueWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        // does it look like a number?
        if let number = self.scalar {
            switch number {
            case .integer(let n, radix: _): return try appData.pack(n)
            case .floatingPoint(let n): return try appData.pack(n)
            default: ()
            }
        }
        return try appData.pack(self.swiftValue)
    }
}


extension List: SelfPackingValueWrapper { }


extension Record: SelfPackingValueWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        throw NotYetImplementedError()
        /*
        let resultDesc = Descriptor.record()
        var userFieldsDesc: Descriptor? = nil
        for (key, value) in self.swiftValue {
            let valueDesc = try appData.pack(value)
            
            switch key.value {
            case let text as Text:
                if userFieldsDesc == nil { userFieldsDesc = Descriptor.list() }
                let keyDesc = Descriptor(string: text.swiftValue)
                try userFieldsDesc!.appendItem(keyDesc)
                try userFieldsDesc!.appendItem(valueDesc)
            case let tag as Tag:
                let keyDesc = try tag.SwiftAutomation_packSelf(appData)
                try resultDesc.setParameter(keyDesc.typeCode(), to: valueDesc)
            default:
                throw CoercionError(value: key.value, coercion: asRecordKey)
            }
        }
        return try appData.pack(self.swiftValue)
     */
    }
    
}




private let missingValueDescriptor = packAsType(0x6D736E67) // 'msng'

extension Nothing: SelfPacking {
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        return missingValueDescriptor
    }
}




extension Tag: SelfPackingValueWrapper {
    
    convenience init(_ code: OSType) {
        self.init(String(format: "«0x%08x»", code)) // TO DO: distinguish typeType/typeEnumerated?
    }
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> Descriptor {
        // can't self-pack without upcasting AppData to NativeAppData, throwing if that fails, which is not ideal -- Q. is this going to be an issue for packing Specifiers? (e.g. `#document after document 1`, `ELEMENTS where PROPERTY eq TAG`)
        if self.swiftValue.hasPrefix("«") && self.swiftValue.hasSuffix("»") {
            throw NotYetImplementedError()
            //return Descriptor(typeCode: UTGetOSTypeFromString(code as CFString)) // TO DO: distinguish typeType/typeEnumerated?
        }
        if let desc = (appData as? NativeAppData)?.glueTable.typesByName[self.key] { return desc }
        throw GeneralError("Can't pack \(self)")
    }
}
