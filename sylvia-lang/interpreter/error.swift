//
//  error.swift
//


// TO DO: error base class with chaining capability (Q. what's easiest? passing parent error to initializer, or calling `throw ERROR(…).from(error)`? [might even consider operator override])

/******************************************************************************/
// implementation bugs

class InternalError: Error, CustomStringConvertible {
    
    let description: String
    
    init(_ message: String) {
        self.description = "An internal error occurred: \(message)"
    }
}

/******************************************************************************/
// parse error

class SyntaxError: Error, CustomStringConvertible {
    
    let description: String
    
    init(_ message: String) {
        self.description = "Invalid syntax: \(message)"
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

class EnvironmentError: Error, CustomStringConvertible { // abstract base class
    
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


class ValueNotFoundError: EnvironmentError {

    override var description: String {
        return "Can’t find a value named “\(self.name)”."
    }
}

class ReadOnlyValueError: EnvironmentError {
    
    override var description: String {
        return "Can’t replace the non-editable value named “\(self.name)”."
    }
}

class HandlerNotFoundError: EnvironmentError {
    
    override var description: String {
        return "Can’t find a handler named “\(self.name)”."
    }
}


/******************************************************************************/
// command evaluation errors

class HandlerFailedError: Error, CustomStringConvertible {
    
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
        return "Handler ‘\(self.handler.name)’ failed: \(self.error)"
    }
}


class BadArgumentError: Error, CustomStringConvertible {
    
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
        let parameter = self.handler.interface.parameters[self.index]
        let argument = self.command.arguments.count < self.index ? self.command.arguments[self.index] : noValue
        return "‘\(self.handler.interface.name)’ handler’s ‘\(parameter.name)” parameter requires \(type(of:parameter.type)) but received \(type(of:argument)): \(argument)" // TO DO: better type descriptions needed
    }
}
