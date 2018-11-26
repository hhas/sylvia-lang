#!/usr/bin/env python3

# temporary script for generating `LIBNAME_handlers.swift` bridge file

# TO DO: option to generate Swift func stubs as well

# TO DO: insert unrecognized argument checks into command handler call_ funcs

# TO DO: insert file comment

signatureParameter = """
	paramType_««count»»: ««type»»,"""

interfaceParameter = """
		("««nativeName»»", signature_««primitiveSignatureName»».paramType_««count»»),"""

unboxArgument = """
	let arg_««count»» = try signature_««primitiveSignatureName»».paramType_««count»».unboxArgument(at: ««count»», command: command, commandEnv: commandEnv, handler: handler)"""

callArgument = """
		««paramLabel»»: arg_««count»»""" # combine with context arguments and comma-separate

checkForUnexpectedArguments = """
    if command.arguments.count > ««parameterCount»» { throw UnrecognizedArgumentError(command: command, handler: handler) }"""

contextArguments = [
		"commandEnv: commandEnv",
		"handlerEnv: handlerEnv",
		"bodyEnv: bodyEnv", # also need to insert Swift code to create this
] # what else? e.g. external IPC, FS, etc connections?

callReturnIfResult = """
    return try signature_««primitiveSignatureName»».returnType.box(value: result, env: handlerEnv)"""

callReturnIfNoResult = """
    return noValue"""

handlerTemplate = """
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
func call_««primitiveSignatureName»»(command: Command, commandEnv: Env, handler: CallableValue, handlerEnv: Env, type: Coercion) throws -> Value {««unboxArguments»»
    ««resultAssignment»»««tryKeyword»»««primitiveFunctionName»»(««callArguments»»
    )««callReturn»»
}
"""

loadHandler = """
    try env.add(interface_««primitiveSignatureName»», call_««primitiveSignatureName»»)"""

loaderTemplate = """
func stdlib_loadHandlers(env: Env) throws {
    ««loadHandlers»»
}"""

# flags
canError = 'canError'
commandEnv = 'commandEnv'
handlerEnv = 'handlerEnv'
bodyEnv = 'bodyEnv'
isEventHandler = 'isEventHandler'


def format(tpl, **kargs):
	tpl = tpl.replace("{", "{{").replace("}", "}}").replace("««", "{").replace("»»", "}")
	return tpl.format(**kargs)

def renderHandlersBridge(handlers):
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
			signatureParameters.append(format(signatureParameter, count=i, type=v))
			interfaceParameters.append(format(interfaceParameter, count=i, nativeName=k, primitiveSignatureName=primitiveSignatureName))
			unboxArguments.append(format(unboxArgument, count=i, primitiveSignatureName=primitiveSignatureName))
			callArguments.append(format(callArgument, count=i, paramLabel=k))
		# if it's a command handler, add code to check all arguments supplied by command have been consumed
		if isEventHandler not in requirements:
			unboxArguments.append(format(checkForUnexpectedArguments, parameterCount=i+1))
		# add any additional ('special') arguments for Swift function call
		if commandEnv in requirements: callArguments.append("\n\t\tcommandEnv: commandEnv")
		if handlerEnv in requirements: callArguments.append("\n\t\thandlerEnv: handlerEnv")
		
		
		if returnType == "asNoResult":
			resultAssignment = ""
			callReturn = callReturnIfNoResult
		else:
			resultAssignment = "let result = "
			callReturn = format(callReturnIfResult, primitiveSignatureName=primitiveSignatureName)

		defineHandlers.append(format(handlerTemplate,
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
		loadHandlers.append(format(loadHandler, primitiveSignatureName=primitiveSignatureName))
    
    # TO DO: write to file
	print(''.join(defineHandlers))
	print(format(loaderTemplate, loadHandlers=''.join(loadHandlers)))


# stdlib handlers are currently hardcoded here; eventually primitive handler definitions should be written in native code using same syntax as for defining native handlers
handlers = [
	("exponent", [("a", "asDouble"), ("b", "asDouble")], "asDouble ", [canError]),
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
	("show", [("value", "asAnythingOrNothing")], "asNoResult", []),
	("defineHandler", [("name", "asString"),
                       ("parameters", "AsArray(asParameter)"),
                       ("returnType", "asCoercion"),
                       ("action", "asIs"),
                       ("isEventHandler", "asBool")
                       ], "asNoResult", [canError, commandEnv]),
	("store", [("name", "asString"), ("value", "asAnythingOrNothing"), ("readOnly", "asBool")], "asIs", [canError, commandEnv]),
	("testIf", [("condition", "asBool"), ("action", "asBlock")], "asIs", [canError, commandEnv]),
	("repeatTimes", [("count", "asInt"), ("action", "asBlock")], "asIs", [canError, commandEnv]),
	("repeatWhile", [("condition", "asAnythingOrNothing"), ("action", "asBlock")], "asIs", [canError, commandEnv]),
	]

renderHandlersBridge(handlers)

