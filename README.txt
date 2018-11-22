# Sylvia

Sylvia (genus) = typical warblers, closely related to Old World babblers


## About

Experimental AST-walking interpreter for a weak, untyped (Algol-ish) language.

Primarily created as a testbed for standardized native<->Swift bridging APIs.

Goal is to eliminate need for manual boilerplate code when implementing primitive libraries.
Moving all bridging logic into standard Coercion classes avoids polluting Swift function
implementations with bridging code (c.f. Python/Ruby extensions), making primitive libraries
simpler, quicker, and less error-prone to create.

Separate bridging logic also makes it easy to autogenerate handler documentation for users,
and facilitates compilation of native code to Swift. e.g. Given a primitive library with
`foo() as text` and `bar(someArg as text)` handlers, the native script `bar(foo)` can be
reduced to Swift code `bar(a:foo())` that calls the primitive library's underlying Swift
functions (`foo()->String` and `bar(someArg:String)`) directly, without the redundant
boxing/unboxing.

(Note that while the surface language [if implemented] would be a C/Pascal-lookalike,
its AST representation is more Lisp-ish in nature, where all code is data and vice-versa,
although without the uniformity of Lisp's "everything is a list"; thus native code
generation/rewrites could be done purely by creating/manipulating native values within
the language itself, though with rather more distinct datatypes than in Lisp.)


## Status

* Some basic datatypes: Nothing, Text, List.

* Some basic coercions: AsText, AsList, AsOptional, etc.

* Traditional, lexically-scoped constants/variables. Name masking is currently not allowed.

* Traditional commands, except arguments are evaluated less eagerly by consuming handler.

* Primitive & user-defined handlers; parameters can specify coercions (including lazy eval).

* No REPL [yet].

* No documentation.

* No guarantee it will ever become a complete, publicly-usable language itself.


## See also

https://bitbucket.org/hhas/entoli/
