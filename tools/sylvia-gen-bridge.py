#!/usr/bin/env python3

# temporary script for generating `LIBNAME_handlers.swift` bridge file; once core language is complete, this will be replaced by swiftlib that generates glue code from native handler definitions (hence the Swift-style camelCase)

# TO DO: swiftlib should also generate Swift func stubs (encourages library developers to design user interface first), or check signatures against existing Swift funcs if already written

# TO DO: effects declarations

# TO DO: method wrappers (probably implement as standard subclass/sibling of PrimitiveHandler containing a `target` Value; similar to how Python implements instance methods by enclosing function objects in <bound method> wrappers)

# TO DO: along with library-defined 'effects' declarations, PrimitiveHandler.init() should be passed a 'boundHandler' flag indicating that the handler body has "free variables" (i.e. the primitive handler function takes a handlerEnv: parameter) so must capture its lexical environment (by wrapping both in a BoundHandler instance) in order to be passed around as a value (closure)


import sys


_signatureParameter = """
    paramType_««count»»: ««coercion»»,"""

_interfaceParameter = """
        ("««nativeName»»", "", signature_««primitiveSignatureName»».paramType_««count»»),"""

_unboxArgument = """
    let arg_««count»» = try signature_««primitiveSignatureName»».paramType_««count»».unboxArgument("««nativeName»»", in: &arguments, commandEnv: commandEnv, command: command, handler: handler)"""

_functionArgument = """
        ««swiftParamName»»: arg_««count»»""" # combine with context arguments and comma-separate

_checkForUnexpectedArguments = """
    if arguments.count > 0 { throw UnrecognizedArgumentError(command: command, handler: handler) }"""

_contextArguments = [ # TO DO: currently unused
        "commandEnv: commandEnv",
        "handlerEnv: handlerEnv",
        "bodyEnv: bodyEnv", # also need to insert Swift code to create lexical sub-env
] # what else? e.g. external IPC, FS, etc connections?

_functionReturnIfResult = """
    return try signature_««primitiveSignatureName»».returnType.box(value: result, env: handlerEnv)"""

_functionReturnIfNoResult = """
    return noValue"""

_handlerTemplate = """
// ««nativeName»» (««nativeArgumentNames»»)
let signature_««primitiveSignatureName»» = (««signatureParameters»»
    returnType: ««returnType»»
)
let interface_««primitiveSignatureName»» = CallableInterface(
    name: "««nativeName»»",
    parameters: [««interfaceParameters»»
    ],
    returnType: signature_««primitiveSignatureName»».returnType
)
func function_««primitiveSignatureName»»(command: Command, commandEnv: Scope, handler: CallableValue, handlerEnv: Scope, coercion: Coercion) throws -> Value {
    var arguments = command.arguments ««unboxArguments»»
    ««resultAssignment»»««tryKeyword»»««primitiveFunctionName»»(««functionArguments»»
    )««functionReturn»»
}
"""

_loadHandler = """
    try env.add(interface_««primitiveSignatureName»», function_««primitiveSignatureName»»)"""

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
primitiveClassName = 'swift_class'

requiresScopes = 'requires_scopes'
commandEnv = 'command'
handlerEnv = 'handler'
bodyEnv = 'body'

canError = 'can_error'

ignoreUnknownArguments = 'ignore_unknown_arguments' # event handler


