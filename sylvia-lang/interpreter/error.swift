//
//  error.swift
//


// TO DO: should LanguageError subclass Value? (yes, as we have enough primitive boxing already, though need to decide how native error API will work)

// TO DO: how to separate user-visible error information from developer-only error information? e.g. stack traces showing command arguments might leak potentially sensitive information (TBH, this probably only becomes a concern when scripts are saved in compiled form)

// TO DO: eventually stack traces should be filterable only to show highlights (typically the initial error, the handler where it occurred, and the topmost command that failed as a result (intermediate trace is of less immediate use and tends to obfuscate the key points, so should be initially hidden by default); in the case of coercion errors, the origins of the Coercion instances may also be described (e.g. as Values typically declared as literals, they should be annotated with their source location); consider using annotations to indicate which error message is which, and provide APIs for working with chained errors

// TO DO: eventually move error raising APIs onto Env, allowing behavior to be customized (e.g. when running in debugger mode, instead of unwinding the stack, a coercion error might suspend execution and activate UI interaction mode where user can inspect, and potentially modify, the problem values, then resume execution from that same point)


class LanguageError: Error, CustomStringConvertible {
    
    private(set) var parentError: Error?
    
    let _message: String
    
    init(_ message: String = "") { // error description provided by calling code, if any
        self._message = message
    }
    
    var message: String { return self._message } // subclasses may override to construct custom error description
    
    func from(_ parentError: Error) -> Error {
        self.parentError = parentError
        return self
    }
    
    var description: String {
        var result = "\(type(of: self)): \(self.message)"
        if let parentError = self.parentError { result = "\(parentError)\n↳ \(result)" }
        return result
    }
    
    //var localizedDescription: String { return self.description } // needed?
}

/******************************************************************************/
// implementation bugs

class InternalError: LanguageError {}

/******************************************************************************/
// parse error

class SyntaxError: LanguageError {
    
    override init(_ message: String) { // TO DO: need to include parser for error reporting use; TO DO: more granular API that takes expected token description, found token, and position (what about previous token?)
        super.init(message)
    }
}

/******************************************************************************/
// coercion errors


class CoercionError: LanguageError {
    
    let value: Value
    let coercion: Coercion
    
    init(value: Value, coercion: Coercion) {
        self.value = value
        self.coercion = coercion
        super.init()
    }
    
    override var message: String {
        return "Can’t coerce this \(self.value.nominalType) to \(self.coercion): \(self.value)"
    }
}


// TO DO: when to promote NullCoercionError to permanent error?

class NullCoercionError: CoercionError {
    
    override var message: String {
        return "Can’t coerce ‘\(self.value)’ to \(self.coercion)."
    }
    
} // coercing Nothing always throws NullCoercionError; this may be caught by AsDefault to supply a default value instead (optional parameter)



/******************************************************************************/


struct ConstraintError: Error, CustomStringConvertible {
    
    let value: Any // TO DO: what should this be? (e.g. enum of Value, Scalar, Primitive?)
    let constraint: Coercion?
    let message: String? // TO DO: rename message
    // TO DO: should this also capture env:Scope?
    
    init(value: Any, constraint: Coercion? = nil, message: String? = nil) {
        self.value = value
        self.constraint = constraint
        self.message = message
    }
    
    var description: String {
        return self.message ?? "Not a valid \(self.constraint == nil ? "value" : String(describing: self.constraint!)): \(self.value)"
    }
}


struct EvaluationError: Error, CustomStringConvertible {
    let description: String // TO DO: separate message and `var description: String { return "\(type(of:self)): \(self.message)" }`
}





class UnrecognizedAttributeError: LanguageError {
    let name: String
    let value: Value
    
    init(name: String, value: Value) {
        self.name = name
        self.value = value
    }
    
    override var message: String {
        return "Can’t find an attribute named “\(self.name)” on the following \(self.value.nominalType): \(self.value)"
    }
}



/******************************************************************************/
// environment lookup errors

class EnvironmentError: LanguageError { // abstract base class
    
    let name: String
    let env: Scope
    
    init(name: String, env: Scope) {
        self.name = name
        self.env = env
        super.init()
    }
}


class ValueNotFoundError: EnvironmentError {

    override var message: String {
        return "Can’t find a value named “\(self.name)”."
    }
}

class ReadOnlyValueError: EnvironmentError {
    
    override var message: String {
        return "Can’t replace the non-editable value named “\(self.name)”."
    }
}

class HandlerNotFoundError: EnvironmentError {
    
    override var message: String {
        return "Can’t find a handler named “\(self.name)”."
    }
}


/******************************************************************************/
// command evaluation errors

class HandlerFailedError: LanguageError {
    
    let handler: Callable
    let command: Command
    
    init(handler: Callable, command: Command) {
        self.handler = handler
        self.command = command
        super.init()
    }
    override var message: String {
        return "‘\(self.handler.name)’ handler failed on command: \(self.command)"
    }
}


class BadArgumentError: LanguageError {
    
    let command: Command
    let handler: CallableValue
    let index: Int // bad command argument's index
    
    init(command: Command, handler: CallableValue, index: Int) {
        self.command = command
        self.handler = handler
        self.index = index
        super.init()
    }
    
    override var message: String {
        let parameter = self.handler.interface.parameters[self.index]
        let argument = self.index < self.command.arguments.count ? self.command.arguments[self.index] : noValue
        return "‘\(self.handler.interface.name)’ handler’s ‘\(parameter.name)’ parameter requires \(type(of:parameter.coercion)) but received \(type(of:argument)): \(argument)" // TO DO: better coercion descriptions needed
    }
}

class UnrecognizedArgumentError: LanguageError {
    
    let command: Command
    let handler: CallableValue
    
    init(command: Command, handler: CallableValue) {
        self.command = command
        self.handler = handler
        super.init()
    }
    
    override var message: String {
        let parameters = self.handler.interface.parameters
        let arguments = self.command.arguments
        return "‘\(self.handler.interface.name)’ handler expected \(parameters.count) parameters but received \(arguments.count): \(arguments)"
    }
}
