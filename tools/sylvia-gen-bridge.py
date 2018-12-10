#!/usr/bin/env python3

# temporary script for generating `LIBNAME_handlers.swift` bridge file; once core language is complete, this will be replaced by swiftlib that generates glue code from native handler definitions (hence the Swift-style camelCase)

# TO DO: swiftlib should also generate Swift func stubs (encourages library developers to design user interface first), or check signatures against existing Swift funcs if already written

# TO DO: effects declarations

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
func call_««primitiveSignatureName»»(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {««unboxArguments»»
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


def _camelCase(s):
    res = []
    isUpper = False
    for c in s:
        if c == '_':
            isUpper = True
        elif isUpper:
            res.append(c.upper())
            isUpper = False
        else:
            res.append(c)
    return ''.join(res)


#######


# flags
primitiveHandlerName = 'swift_handler'

requiresScopes = 'requires_scopes'
commandEnv = 'command'
handlerEnv = 'handler'
bodyEnv = 'body'

canError = 'can_error'
ignoreUnknownArguments = 'ignore_unknown_arguments'

def renderHandlersBridge(libraryName, handlers, out=sys.stdout):
    defineHandlers = []
    loadHandlers = []
    for name, parameters, returnType, requirements in handlers:
        swiftFuncName = requirements.get(primitiveHandlerName) or _camelCase(name)
        # create unique identifier for handler's generated code (e.g. `FUNCTIONNAME_ARG1_ARG2_ARG3`)
        primitiveSignatureName = [swiftFuncName] + [_camelCase(k) for k,v in parameters]
        scopes = requirements.get(requiresScopes, set())
        if commandEnv in scopes: primitiveSignatureName.append("commandEnv")
        if handlerEnv in scopes: primitiveSignatureName.append("handlerEnv")
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
            callArguments.append(_render(_callArgument, count=i, paramLabel=_camelCase(k)))
        # if it's a command handler, add code to check all arguments supplied by command have been consumed
        if not requirements.get(ignoreUnknownArguments):
            unboxArguments.append(_render(_checkForUnexpectedArguments, parameterCount=i+1))
        # add any additional ('special') arguments for Swift function call
        if commandEnv in scopes: callArguments.append("\n\t\tcommandEnv: commandEnv")
        if handlerEnv in scopes: callArguments.append("\n\t\thandlerEnv: handlerEnv")
        
        
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
                tryKeyword='try ' if requirements.get(canError) else '',
                primitiveFunctionName=swiftFuncName,
                callArguments=','.join(callArguments),
                callReturn=callReturn))
        loadHandlers.append(_render(_loadHandler, primitiveSignatureName=primitiveSignatureName))
    
    # TO DO: write to file
    print(_render(_commentTemplate, libraryName=libraryName), file=out)
    print(''.join(defineHandlers), file=out)
    print(_render(_loaderTemplate, loadHandlers=''.join(loadHandlers)), file=out)



#######
# handler glue definitions for stdlib are currently hardcoded below; eventually primitive handler definitions should be written in native code using same syntax as for defining native handlers

# TO DO: update this table to use native underscore names (these will be converted to camelCase for idiomatic Swift code); still need to decide policy for native handler names (particularly when masked by operators)

