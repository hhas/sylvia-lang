//
//  error.swift
//


/******************************************************************************/
// implementation bugs

class InternalError: Error, CustomStringConvertible {
    
    let description: String
    
    init(_ message: String) {
        self.description = "An internal error occurred: \(message)"
    }
}

/******************************************************************************/
// coercion errors


class CoercionError: Error, CustomStringConvertible {
    
    let value: Value
    let type: Coercion
    
    init(value: Value, type: Coercion) {
        self.value = value
        self.type = type
    }
    
    var localizedDescription: String { // TO DO: this is NSError throwback; is it needed?
        return self.description
    }
    
    var description: String {
        return "Can’t coerce value to \(self.type): \(self.value)"
    }
}


// TO DO: when to promote NullCoercionError to permanent error?

class NullCoercionError: CoercionError {} // coercing Nothing always throws NullCoercionError; this may be caught by AsDefault


/******************************************************************************/
// environment lookup errors

class EnvironmentException: Error, CustomStringConvertible { // abstract base class
    
    let name: String
    let env: Env
    
    init(name: String, env: Env) {
        self.name = name
        self.env = env
    }
    
    var description: String {
        fatalError("Subclasses must override `var description`.")
    }
    var localizedDescription: String {
        return self.description
    }
}


class ValueNotFoundException: EnvironmentException {

    override var description: String {
        return "Can’t find value named “\(self.name)”."
    }
}

class ReadOnlyValueException: EnvironmentException {
    
    override var description: String {
        return "Can’t replace read-only value named “\(self.name)”."
    }
}

class HandlerNotFoundException: EnvironmentException {
    
    override var description: String {
        return "Can’t find handler named “\(self.name)”."
    }
}


/******************************************************************************/
// command evaluation errors

class HandlerFailedException: Error, CustomStringConvertible {
    
    let handler: Callable
    let error: Error
    
    init(handler: Callable, error: Error) {
        self.handler = handler
        self.error = error
    }
    
    var localizedDescription: String {
        return self.description
    }
    
    var description: String {
        return "Handler \(self.handler.name) failed: \(self.error)"
    }
}


class BadArgumentException: Error, CustomStringConvertible {
    
    let command: Command
    let handler: CallableValue
    let index: Int
    
    init(command: Command, handler: CallableValue, index: Int) {
        self.command = command
        self.handler = handler
        self.index = index
    }
    
    var localizedDescription: String {
        return self.description
    }
    
    var description: String {
        return "\(self.handler.interface.name) requires \(self.handler.interface.parameters[self.index].name) parameter of "
            + "type \(self.handler.interface.parameters[self.index].type) but received: \(self.command.arguments[self.index])"
    }
}
