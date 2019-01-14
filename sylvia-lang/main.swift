//
//  main.swift
//

// ad-hoc tests


import Foundation



let e = Env()


do {
    try stdlib_load(env: e)
    try aelib_load(env: e)
} catch {
    print("ImportError: Can’t import stdlib due to \(type(of:error)): \(error)")
    exit(1)
}


let sd = Date()


/*

do { // evaluate to List of Text
    /*
        [“Hello”, “World”] as value
        => [“Hello”, “World”]
     */
    let v = List([Text("Hello"), Text("World")])
    let t = asValue
    print(try t.coerce(value: v, env: e))
} catch {
    print(1, error)
}

do { // evaluate to Array<String>, resolving identifier
    /*
        let person = “Bob”
        [“Hello”, person] as primitive(list(text))
        => ["Hello", "Bob"] // Array<String>
     */
    try? e.set("person", to: Text("Bob"))
    let v = List([Text("Hello"), Identifier("person")])
    let t = AsArray(AsString())
    print(try t.unbox(value: v, env: e)) // Swift
} catch {
    print(2, error)
}

do { // evaluate to List of Text, using default value
    /*
        [“Hello”, nothing] as list(default(“stranger”, text))
        => [“Hello”, “stranger”]
     */
    let v = List([Text("Hello"), noValue])
    let t = AsList(AsDefault(AsString(), Text("stranger")))
    print(try t.coerce(value: v, env: e)) // native
} catch {
    print(3, error)
}

do { // evaluate commands
    /*
        « '-'('+'(1, 2), 6) »
        1 + 2 - 6
        => “-3”
     */
    let v = Command("-", [Command("+", [Text("1"), Text("2")]), Text("6")])
    print(try asAnything.coerce(value: v, env: e)) // "-3" // native
} catch {
    print(4, error)
}

do { // define and call native handler
    /*
         to add_one(n as number) returning number {
            1 + n
         }
     
         show(add_one(3))
         « “4.0” »
         => nothing
     */
    let h = Handler(CallableInterface(name: "addOne", parameters: [(name: "n", coercion: asDouble)], returnType: asDouble),
                    Command("+", [Text("1"), Identifier("n")]))
    try e.add(h)
    let v = Command("show", [Command("addOne", [Text("3")])])
    print(try asAnything.coerce(value: v, env: e)) // prints "4" and returns `nothing`
} catch {
    print(5, error)
}


do { // conditional
    /*
     test_if(value: "ok", action: "42")      // returns "42"
     test_if(value: "", action: "42"))       // returns `nothing`
     test_if(value: nothing, action: "42"))  // returns `nothing`
     */
    for arg in [trueValue, falseValue, noValue] {
        let v = Command("testIf", [arg, Text("42")])
        print(try asAnything.coerce(value: v, env: e))
    }
} catch {
    print(6, error)
}

*/



let ops = OperatorRegistry()
ops.add(stdlib_operators)

//print(ops.symbolLookup.debugDescription)

//let code = "(0.00003 *+ foo exp -2) / 2e5×-2-1.123456E-100 == nothing"

var code: String

code = """

'foo'

"hello"

xxx


"foo \\n bar "
"""

/*
 use framework "Foundation"
 property NSDate : class "NSDate"
 set d1 to NSDate's alloc()'s init()
 repeat 1000000 times
 1 + 2 * 3
 end repeat
 set d2 to NSDate's alloc()'s init()
 (((d2's timeIntervalSinceDate:d1) * 1000) as text) & "ms"
 --> "185.995101928711ms"
 */



//code = " 1 + \n 2 * 3" // TO DO: parser currently skips over newline in order to complete operator that it knows to be infix (otoh, if newline appears before `*` it reports syntax error); need to decide on syntax rules for wrapping expressions over multiple lines


code = "[π, 23.4e5, (1+2), “Hello\\nGoodbye”, [1,2,3]]"


