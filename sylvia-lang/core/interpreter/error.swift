//
//  error.swift
//


// TO DO: should GeneralError subclass Value? (yes, as we have enough primitive boxing already, though need to decide how native error API will work)

// TO DO: how to separate user-visible error information from developer-only error information? e.g. stack traces showing command arguments might leak potentially sensitive information (TBH, this probably only becomes a concern when scripts are saved in compiled form)

// TO DO: eventually stack traces should be filterable only to show highlights (typically the initial error, the handler where it occurred, and the topmost command that failed as a result (intermediate trace is of less immediate use and tends to obfuscate the key points, so should be initially hidden by default); in the case of coercion errors, the origins of the Coercion instances may also be described (e.g. as Values typically declared as literals, they should be annotated with their source location); consider using annotations to indicate which error message is which, and provide APIs for working with chained errors

// TO DO: eventually move error raising APIs onto Environment, allowing behavior to be customized (e.g. when running in debugger mode, instead of unwinding the stack, a coercion error might suspend execution and activate UI interaction mode where user can inspect, and potentially modify, the problem values, then resume execution from that same point)

// TO DO: error message generation should be moved to external class[es] that can analyze the entire stack trace and construct a clear description of the problem (currently each error class adds its own message, which results in lengthy, duplicative, and sometimes confusingly/misleadingly phrased message; e.g. if the root cause is "value not found", rest of the message chain should not talk about "coercion")


class GeneralError: Error, CustomStringConvertible {
    
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

class InternalError: GeneralError {} // an error that should never occur, unless [e.g.] triggered by an implementation bug elsewhere


class NotYetImplementedError: GeneralError {
    
    init(_ message: String? = nil, function: String = #function) {
        super.init("\(function)" + (message == nil ? "." : ": \(message!)"))
    }
}


/******************************************************************************/
// parse error

class SyntaxError: GeneralError {
    
    override init(_ message: String) { // TO DO: need to include parser for error reporting use; TO DO: more granular API that takes expected token description, found token, and position (what about previous token?)
        super.init(message)
    }
}

/******************************************************************************/
// coercion errors


class CoercionError: GeneralError {
    
    let value: Value
    let coercion: Coercion
    
    init(value: Value, coercion: Coercion) {
        self.value = value
        self.coercion = coercion
        super.init()
    }
    
    override var message: String {
        return "Can’t coerce the following \(self.value.nominalType) to \(self.coercion): \(self.value)"
    }
}


// TO DO: when to promote NullCoercionError to permanent error?

class NullCoercionError: CoercionError {
    
    override var message: String {
        return "Can’t coerce ‘\(self.value)’ to \(self.coercion)."
    }
    
} // coercing Nothing always throws NullCoercionError; this may be caught by AsDefault to supply a default value instead (optional parameter)



/******************************************************************************/


class ConstraintError: Error, CustomStringConvertible {
    
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



/******************************************************************************/
// environment lookup errors

class EnvironmentError: GeneralError { // abstract base class
    
    let name: String
    let env: Attributed // TO DO: rename 'scope' (since it may be Environment, AttributedValue, or some other exotica)
    
    init(name: String, env: Attributed) {
        self.name = name
        self.env = env
        super.init()
    }
}


// TO DO: these need better description of scope

class ValueNotFoundError: EnvironmentError { // TO DO: how should Environment/Scope lookup errors relate to AttributedValue lookup errors?

    override var message: String {
        //         return "Can’t find an attribute named “\(self.name)” on the following \(self.value.nominalType): \(self.value)"
        return "Can’t find a value named “\(self.name)” in \(self.env)."
    }
}

class HandlerNotFoundError: ValueNotFoundError {
    
    override var message: String {
        return "Can’t find a handler named “\(self.name)” in \(self.env)." // TO DO: message should adapt if slot exists but contains non-HandlerProtocol [caution: this'd need to capture slot immediately, or else take found value as argument, as deferring the slot lookup to here would create potential race]
    }
}


class ReadOnlyValueError: EnvironmentError {
    
    override var message: String {
        return "Can’t replace the non-editable value named “\(self.name)”."
    }
}


/******************************************************************************/
// command evaluation errors

class HandlerFailedError: GeneralError {
    
    let handler: HandlerProtocol
    let command: Command
    
    init(handler: HandlerProtocol, command: Command) { // TO DO: inspect Command and Handlers annotations for stack trace generation
        self.handler = handler
        self.command = command
        super.init()
    }
    override var message: String {
        return "The ‘\(self.handler.name)’ handler failed on the following command: \(self.command)"
    }
}


class BadArgumentError: GeneralError {
    
    let paramKey: String
    let argument: Value
    let command: Command
    let handler: Handler
    
    init(paramKey: String, argument: Value, command: Command, handler: Handler) {
        self.paramKey = paramKey
        self.argument = argument
        self.command = command
        self.handler = handler
        super.init()
    }
    
    override var message: String {
        guard let parameter = self.handler.interface.parameters.first(where: { $0.0 == self.paramKey }) else {
            // this will only happen if there's a bug in primitive handler where its interface's parameter definition and corresponding removeArgument call have mismatched labels
            fatalError("Implementation bug in \(self.handler.name) handler: mismatched parameter label `\(self.paramKey)` not in \(self.handler.interface)")
        }
        return "The ‘\(self.handler.interface.name)’ handler’s ‘\(parameter.label)’ parameter expected \(parameter.coercion.key) but received the following \(self.argument.nominalType): \(self.argument)" // TO DO: better coercion descriptions needed // TO DO: error message phrasing is misleading, as it implies a type error but can be triggered by other evaluation failures (e.g. value not found)
    }
}

class UnrecognizedArgumentError: GeneralError {
    
    let command: Command
    let handler: Handler
    
    init(command: Command, handler: Handler) {
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
