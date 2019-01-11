//
//  annotation.swift
//

// TO DO: should this use an enum that defines cases for standard/commonly-used annotations, plus an `.other(TYPE,DATA)` case for everything else (rarely-used annotations, third-party annotations, annotation types defined after public API has been finalized making new cases are harder to add)



let codeAnnotation = 1 // attached to every Value in AST, indicating its position in source code (note: positions will change when code is pretty-printed, presumably necessitating a re-parse of part/full source)

let operatorAnnotation = 2 // attached to every Command in AST declared by operator syntax, providing its OperatorDefinition (e.g. for use by pretty-printer)

// TO DO: what else? comments, disabled code, 'macros' (e.g. for disabling default imports)
