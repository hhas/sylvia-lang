//
//  stdlib/handlers/specifier.swift
//


/******************************************************************************/
// reference

func ofClause(attribute: Value, value: AttributedValue, commandEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    // look up attribute (identifier/command) on value; all other evaluation (command arguments) is done in commandEnv as normal
    let scope = value as? Scope ?? ScopeShim(value) // kludge
    switch attribute {
    case let command as Command:
        return try scope.handle(command: command, commandEnv: commandEnv, coercion: asAnything)
    case let identifier as Identifier:
        return try identifier.nativeEval(env: scope, coercion: asAnything)
    default:
        throw CoercionError(value: attribute, coercion: asAttribute)
    }
}


/******************************************************************************/
// selectors

// TO DO: these are really Reference methods, but are implemented here to catch any calls from operators, e.g. `item at 1` may be written in any Scope, though how it should be handled is another question (FWIW, `get name of every handler [of SCOPE]` would be legit introspection code)

private func elements(ofType elementType: String, from parentObject: Scope) throws -> Selectable {
    guard let elements = try parentObject.get(elementType) as? Selectable else { // e.g. `items [of LIST]`
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

func idSelector(elementType: String, selectorData: Value, commandEnv parentObject: Scope) throws -> Value {
    return try elements(ofType: elementType, from: parentObject).byID(selectorData)
}

func testSelector(elementType: String, selectorData: Reference, commandEnv parentObject: Scope) throws -> Value {
    return try elements(ofType: elementType, from: parentObject).byTest(selectorData)
}


