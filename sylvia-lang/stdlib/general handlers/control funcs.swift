//
//  stdlib/handlers/control.swift
//
// control flow

// TO DO: implement Icon-like evaluation, where there is only `test` + `action` parameters, and `didNothing` ('fail') is returned when test is false; that result can then be captured by an `else` operator, or coerced to `nothing` otherwise (advantage of this approach is more granular, composable code; e.g. `else` could also be applied to a `repeatWhile()` command to execute alternative branch if zero iterations are performed)

// note: while primitive functions can use Thunks for lazily evaluated arguments, it's cheaper just to pass the command's arguments as-is plus the command's environment and evaluate directly

// TO DO: where a handler function evals a value, the handler signature's returnType should propagate up to action.nativeEval(); alternatively, function might encapsulate action in a Value which is returned to the wrapper to force

func testIf(condition: Bool, action: Value, commandEnv: Scope) throws -> Value {
    return try condition ? action.nativeEval(env: commandEnv, coercion: asAnything) : didNothing
}

func repeatTimes(count: Int, action: Value, commandEnv: Scope) throws -> Value {
    var count = count
    var result: Value = didNothing
    while count > 0 {
        result = try action.nativeEval(env: commandEnv, coercion: asAnything)
        count -= 1
    }
    return result
}


func repeatWhile(condition: Value, action: Value, commandEnv: Scope) throws -> Value {
    var result: Value = didNothing // TO DO: returning `didNothing` (implemented as subclass of NoValue?) will allow composition with infix `else` operator (ditto for `if`, etc); need to figure out precise semantics for this (as will NullCoercionErrors, the extent to which such a value can propagate must be strictly limited, with the value converting to noValue if not caught and handled immediately; one option is to define an `AsDidNothing(TYPE)` coercion which can unbox/coerce the nothing as a special case, e.g. returning a 2-case enum/returning didNothing rather than coercing it to noValue [which asAnything/asOptional/asDefault should do])
    while try asBool.unbox(value: condition, env: commandEnv) {
        result = try action.nativeEval(env: commandEnv, coercion: asAnything)
    }
    return result
}


func elseClause(action: Value, alternativeAction: Value, commandEnv: Scope) throws -> Value { // TO DO: see TODO on AsAnything re. limiting scope of `didNothing` result
    let result = try action.nativeEval(env: commandEnv, coercion: asAnything)
    //print("action returned: \(result)")
    return result is DidNothing ? try alternativeAction.nativeEval(env: commandEnv, coercion: asAnything) : result
}


