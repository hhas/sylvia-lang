//
//  error.swift
//



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



// evaluation error

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
