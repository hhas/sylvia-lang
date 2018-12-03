//
//  stdlib_load.swift
//



/* TO DO:
 
 - once language is fully bootstrapped, LIBRARY_bridge.swift files should be 100% code-generated from native interface declarations; hopefully this can be done using existing syntax and operators/commands, the only difference is that when running IDC scripts, FFILib is loaded *instead of* (on top of?) stdlib, redefining the standard `define…Handler` and `store` commands to emit LIBNAME_bridge.swift code instead of modifying env
 
 - consider supporting .nonMutating/.mutatesOnce/.mutating flags for indicating side effects ('mutatesOnce' = idempotent; once called, subsequent identical calls have no additional effect)
 
 - for FFI syntax, e.g. (assuming `NAME:VALUE` is assignment):
 
 to '+' (a as primitive number, b as primitive number) returning primitive number {
 
 primitiveFunc:      add
 operatorParseFunc:  parseInfixOperator
 aliases:            [add]
 throws:             true
 commandEnv:         false
 handlerEnv:         false
 bodyEnv:            false
 
 }
 
 Requirements may be declared as assignments within the block. (All requirement declarations should be optional; if omitted, defaults are used.)
 
 
 A further improvement would be to parse top-level function declarations of NAMElib.swift, allowing the bound name to be checked and eliminating need for explicit `primitive` operator, and `throws`, `commandEnv`/`handlerEnv`/`bodyEnv` requirements (as these can be determined from Swift func's signature).
 
 (Longer term, requirements section might include an option to extract the Swift function's body to code template suitable for cross-compiler to inline.)
 

 - how should external entry point be named/declared?  consider using LibraryLoader protocol, as this will allow e.g. documentation generator to introspect the library without having to load everything into an actual environment

 - what about operator aliases? operator-sugared handlers must (currently?) be stored under operator's canonical name, which is not necessarily the same as primitive function's canonical name

 - catch and rethrow as ImportError?

 - stdlib_load() adds directly to supplied env; it doesn't create a module scope of its own; Q. who should be responsible for creating module namespaces? (and who is responsible for adding modules to a global namespace where scripts can access them); Q. what is naming convention for 3rd-party modules? (e.g. reverse domain), and how will those modules appear in namespace (e.g. flat/custom name or hierarchical names [e.g. `com.foo.module[.handler]`])

 - loading should never fail (unless there's a module implementation bug, e.g. duplicate name); how practical to guarantee error-free module loading, in which case LIBNAME_load can be non-throwing?

 - how best to store & lazily load user documentation? (may be simplest just to include original bridge definition files in library bundle; if documentation is requested then read and parse/secure-eval those files)

 - to what extent can/should primitive funcs be declared public, allowing optimizing cross-compiler to discard native<->Swift conversions and bypass PrimitiveHandler implementation whenever practical? e.g. `Command("add",[Text("1"),Text("2")])` should cross-compile to `try stdlib.add(a:1,b:2)` (note that even when full reductions can't be done due to insufficient detail/partial coercion matches, lesser reductions can still be achieved using coercion info from PrimitiveHandler's introspection APIs, e.g. `try asDouble.box(stdlib.add(a:asDouble.unbox(…),b:asDouble.unbox(…)),…)` would save an Env lookup and some function calls, at cost of less precise error messages when a non-numeric value is passed as argument); the final optimization step would be to eliminate the library call entirely and insert templated Swift code directly (this is mostly useful for standard arithmetic and conditional operators, and conditional, loop, and error handling blocks, which are both simple and frequent enough to warrant the extra code generation logic, at least in stdlib)

*/



func stdlib_load(env: Env) throws {
    try stdlib_loadConstants(env: env)
    try stdlib_loadCoercions(env: env)
    try stdlib_loadHandlers(env: env)
}

