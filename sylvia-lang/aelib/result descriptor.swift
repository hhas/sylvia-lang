//
//  descriptor value.swift
//
//  wraps NSAppleEventDescriptor returned by AppData.sendAppleEvent(…) as Value, allowing unpacking to be driven by Coercion
//

import Foundation
import SwiftAutomation


typealias OpaqueValue = Value // TO DO


class ResultDescriptor: OpaqueValue {
    
    override var description: String { return "«\(self.desc)»" }
    
    override class var nominalType: Coercion { return asAnything } // TO DO: need Precis, and probably AsOpaque
    
    private let desc: NSAppleEventDescriptor
    private let appData: NativeAppData
    
    init(_ desc: NSAppleEventDescriptor, appData: NativeAppData) {
        self.desc = desc
        self.appData = appData
    }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value {
        return try self.toText(env: env, coercion: coercion) // temporary; need to figure how best to dispatch on descriptorType
    }
    
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        switch self.desc.descriptorType {
        // common AE types
        case typeSInt32, typeSInt16:
            return Text(Int(self.desc.int32Value))
        // TO DO: other integer types
        case typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint:
            return Text(self.desc.doubleValue)
        case type128BitFloatingPoint: // coerce down lossy
            guard let doubleDesc = self.desc.coerce(toDescriptorType: typeIEEE64BitFloatingPoint) else {
                throw CoercionError(value: self, coercion: coercion) // message: "Can't coerce 128-bit float to double."
            }
            return Text(doubleDesc.doubleValue)
        case typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            guard let result = self.desc.stringValue else {
                throw GeneralError("Corrupt descriptor: \(self.desc)")
            }
            return Text(result)
        default:
            guard let result = self.desc.stringValue else {
                throw CoercionError(value: self, coercion: coercion)
            }
            return Text(result)
        }
    }
    
    /*
    override func toList(env: Scope, coercion: AsList) throws -> List {
        do {
            return try List([self.nativeEval(env: env, coercion: coercion.elementType)])
        } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
            throw CoercionError(value: self, coercion: coercion.elementType).from(error)
        }
    }
    
    override func toArray<E, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        do {
            return try [self.bridgingEval(env: env, coercion: coercion.elementType)] //[coercion.elementType.unbox(value: self, env: env)]
        } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
            throw CoercionError(value: self, coercion: coercion.elementType).from(error) // TO DO: ditto
        }
    }
    */
}


