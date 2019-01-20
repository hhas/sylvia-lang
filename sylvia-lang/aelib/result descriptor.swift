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
    
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        switch self.desc.descriptorType {
        // common AE types
        case typeSInt32, typeSInt16, typeUInt16:  // typeSInt64, typeUInt64, typeUInt32
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
    
    override func toList(env: Scope, coercion: AsList) throws -> List {
        do {
            guard let listDesc = self.desc.coerce(toDescriptorType: typeAEList) else { throw CoercionError(value: self, coercion: coercion) }
            var result = [Value]()
            for i in 1...listDesc.numberOfItems {
                let desc = ResultDescriptor(listDesc.atIndex(i)!, appData: self.appData)
                do {
                    result.append(try desc.nativeEval(env: env, coercion: coercion.elementType))
                } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                    throw CoercionError(value: desc, coercion: coercion.elementType).from(error)
                }
            }
            return List(result)
        } catch {
            throw CoercionError(value: self, coercion: coercion).from(error)
        }
    }
    
    override func toArray<E, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        do {
            guard let listDesc = self.desc.coerce(toDescriptorType: typeAEList) else { throw CoercionError(value: self, coercion: coercion) }
            var result = [E.SwiftType]()
            for i in 1...listDesc.numberOfItems {
                let desc = ResultDescriptor(listDesc.atIndex(i)!, appData: self.appData)
                do {
                    result.append(try desc.bridgingEval(env: env, coercion: coercion.elementType))
                } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                    throw CoercionError(value: desc, coercion: coercion.elementType).from(error)
                }
            }
            return result
        } catch {
            throw CoercionError(value: self, coercion: coercion).from(error)
        }
    }
    
    override func toSymbol(env: Scope, coercion: Coercion) throws -> Symbol {
        let code: OSType
        switch self.desc.descriptorType {
        case typeType, typeProperty, typeKeyword:
            code = desc.typeCodeValue
        case typeEnumerated:
            code = desc.enumCodeValue
        default:
            throw CoercionError(value: self, coercion: coercion)
        }
        // TO DO: worth caching Symbols?
        if let name = self.appData.glueTable.typesByCode[code] {
            return Symbol(name) // e.g. `#document`
        } else {
            return Symbol("$\(UTCreateStringForOSType(code).takeRetainedValue() as String)") // e.g. `#‘$docu’`
        }
    }
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value { // quick-n-dirty implementation
        switch self.desc.descriptorType {
        case typeSInt32, typeSInt16, typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint,
             typeSInt64, typeUInt64, typeUInt32, typeUInt16,
             typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            return try self.toText(env: env, coercion: coercion)
        case typeAEList:
            return try self.toList(env: env, coercion: asList)
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            return try self.toSymbol(env: env, coercion: coercion)
        case typeObjectSpecifier:
            let specifier = try self.appData.unpack(desc) as AEItem
            if let multipleSpecifier = specifier as? AEItems {
                return MultipleReference(multipleSpecifier, attributeName: "", appData: self.appData) // TO DO: what should attributeName be? (since specifier is returned by app, we assume that property/element name ambiguity is not an issue; simplest is to use empty string and check for that before throwing an error in SingleReference.toMultipleReference())
            } else {
                return SingleReference(specifier, attributeName: "", appData: self.appData) // TO DO: ditto
            }
        case typeQDPoint, typeQDRectangle, typeRGBColor:
            return List((try self.appData.unpack(desc) as [Int]).map{Text($0)})
        default:
            return self
        }
    }
}


