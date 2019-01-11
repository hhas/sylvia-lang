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
        let (value, handlerEnv) = try scope.get(command.key)
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

private func elements(ofType elementType: String, from parentObject: Scope) throws -> Selectable {
    guard let elements = try parentObject.get(elementType).value as? Selectable else { // e.g. `items [of LIST]`
        throw ValueNotFoundError(name: elementType, env: parentObject) // TO DO: distinguish between 'not found' and 'not elements'
    }
    return elements
}

func indexSelector(elementType: String, selectorData: Value, commandEnv parentObject: Scope) throws -> Value { // also implements by-range
    return try elements(ofType: elementType, from: parentObject).byIndex(selectorData)
}

func nameSelector(elementType: String, selectorData: Value, commandEnv parentObject: Scope) throws -> Value {
    return try elements(ofType: elementType, from: parentObject).byName(selectorData)
}

func uidSelector(elementType: String, selectorData: Value, commandEnv parentObject: Scope) throws -> Value {
    return try elements(ofType: elementType, from: parentObject).byID(selectorData)
}

func testSelector(elementType: String, selectorData: Value, commandEnv parentObject: Scope) throws -> Value {
    return try elements(ofType: elementType, from: parentObject).byTest(selectorData)
}


