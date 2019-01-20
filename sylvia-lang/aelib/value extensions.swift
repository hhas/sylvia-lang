//
//  values.swift
//

import SwiftAutomation


// native Value subclasses that wrap an already-bridged Swift type as `swiftType` ivar

protocol SelfPackingValueWrapper: SelfPacking, PrimitiveWrapper { }

extension SelfPackingValueWrapper {
    
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        return try appData.pack(self.swiftValue)
    }
}


// extend standard Value subclasses to pack themselves where practical


extension Text: SelfPackingValueWrapper { } // TO DO: Text needs smarter behavior to distinguish 'actual' numbers from strings (incl. numeric strings); safest to check for *existing* scalar representation


extension List: SelfPackingValueWrapper { }


private let missingValueDescriptor = NSAppleEventDescriptor(typeCode: 0x6D736E67) // 'msng'

extension Nothing: SelfPacking {
    func SwiftAutomation_packSelf(_ appData: AppData) throws -> NSAppleEventDescriptor {
        return missingValueDescriptor
    }
}
