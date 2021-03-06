//
//  descriptor value.swift
//
//  wraps Descriptor returned by AppData.sendAppleEvent(…) as Value, allowing unpacking to be driven by Coercion
//

import Foundation
import AppleEvents
import SwiftAutomation



typealias OpaqueValue = Value // TO DO


class ResultDescriptor: OpaqueValue {
    
    override var description: String { return "«\(self.desc)»" }
    
    override class var nominalType: Coercion { return asAnything } // TO DO: need Precis, and probably AsOpaque
    
    private let desc: Descriptor
    private let appData: NativeAppData
    
    init(_ desc: Descriptor, appData: NativeAppData) {
        self.desc = desc
        self.appData = appData
    }
    
    // unpack atomic types
    
    override func toBoolean(env: Scope, coercion: Coercion) throws -> Boolean {
        // TO DO: rework this (should it follow AE coercion rules or native? e.g. 0 = true or false?)
        guard let result = try? unpackAsBool(self.desc) else { throw CoercionError(value: self, coercion: asBool) }
        return result ? trueValue : falseValue
    }
        
    override func toText(env: Scope, coercion: Coercion) throws -> Text {
        switch self.desc.type {
        // common AE types
        case typeSInt32, typeSInt16, typeUInt16, typeSInt64, typeUInt64, typeUInt32:
            return Text(try! unpackAsInt(self.desc))
        // TO DO: other integer types
        case typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint: // 128-bit will be coerced down (lossy)
            guard let result = try? unpackAsDouble(self.desc) else {
                throw CoercionError(value: self, coercion: coercion) // message: "Can't coerce 128-bit float to double."
            }
            return Text(result)
        case typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            guard let result = try? unpackAsString(self.desc) else {
                throw GeneralError("Corrupt descriptor: \(self.desc)")
            }
            return Text(result)
        default:
            guard let result = try? unpackAsString(self.desc) else {
                throw CoercionError(value: self, coercion: coercion)
            }
            return Text(result)
        }
    }
    
    override func toTag(env: Scope, coercion: Coercion) throws -> Tag {
        let code: OSType
        switch self.desc.type {
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            code = try! unpackAsFourCharCode(desc)
        default:
            throw CoercionError(value: self, coercion: coercion)
        }
        // TO DO: worth caching Tags?
        if let name = self.appData.glueTable.typesByCode[code] {
            return Tag(name) // e.g. `#document`
        } else {
            return Tag(code) // e.g. `#‘«docu»’`
        }
    }
    
    // unpack collections
    
    override func toList(env: Scope, coercion: AsList) throws -> List {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [Value]()
                for itemDesc in desc {
                    let item = ResultDescriptor(itemDesc, appData: self.appData)
                    do {
                        result.append(try item.nativeEval(env: env, coercion: coercion.elementType))
                    } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                        throw CoercionError(value: item, coercion: coercion.elementType).from(error)
                    }
                }
                return List(result)
            } else {
                return List([try self.nativeEval(env: env, coercion: coercion.elementType)])
            }
        } catch {
            throw CoercionError(value: self, coercion: coercion).from(error)
        }
    }
    
    override func toArray<E: BridgingCoercion, T: AsArray<E>>(env: Scope, coercion: T) throws -> T.SwiftType {
        do {
            if let desc = self.desc as? ListDescriptor {
                var result = [E.SwiftType]()
                for itemDesc in desc {
                    let item = ResultDescriptor(itemDesc, appData: self.appData)
                    do {
                        result.append(try item.bridgingEval(env: env, coercion: coercion.elementType))
                    } catch { // NullCoercionErrors thrown by list items must be rethrown as permanent errors
                        throw CoercionError(value: item, coercion: coercion.elementType).from(error)
                    }
                }
                return result
            } else {
                return [try self.bridgingEval(env: env, coercion: coercion.elementType)]
            }
        } catch {
            throw CoercionError(value: self, coercion: coercion).from(error)
        }
    }
    
    private let classKey = Tag("class").recordKey
    
    override func toRecord(env: Scope, coercion: AsRecord) throws -> Record {
        throw NotYetImplementedError()
        /*
        if !self.desc.isRecord { throw CoercionError(value: self, coercion: coercion) }
        var fields = Record.Storage()
        if self.desc.type != typeAERecord {
            fields[classKey] = try self.appData.unpack(Descriptor(typeCode: self.desc.type))
        }
        for i in 1...(try! self.desc.count()) {
            let key: Tag
            let (keyCode, valueDesc) = try self.desc.item(i) // ResultDescriptor will take ownership; TO DO: what about applying [simple] value type coercions here?
            // TO DO: better to hide this table behind API that returns Tag instances, as that allows caching (alternative is to create all Tag instances up-front, but that's probably overkill as most won't be used in any given script)
            if keyCode == 0x6C697374 { // keyASUserRecordFields
                fatalError("TODO") // TO DO: unpack user fields (an AEList of form `[string,any,string,any,…]`, where each string is a field name)
            } else {
                if let tagName = self.appData.glueTable.typesByCode[keyCode] {
                    key = Tag(tagName)
                } else { // TO DO: how to represent four-char-codes as tags? easiest to use `0x_HEXACODE`, though that's not the most readable; probably sufficient to use leading underscore or other character that isn't encountered in terminology keywords [caveat it has to be legal in at least a single-quoted identifier]
                    key = Tag(keyCode)
                }
                fields[key.recordKey] = try ResultDescriptor(valueDesc, appData: self.appData).nativeEval(env: env, coercion: coercion.valueType)
            }
        }
        return Record(fields)
     */
    }
    
    // unpack as anything
    
    override func toAny(env: Scope, coercion: Coercion) throws -> Value { // quick-n-dirty implementation
        switch self.desc.type {
        case typeBoolean, typeTrue, typeFalse:
            return try self.toBoolean(env: env, coercion: coercion)
        case typeSInt32, typeSInt16, typeIEEE64BitFloatingPoint, typeIEEE32BitFloatingPoint, type128BitFloatingPoint,
             typeSInt64, typeUInt64, typeUInt32, typeUInt16,
             typeChar, typeIntlText, typeUTF8Text, typeUTF16ExternalRepresentation, typeStyledText, typeUnicodeText, typeVersion:
            return try self.toText(env: env, coercion: coercion)
        case typeAEList:
            return try self.toList(env: env, coercion: asList)
        case typeAERecord:
            return try self.toRecord(env: env, coercion: asRecord)
        case typeType where (try? unpackAsType(self.desc)) == 0x6D736E67: // cMissingValue
            return noValue
        case typeType, typeProperty, typeKeyword, typeEnumerated:
            return try self.toTag(env: env, coercion: coercion)
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
            //if self.desc.isRecord { return try self.toRecord(env: env, coercion: asRecord) }
            return self
        }
    }
}