def renderHandlersBridge(libraryName, handlers, out=sys.stdout):
    defineHandlers = []
    loadHandlers = []
    for name, parameters, returnType, requirements in handlers:
        swiftFuncName = requirements.get(primitiveClassName) or requirements.get(primitiveHandlerName) or _camelCase(name)
        # create unique identifier for handler's generated code (e.g. `FUNCTIONNAME_ARG1_ARG2_ARG3`)
        primitiveSignatureName = [swiftFuncName] + [_camelCase(k) for k,v in parameters]
        scopes = requirements.get(requiresScopes, set())
        if commandEnv in scopes: primitiveSignatureName.append("commandEnv")
        if handlerEnv in scopes: primitiveSignatureName.append("handlerEnv")
        primitiveSignatureName = '_'.join(primitiveSignatureName)
        # TO DO: bodyEnv (also requires extra line to create subenv)
        # insert code to unbox each argument; collect list of arguments for Swift function call
        nativeArgumentNames = []
        signatureParameters = []
        interfaceParameters = []
        unboxArguments = []
        functionArguments = []
        i = -1
        for i, param in enumerate(parameters):
            label, binding, coercion = param if len(param) == 3 else (param[0], _camelCase(param[0]), param[1])
            nativeArgumentNames.append(label)
            signatureParameters.append(_render(_signatureParameter, count=i, coercion=coercion))
            interfaceParameters.append(_render(_interfaceParameter, count=i, nativeName=label, primitiveSignatureName=primitiveSignatureName))
            unboxArguments.append(_render(_unboxArgument, count=i, nativeName=label, primitiveSignatureName=primitiveSignatureName))
            functionArguments.append(_render(_functionArgument, count=i, swiftParamName=binding))
        # if it's a command handler, add code to check all arguments supplied by command have been consumed
        if not requirements.get(ignoreUnknownArguments):
            unboxArguments.append(_render(_checkForUnexpectedArguments, parameterCount=i+1))
        # add any additional ('special') arguments for Swift function call
        if commandEnv in scopes: functionArguments.append("\n\t\tcommandEnv: commandEnv")
        if handlerEnv in scopes: functionArguments.append("\n\t\thandlerEnv: handlerEnv")
        
        if requirements.get(primitiveClassName):
            resultAssignment = "return "
            functionReturn = ""
        elif returnType == "asNoResult":
            resultAssignment = ""
            functionReturn = _functionReturnIfNoResult
        else:
            resultAssignment = "let result = "
            functionReturn = _render(_functionReturnIfResult, primitiveSignatureName=primitiveSignatureName)

        defineHandlers.append(_render(_handlerTemplate,
                nativeName=name,
                nativeArgumentNames=', '.join(nativeArgumentNames),
                # signature/interface
                primitiveSignatureName=primitiveSignatureName,
                signatureParameters=''.join(signatureParameters),
                returnType=returnType,
                interfaceParameters=''.join(interfaceParameters),
                # function func
                unboxArguments=''.join(unboxArguments),
                resultAssignment=resultAssignment,
                tryKeyword='try ' if requirements.get(canError) else '',
                primitiveFunctionName=swiftFuncName,
                functionArguments=','.join(functionArguments),
                functionReturn=functionReturn))
        loadHandlers.append(_render(_loadHandler, primitiveSignatureName=primitiveSignatureName))
    
    # TO DO: write to file
    print(_render(_commentTemplate, libraryName=libraryName), file=out)
    print('\n'.join(defineHandlers), file=out)
    print(_render(_loaderTemplate, loadHandlers=''.join(loadHandlers)), file=out)



#######
# handler glue definitions for stdlib are currently hardcoded below; eventually primitive handler definitions should be written in native code using same syntax as for defining native handlers

# TO DO: update this table to use native underscore names (these will be converted to camelCase for idiomatic Swift code); still need to decide policy for native handler names (particularly when masked by operators)

# parameter tuples must be (LABEL, BINDING, COERCION) or (LABEL, COERCION); if the latter, binding = camelCase(LABEL)

