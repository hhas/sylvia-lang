//
//  remote call.swift
//

import Foundation
import SwiftAutomation


/******************************************************************************/
// application command


class RemoteCall: Handler {
    
    override var description: String { return "«\(self.definition) of \(self.parent)»" } // TO DO: native formatting
    
    lazy var interface = { return appData.interfaceForCommand(term: self.definition) }()
    
    let parent: Reference
    let definition: CommandTerm
    let appData: NativeAppData
    
    private let orderedParameterDefinitions: [(String, OSType)]
    
    func call(command: Command, commandEnv: Scope, handlerEnv: Scope, coercion: Coercion) throws -> Value { // TO DO: how to support returnType coercions? (they should drive unpacking, which means reply AE needs to present as Value wrapper with toTYPE methods that drive the actual AE unpacking, e.g. by coercing the wrapped descriptor to the appropriate AE type; presumably AEList [and AERecord?] descs will need to be custom-unpacked)
        var parameters = [OSType: Value]()
        var arguments = command.arguments
        // TO DO: confirm that method arguments will always be evaluated in extended target scope, and generalize to all methods (on one hand, this is necessary to support unparenthesized commands, e.g. `get text of document 1` -> `of(get(text),document(1))`; on the other, this could have all sorts of hilariously unintended consequences where user isn't expecting it [as, unlike explicit `tell` block where its ability to mask existing names in command scope is obvious, the extra scope is implicitly injected when evaluating argument expression but can still mask names in command scope])
        let scope = TargetScope(self.parent, parent: commandEnv)
        for (paramKey, code) in self.orderedParameterDefinitions {
            if let value = try removeArgument(paramKey, from: &arguments)?.nativeEval(env: scope, coercion: asAnything) {
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
                                                   considering: nil) as NSAppleEventDescriptor?
        if let result = desc {
            do {
                return try ResultDescriptor(result, appData: self.appData).nativeEval(env: commandEnv, coercion: coercion)
            } catch { // presumably a CoercionError; anything else?
                print("Failed to unpack RESULT DESC as \(coercion): \(result)") // DEBUG
                throw error // TO DO: throw a CommandError? or just let CoercionError propagate? (technically the remote command succeeded; however, we're still within handler and it may help user to see the complete command; would probably also help to see the ResultDescriptor unpacked asAnything, in which case maybe chain/duplicate the CoercionError)
            }
        } else {
            return noValue
        }
    }
    
    init(_ parent: Reference, definition: CommandTerm, appData: NativeAppData) {
        self.parent = parent
        self.definition = definition
        self.appData = appData
        self.orderedParameterDefinitions = [("direct_parameter", 0x2D2D2D2D)] + definition.orderedParameters.map{ ($0.name, $0.code) }
    }
}

