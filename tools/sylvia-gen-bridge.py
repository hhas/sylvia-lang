#!/usr/bin/env python3

# temporary script for generating `LIBNAME_handlers.swift` bridge file

# TO DO: option to generate Swift func stubs as well (encourages library developers to design user interface first)

# TO DO: insert file comment (this)

import sys


_signatureParameter = """
    paramType_««count»»: ««coercion»»,"""

_interfaceParameter = """
        ("««nativeName»»", signature_««primitiveSignatureName»».paramType_««count»»),"""

_unboxArgument = """
    let arg_««count»» = try signature_««primitiveSignatureName»».paramType_««count»».unboxArgument(at: ««count»», command: command, commandEnv: commandEnv, handler: handler)"""

_callArgument = """
        ««paramLabel»»: arg_««count»»""" # combine with context arguments and comma-separate

_checkForUnexpectedArguments = """
    if command.arguments.count > ««parameterCount»» { throw UnrecognizedArgumentError(command: command, handler: handler) }"""

_contextArguments = [ # TO DO: currently unused
        "commandEnv: commandEnv",
        "handlerEnv: handlerEnv",
        "bodyEnv: bodyEnv", # also need to insert Swift code to create lexical sub-env
] # what else? e.g. external IPC, FS, etc connections?

_callReturnIfResult = """
    return try signature_««primitiveSignatureName»».returnType.box(value: result, env: handlerEnv)"""

_callReturnIfNoResult = """
    return noValue"""

_handlerTemplate = """
// ««nativeName»»(…)
let signature_««primitiveSignatureName»» = (««signatureParameters»»
    returnType: ««returnType»»
)
let interface_««primitiveSignatureName»» = CallableInterface(
    name: "««nativeName»»",
    parameters: [««interfaceParameters»»
    ],
    returnType: signature_««primitiveSignatureName»».returnType
)
func call_««primitiveSignatureName»»(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, coercion: Coercion) throws -> Value {««unboxArguments»»
    ««resultAssignment»»««tryKeyword»»««primitiveFunctionName»»(««callArguments»»
    )««callReturn»»
}
"""

_loadHandler = """
    try env.add(interface_««primitiveSignatureName»», call_««primitiveSignatureName»»)"""

_loaderTemplate = """
func stdlib_loadHandlers(env: Env) throws {
    ««loadHandlers»»
}"""

_commentTemplate = """
//
//  ««libraryName»»_handlers.swift
//
//  Bridging code for primitive handlers. This file is auto-generated; do not edit directly.
//
"""


def _render(tpl, **kargs):
    tpl = tpl.replace("{", "{{").replace("}", "}}").replace("««", "{").replace("»»", "}")
    return tpl.format(**kargs)


#######


# flags
canError = 'canError'
commandEnv = 'commandEnv'
handlerEnv = 'handlerEnv'
bodyEnv = 'bodyEnv'
isEventHandler = 'isEventHandler'

def renderHandlersBridge(libraryName, handlers, out=sys.stdout):
    defineHandlers = []
    loadHandlers = []
    for name, parameters, returnType, requirements in handlers:
        # create unique identifier for handler's generated code (e.g. `FUNCTIONNAME_ARG1_ARG2_ARG3`)
        primitiveSignatureName = [name] + [k for k,v in parameters]
        if commandEnv in requirements: primitiveSignatureName.append("commandEnv")
        if handlerEnv in requirements: primitiveSignatureName.append("handlerEnv")
        primitiveSignatureName = '_'.join(primitiveSignatureName)
        # TO DO: bodyEnv (also requires extra line to create subenv)
        # insert code to unbox each argument; collect list of arguments for Swift function call
        signatureParameters = []
        interfaceParameters = []
        unboxArguments = []
        callArguments = []
        i = -1
        for i, (k,v) in enumerate(parameters):
            signatureParameters.append(_render(_signatureParameter, count=i, coercion=v))
            interfaceParameters.append(_render(_interfaceParameter, count=i, nativeName=k, primitiveSignatureName=primitiveSignatureName))
            unboxArguments.append(_render(_unboxArgument, count=i, primitiveSignatureName=primitiveSignatureName))
            callArguments.append(_render(_callArgument, count=i, paramLabel=k))
        # if it's a command handler, add code to check all arguments supplied by command have been consumed
        if isEventHandler not in requirements:
            unboxArguments.append(_render(_checkForUnexpectedArguments, parameterCount=i+1))
        # add any additional ('special') arguments for Swift function call
        if commandEnv in requirements: callArguments.append("\n\t\tcommandEnv: commandEnv")
        if handlerEnv in requirements: callArguments.append("\n\t\thandlerEnv: handlerEnv")
        
        
        if returnType == "asNoResult":
            resultAssignment = ""
            callReturn = _callReturnIfNoResult
        else:
            resultAssignment = "let result = "
            callReturn = _render(_callReturnIfResult, primitiveSignatureName=primitiveSignatureName)

        defineHandlers.append(_render(_handlerTemplate,
                nativeName=name,
                # signature/interface
                primitiveSignatureName=primitiveSignatureName,
                signatureParameters=''.join(signatureParameters),
                returnType=returnType,
                interfaceParameters=''.join(interfaceParameters),
                # call func
                unboxArguments=''.join(unboxArguments),
                resultAssignment=resultAssignment,
                tryKeyword='try ' if canError in requirements else '',
                primitiveFunctionName=name,
                callArguments=','.join(callArguments),
                callReturn=callReturn))
        loadHandlers.append(_render(_loadHandler, primitiveSignatureName=primitiveSignatureName))
    
    # TO DO: write to file
    print(_render(_commentTemplate, libraryName=libraryName), file=out)
    print(''.join(defineHandlers), file=out)
    print(_render(_loaderTemplate, loadHandlers=''.join(loadHandlers)), file=out)



