//
//  type constants.swift
//

// convenience constants; use these when no additional constraints are needed

// basic evaluation

let asValue = AsValue() // any value except `nothing`; this is the default parameter coercion for native handlers

let asAnything = AsAnything() // any value or `nothing`; this is the default return coercion for native handlers and may be used to expand any value, including [nested] lists containing `nothing`, e.g. `[1,nothing] as optional(value) -> CoercionError`, whereas `[1,nothing] as anything -> [1,nothing]`


let asBool = AsBool()

let asScalar = AsScalar()
let asInt = AsInt()
let asDouble = AsDouble()
let asString = AsString()
let asText = AsText()

let asTag = AsTag()
let asTagKey = AsTagKey()

let asList = AsList(asValue)
let asRecord = AsRecord(asValue)
let asRecordKey = AsRecordKey()

// lazy evaluation

let asThunk = AsThunk(asAnything) // native handlers may use this to declare lazily evaluated parameters


// handler signatures

let asParameter = AsParameter()
let asCoercion = AsCoercion()

let asIs = AsIs() // supplied value is returned as-is, without expanding or thunking it; used in primitive handlers to take lazily-evaluated arguments that will be evaluated using the supplied `commandEnv` (primitive handlers should only need to thunk values that will be evaluated after the handler is returned)

let asIdentifierLiteral = AsIdentifierLiteral()
let asCommandLiteral = AsCommandLiteral()

let asBlock = asIs // primitive handlers don't really care if an argument is a block or an expression (to/if/repeat/etc operators should check for block syntax themselves), so for now just pass it to the handler body as-is (there's no need to thunk it either, unless the supplied block/expression needs to be retained beyond the handler call in which case it must be captured with the command scope, either by declaring the parameter coercion asThunk or by calling asThunk.coerce in the handler body)

let asNoResult = AsNoResult() // expands value to anything, ignoring any result, and always returns `nothing`; used as a handler's return type when no result is given/required


// references

let asAttributedValue = AsAttributedValue()
let asAttribute = AsAttribute()

let asReference = AsReference()
let asTestReference = asReference // TO DO: how easy to implement this? (being able to distinguish reference types will improve runtime error checking and tooling support)
