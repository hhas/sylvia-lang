//
//  remote call.swift
//

import Foundation
import SwiftAutomation


/******************************************************************************/
// application command


class RemoteCall: CallableValue {
    
    override var description: String { return "«\(self.definition) of \(self.parent)»" } // TO DO: native formatting
    
    lazy var interface = { return appData.interfaceForCommand(term: self.definition) }()
    
    let parent: Reference
    let definition: CommandTerm
    let appData: NativeAppData
    
    private let orderedParameterDefinitions: [(String, OSType)]
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // TO DO: how to support returnType coercions? (they should drive unpacking, which means reply AE needs to present as Value wrapper with toTYPE methods that drive the actual AE unpacking, e.g. by coercing the wrapped descriptor to the appropriate AE type; presumably AEList [and AERecord?] descs will need to be custom-unpacked)
        var parameters = [OSType: Value]()
        var arguments = command.arguments
        for (paramKey, code) in self.orderedParameterDefinitions {
            if let value = try removeArgument(paramKey, from: &arguments)?.nativeEval(env: commandEnv, coercion: asAnything) {
                parameters[code] = value
            }
        }
        if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: self) }
        
        // TO DO: need to catch and rethrow (Q. how to present primitive errors as native?)
        let desc = try self.appData.sendAppleEvent(eventClass: self.definition.eventClass,
                                                   eventID: self.definition.eventID,
                                                   parentSpecifier: self.parent.specifier,
                                                   parameters: parameters,
                                                   requestedType: nil,
                                                   waitReply: true,
                                                   sendOptions: nil,
                                                   withTimeout: nil,
                                                   considering: nil) as NSAppleEventDescriptor
        print("RESULT DESC: \(desc)")
        let result = try ResultDescriptor(desc, appData: self.appData).nativeEval(env: commandEnv, coercion: coercion)
        return result
    }
    
    init(_ parent: Reference, definition: CommandTerm, appData: NativeAppData) {
        self.parent = parent
        self.definition = definition
        self.appData = appData
        self.orderedParameterDefinitions = [("direct_parameter", 0x2D2D2D2D)] + definition.orderedParameters.map{ ($0.name, $0.code) }
    }
}