#######
# handler glue definitions for stdlib are currently hardcoded below; eventually primitive handler definitions should be written in native code using same syntax as for defining native handlers

handlers = [("exponent", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
            ("positive", [("a", "asDouble")], "asDouble ", [canError]),
            ("negative", [("a", "asDouble")], "asDouble ", [canError]),
            ("add", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
            ("subtract", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
            ("multiply", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
            ("divide", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
            ("div", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
            ("mod", [("a", "asDouble"), ("b", "asDouble")], "asDouble", [canError]),
            ("isLessThan", [("a", "asDouble"), ("b", "asDouble")], "asBool", []),
            ("isLessThanOrEqualTo", [("a", "asDouble"), ("b", "asDouble")], "asBool", []),
            ("isEqualTo", [("a", "asDouble"), ("b", "asDouble")], "asBool", []),
            ("isNotEqualTo", [("a", "asDouble"), ("b", "asDouble")], "asBool", []),
            ("isGreaterThan", [("a", "asDouble"), ("b", "asDouble")], "asBool", []),
            ("isGreaterThanOrEqualTo", [("a", "asDouble"), ("b", "asDouble")], "asBool", []),
            ("NOT", [("a", "asBool")], "asBool", []),
            ("AND", [("a", "asBool"), ("b", "asBool")], "asBool", []),
            ("OR", [("a", "asBool"), ("b", "asBool")], "asBool", []),
            ("XOR", [("a", "asBool"), ("b", "asBool")], "asBool", []),
            ("lt", [("a", "asString"), ("b", "asString")], "asBool", [canError]),
            ("le", [("a", "asString"), ("b", "asString")], "asBool", [canError]),
            ("eq", [("a", "asString"), ("b", "asString")], "asBool", [canError]),
            ("ne", [("a", "asString"), ("b", "asString")], "asBool", [canError]),
            ("gt", [("a", "asString"), ("b", "asString")], "asBool", [canError]),
            ("ge", [("a", "asString"), ("b", "asString")], "asBool", [canError]),
            ("joinValues", [("a", "asString"), ("b", "asString")], "asString", [canError]),
            ("uppercase", [("a", "asString")], "asString", []),
            ("lowercase", [("a", "asString")], "asString", []),
            ("show", [("value", "asAnything")], "asNoResult", []),
            ("formatCode", [("value", "asOptionalValue")], "asString", []),
            ("defineHandler", [("name", "asString"),
                               ("parameters", "AsArray(asParameter)"),
                               ("returnType", "asCoercion"),
                               ("action", "asIs"),
                               ("isEventHandler", "asBool")
                               ], "asNoResult", [canError, commandEnv]),
            ("store", [("name", "asString"), ("value", "asOptionalValue"), ("readOnly", "asBool")], "asIs", [canError, commandEnv]),
            ("testIf", [("condition", "asBool"), ("action", "asBlock")], "asIs", [canError, commandEnv]),
            ("repeatTimes", [("count", "asInt"), ("action", "asBlock")], "asIs", [canError, commandEnv]),
            ("repeatWhile", [("condition", "asOptionalValue"), ("action", "asBlock")], "asIs", [canError, commandEnv]),
            ("elseClause", [("action", "asAnything"), ("elseAction", "asAnything")], "asIs", [canError, commandEnv]),
    ]


with open("../sylvia-lang/stdlib/stdlib_handlers.swift", "w", encoding="utf-8") as f:
    renderHandlersBridge("stdlib", handlers, f)