code = """

to add_one(n) { n + 1 - x } «This throws ‘ValueNotFoundError: Can’t find a value named “x”.’»

if add_one(3) > 8 {

    show("4 > 8")

}

if 4 ≤ 8 { show("4 ≤ 8") }

"""

// TO DO: unprefixed annotations are developer comments; any practical way to determine annotation coercion, particularly user doc, if it starts with markdown syntax?

code = """
«foo.sy -- about this script»

«= Section =»

store ("name", "Bob")

«== Subsection ==»

"Hello" & ", " & name & "!"

«some comment»
"""


code = """
define_handler("test", [["x", optional]], no_result, {show ([1,x]), x}, false)

show([2,test(123)])

«show(test()) «`x` is optional parameter»»

"""

/*
code = """
define_handler("square", [["n", number]], number, {n * n}, false)

show(square(-4)) «prints “16.0”»

show("") «prints “”»

show(square("abc")) «CoercionError: can't coerce text to number»

"""
*/


code = """

if 3 > 5 {"yes"} else {"no"}

"""



code = """

to add_one (n) { n + 1 - x }

store ("x", -33)
store ("y", add_one (3))

if y > 8 {

    show ("4 > 8")
    y
}

"""


// code = " 2 thru 5 as list "
// code = " items at 2 thru 4 of [5,6,7,8] "

//code = " repeat 1000000 { 11.4 + 2 * 3 }" // 1M multiply&sum calculations = ~1.2sec (release build) vs ~0.3sec in AppleScript

//code = " (0x1234ABCDxyz) + 1"


//code = "\n[\nπ, 23.4e5, \n(\n1+2\n)\n, \n“Hello\\nGoodbye”, [1\n\n,\n\t2,3], «1+\n2»4\n]\n"


//code = "Store (“N”, 2), item -n of [5,6,7,8,9]" // TO DO: while `item at -EXPR of LIST` works fine, parsing `item -EXPR of LIST` currently causes a misleading runtime error ("ValueNotFoundError: Can’t find a value named “item”") as `-` symbol parses here as valid binary operator `((item - n) of list)`, which is worse than parse-time error; problem is that `-` is overloaded as both unary and binary operators, which is ambiguous but unavoidable as mathematical syntax [dialect] requires it); see TODO on parser re. enhancing stock parser with library-supplied issue detectors/resolvers. In this case, consuming the library's `-` operator definition would activate ambiguity analyzers that consider surrounding context; e.g. by attempting parse trees for both unary and binary `-` operators to see if one or both succeed, weighting each outcome with library's own expert knowledge (e.g. `of` operator expects its left operand to be of form `IDENTIFIER [ARGUMENT]`, so `IDENTIFIER BINARY_OPERATOR ARGUMENT` sequence would have a very suspect 'smell' whereas `IDENTIFIER UNARY_OPERATOR ARGUMENT` would smell fine), and making best guess/prompting user to choose at edit-time.



code = "Store (“N”, 2), [\n\t Item 2 of [5,6,7,8,9], \n\t Item at -n of [5,6,7,8,9], \n\t ITEM at 2 thru -2 of [5,6,7,8,9]\n]" // [7, 6]


code = "show ({ 1 + 1 })"


code = "color of text of documents of app “TextEdit”" // TO DO: element selectors aren't working yet


let lexer = Lexer(code: code, operatorRegistry: ops)

let tokens = lexer.tokenize()




let p = Parser(tokens)

do {
    print("\nCODE:")
    print(code)
    print("\nPARSE:")
    let s = try p.parseScript()
    print(s)
    print("\nEVAL:")
    let res = try s.nativeEval(env: e, coercion: asAnything)
    print(res)
} catch {
    print(error)
}

//for t in tokens { print((t.start.encodedOffset, t.end.encodedOffset), t.coercion, "  ⟹", code[t.start..<t.end].debugDescription) }



print("Duration: \(Date().timeIntervalSince(sd) * 1000)ms")



//print(appData.glueTable.elementsByName["documents"])
