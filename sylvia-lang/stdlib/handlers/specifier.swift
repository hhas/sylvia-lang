//
//  stdlib/handlers/specifier.swift
//


/******************************************************************************/
// reference

func ofClause(attribute: Value, value: Value, commandEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    // look up attribute (identifier/command) on value; all other evaluation (command arguments) is done in commandEnv as normal
    guard let scope = value as? Scope else { throw UnrecognizedAttributeError(name: attribute.description, value: value) }
    switch attribute {
    case let command as Command:
        // TO DO: copypasted from Command.eval; might be better to put implementation on Command/Scope
        let (value, handlerEnv) = try scope.get(command.normalizedName)
        guard let handler = value as? Callable else { throw HandlerNotFoundError(name: command.name, env: scope) }
        return try handler.call(command: command, commandEnv: commandEnv, handlerEnv: handlerEnv, coercion: asAnything)
    case let identifier as Identifier:
        return try identifier.nativeEval(env: scope, coercion: asAnything)
    default:
        throw CoercionError(value: attribute, coercion: asAttribute)
    }
}


/******************************************************************************/
// selectors

// TO DO: can this be folded into selector.swift?

func atClause(elementType name: String, selectorData index: Value, commandEnv parentObject: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    guard let elements = try parentObject.get(name).value as? Selectable else { // e.g. `items [of LIST]`
        throw ValueNotFoundError(name: name, env: parentObject)
    }
    return try elements.byIndex(index)
}