handlers = [("exponent", [("a", "asScalar"), ("b", "asScalar")], "asScalar",
                    dict(can_error=True)), # TO DO: replace flags list with dict (native definitions will represent flags as `IDENTIFIER:VALUE`)
            
            # TO DO: optional 'swiftName', allowing native name to be symbol instead of words, e.g. `‘<’(a,b)`, not `if_less_than(a,b)`; as a rule of thumb, it's best that operators mask their own command names (when defining glue in native syntax, use quoted symbol in `to SIGNATURE` definition and include `Swift_name:IDENTIFIER` in block); Q. should `SwiftName` contain Swift parameter names as well, e.g. "isLessThan(lhs:rhs:)"?
            ("positive", [("a", "asScalar")], "asScalar",
                    dict(can_error=True)),
            ("negative", [("a", "asScalar")], "asScalar",
                    dict(can_error=True)),
            ("+", [("a", "asScalar"), ("b", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="add")),
            ("-", [("a", "asScalar"), ("b", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="subtract")),
            ("*", [("a", "asScalar"), ("b", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="multiply")),
            ("/", [("a", "asScalar"), ("b", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="divide")),
            ("div", [("a", "asDouble"), ("b", "asDouble")], "asDouble",
                    dict(can_error=True)),
            ("mod", [("a", "asDouble"), ("b", "asDouble")], "asDouble", 
                    dict(can_error=True)),
            ("<", [("a", "asDouble"), ("b", "asDouble")], "asBool", 
                    dict(swift_handler="isLessThan")),
            ("<=", [("a", "asDouble"), ("b", "asDouble")], "asBool", 
                    dict(swift_handler="isLessThanOrEqualTo")),
            ("==", [("a", "asDouble"), ("b", "asDouble")], "asBool", 
                    dict(swift_handler="isEqualTo")),
            ("!=", [("a", "asDouble"), ("b", "asDouble")], "asBool", 
                    dict(swift_handler="isNotEqualTo")),
            (">", [("a", "asDouble"), ("b", "asDouble")], "asBool", 
                    dict(swift_handler="isGreaterThan")),
            (">=", [("a", "asDouble"), ("b", "asDouble")], "asBool", 
                    dict(swift_handler="isGreaterThanOrEqualTo")),
            ("NOT", [("a", "asBool")], "asBool", 
                    dict()),
            ("AND", [("a", "asBool"), ("b", "asBool")], "asBool", 
                    dict()),
            ("OR", [("a", "asBool"), ("b", "asBool")], "asBool", 
                    dict()),
            ("XOR", [("a", "asBool"), ("b", "asBool")], "asBool", 
                    dict()),
            ("lt", [("a", "asString"), ("b", "asString")], "asBool", 
                    dict(can_error=True)),
            ("le", [("a", "asString"), ("b", "asString")], "asBool", 
                    dict(can_error=True)),
            ("eq", [("a", "asString"), ("b", "asString")], "asBool", 
                    dict(can_error=True)),
            ("ne", [("a", "asString"), ("b", "asString")], "asBool", 
                    dict(can_error=True)),
            ("gt", [("a", "asString"), ("b", "asString")], "asBool", 
                    dict(can_error=True)),
            ("ge", [("a", "asString"), ("b", "asString")], "asBool", 
                    dict(can_error=True)),
            ("&", [("a", "asString"), ("b", "asString")], "asString", 
                    dict(can_error=True, swift_handler="joinValues")),
            ("uppercase", [("a", "asString")], "asString", 
                    dict()),
            ("lowercase", [("a", "asString")], "asString", 
                    dict()),
            ("show", [("value", "asAnything")], "asNoResult", 
                    dict()),
            ("format_code", [("value", "asOptionalValue")], "asString", 
                    dict()),
            ("define_handler", [("name", "asString"),
                               ("parameters", "AsArray(asParameter)"),
                               ("return_type", "asCoercion"),
                               ("action", "asIs"),
                               ("is_event_handler", "asBool")
                               ], "asNoResult", 
                    dict(can_error=True, requires_scopes={commandEnv})),
            ("store", [("name", "asString"), ("value", "asOptionalValue"), ("readOnly", "asBool")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv})),
            ("if", [("condition", "asBool"), ("action", "asBlock")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="testIf")),
            ("repeat", [("count", "asInt"), ("action", "asBlock")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="repeatTimes")),
            ("while", [("condition", "asOptionalValue"), ("action", "asBlock")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="repeatWhile")),
            ("else", [("action", "asAnything"), ("elseAction", "asAnything")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="elseClause")),
            ("of", [("attribute", "asAttributedValue"), ("value", "asAnything")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="ofClause")),
            ("at", [("attribute", "asAttributedValue"), ("value", "asAnything")], "asIs", 
                    dict(can_error=True, swift_handler="atClause")),
    ]


with open("../sylvia-lang/stdlib/stdlib_handlers.swift", "w", encoding="utf-8") as f:
    renderHandlersBridge("stdlib", handlers, f)

