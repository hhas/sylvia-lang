# Sylvia

(final name TBC)

## Example

    tell app “Finder” { get name of folder 1 of home }

## About

A stealth Lisp/Logo, devised as a modern, easy-to-use AppleScript successor.

Language core implements standard datatypes, environment, and eval loop functionality
only; all behaviors (including flow control) is supplied by optional libraries.
Operators are optional, library-defined, syntactic sugar over commands.

“[Almost] Everything is a command.”

Rich metadata, homoiconic syntax. Able to support GUI (Shortcuts-style) and voice (Siri)
control, in addition to traditional text (keyboard) input.

Weak, untyped: “If a value looks right, it [generally] is.” Rich coercion and constraint-
checking annotations for primitive/native handler parameters and results provide both
runtime safety and opportunities for automated compile-time correctness checks and/or
performance optimizations (via partial/full cross-compilation to Swift code).

Optional (library-enabled) metaprogramming support.

High-level native<->Swift bridging APIs makes new primitive libraries trivial to develop.
Type-conversion and constraint-checking for arguments and results is provided for free,
along with basic interface documentation.


## Status

* Some basic datatypes: Nothing, Text (including numbers), List, Record (dictionary).

* Some basic coercions: AsText, AsList, AsOptional, etc.

* Traditional, lexically-scoped constants/variables. Name masking is currently not allowed.

* Traditional commands, except that arguments are evaluated by receiving handler (allowing,
  e.g., lazy evaluation).

* Primitive & user-defined handlers; parameters can specify coercions (including lazy eval).

* No REPL [yet].

* No documentation.

* No guarantee it will ever become a complete, publicly-usable language itself.


## See also

https://bitbucket.org/hhas/entoli/