handlers = [("exponent", [("left", "asScalar"), ("right", "asScalar")], "asScalar",
                    dict(can_error=True)), # TO DO: replace flags list with dict (native definitions will represent flags as `IDENTIFIER:VALUE`)
            
            # note: by default, underscore handler names automatically map to camel-case Swift function names, e.g. `foo_bar` would map to `fooBar`; use `dict(swift_handler="FUNCNAME")` to specify a different mapping (e.g. if native name is a symbol or reserved/ambiguous in Swift)
            # as a rule of thumb, it's best that operators mask their own command names (when defining glue in native syntax, use quoted symbol in `to SIGNATURE` definition and include `Swift_name:IDENTIFIER` in block)
            ("positive", [("left", "asScalar")], "asScalar",
                    dict(can_error=True)),
            ("negative", [("left", "asScalar")], "asScalar",
                    dict(can_error=True)),
            
            ("+", [("left", "asScalar"), ("right", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="add")),
            ("-", [("left", "asScalar"), ("right", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="subtract")),
            ("*", [("left", "asScalar"), ("right", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="multiply")),
            ("/", [("left", "asScalar"), ("right", "asScalar")], "asScalar",
                    dict(can_error=True, swift_handler="divide")),
            ("div", [("left", "asDouble"), ("right", "asDouble")], "asDouble",
                    dict(can_error=True)),
            ("mod", [("left", "asDouble"), ("right", "asDouble")], "asDouble",
                    dict(can_error=True)),
            
            ("<", [("left", "asDouble"), ("right", "asDouble")], "asBool",
                    dict(swift_handler="isLessThan")),
            ("<=", [("left", "asDouble"), ("right", "asDouble")], "asBool",
                    dict(swift_handler="isLessThanOrEqualTo")),
            ("==", [("left", "asDouble"), ("right", "asDouble")], "asBool",
                    dict(swift_handler="isEqualTo")),
            ("!=", [("left", "asDouble"), ("right", "asDouble")], "asBool",
                    dict(swift_handler="isNotEqualTo")),
            (">", [("left", "asDouble"), ("right", "asDouble")], "asBool",
                    dict(swift_handler="isGreaterThan")),
            (">=", [("left", "asDouble"), ("right", "asDouble")], "asBool",
                    dict(swift_handler="isGreaterThanOrEqualTo")),
            
            ("NOT", [("right", "asBool")], "asBool",
                    dict()),
            ("AND", [("left", "asBool"), ("right", "asBool")], "asBool",
                    dict()),
            ("OR", [("left", "asBool"), ("right", "asBool")], "asBool",
                    dict()),
            ("XOR", [("left", "asBool"), ("right", "asBool")], "asBool",
                    dict()),
            
            ("lt", [("left", "asString"), ("right", "asString")], "asBool",
                    dict(can_error=True)),
            ("le", [("left", "asString"), ("right", "asString")], "asBool",
                    dict(can_error=True)),
            ("eq", [("left", "asString"), ("right", "asString")], "asBool",
                    dict(can_error=True)),
            ("ne", [("left", "asString"), ("right", "asString")], "asBool",
                    dict(can_error=True)),
            ("gt", [("left", "asString"), ("right", "asString")], "asBool",
                    dict(can_error=True)),
            ("ge", [("left", "asString"), ("right", "asString")], "asBool",
                    dict(can_error=True)),
            
            ("is_a", [("value", "asAnything"), ("of_type", "asCoercion")], "asBool",
                    dict()),
            ("&", [("left", "asString"), ("right", "asString")], "asString",
                    dict(can_error=True, swift_handler="joinValues")),
            
            ("uppercase", [("text", "asString")], "asString",
                    dict()),
            ("lowercase", [("text", "asString")], "asString",
                    dict()),
            
            ("show", [("value", "asAnything")], "asNoResult", 
                    dict()),
            ("format_code", [("value", "asAnything")], "asString",
                    dict()),
            
            ("define_handler", [("name", "asString"), # TO DO: use asSymbolKey
                               ("parameters", "AsArray(asParameter)"),
                               ("return_type", "asCoercion"),
                               ("action", "asIs"),
                               ("is_event_handler", "asBool")
                               ], "asNoResult", 
                    dict(can_error=True, requires_scopes={commandEnv})),
            ("store", [("key", "asSymbolKey"), ("value", "asAnything"), ("readOnly", "asBool")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv})),
            ("as", [("value", "asAnything"), ("coercion", "asCoercion")], "asIs", # TO DO: Precis on return type to describe its relationship to 'coercion' arg
             dict(can_error=True, requires_scopes={commandEnv}, swift_handler="coerce")),

            ("if", [("condition", "asBool"), ("action", "asBlock")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="testIf")),
            ("repeat", [("count", "asInt"), ("action", "asBlock")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="repeatTimes")),
            ("while", [("condition", "asAnything"), ("action", "asBlock")], "asIs", 
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="repeatWhile")),
            ("else", [("action", "asAnything"), ("alternative_action", "asAnything")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="elseClause")),
            
            ("of", [("attribute", "asAttribute"), ("value", "asAttributedValue")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="ofClause")),
            
            ("at", [("element_type", "asSymbolKey"), ("selector_data", "asAnything")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="indexSelector")),
            ("named", [("element_type", "asSymbolKey"), ("selector_data", "asAnything")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="nameSelector")),
            ("with_id", [("element_type", "asSymbolKey"), ("selector_data", "asAnything")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="idSelector")),
            ("where", [("element_type", "asSymbolKey"), ("selector_data", "asReference")], "asIs",
                    dict(can_error=True, requires_scopes={commandEnv}, swift_handler="testSelector")),
            
            ("thru", [("from", "asValue"), ("to", "asValue")], "asIs",
                    dict(swift_class="Range")),
           
    ]


with open("../sylvia-lang/stdlib/stdlib_handlers.swift", "w", encoding="utf-8") as f:
    renderHandlersBridge("stdlib", handlers, f)

