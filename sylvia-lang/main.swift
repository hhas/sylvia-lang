//
//  main.swift
//

// ad-hoc tests


import Foundation



let e = Env()


do {
    try stdlib_load(env: e)
} catch {
    print("ImportError: Can’t import stdlib due to \(type(of:error)): \(error)")
    exit(1)
}


let sd = Date()


/*

do { // evaluate to List of Text
    /*
        [“Hello”, “World”] as anything
        => [“Hello”, “World”]
     */
    let v = List([Text("Hello"), Text("World")])
    let t = AsValue()
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
         to addOne(n as number) returning number {
            1 + n
         }
     
         show(addOne(3))
         « “4.0” »
         => nothing
     */
    let h = Handler(CallableInterface(name: "addOne", parameters: [(name: "n", type: asDouble)], returnType: asDouble),
                    Command("+", [Text("1"), Identifier("n")]))
    try e.add(h)
    let v = Command("show", [Command("addOne", [Text("3")])])
    print(try asAnything.coerce(value: v, env: e)) // prints "4" and returns `nothing`
} catch {
    print(5, error)
}


do { // conditional
    /*
     testIf(value: "ok", ifTrue: show("yes"), ifFalse: show("no"))  // prints "yes"
     testIf(value: "", ifTrue: show("yes"), ifFalse: show("no"))    // prints "no"
     */
    for arg in [trueValue, falseValue] {
        let v = Command("testIf", [arg, Command("show", [Text("yes")]), Command("show", [Text("no")])])
        print(try asAnything.coerce(value: v, env: e))
    }
    // optional arguments and return values
    /*
     testIf(value: "ok", ifTrue: "42")      // returns "42"
     testIf(value: "", ifTrue: "42"))       // returns `nothing`
     testIf(value: nothing, ifTrue: "42"))  // returns `nothing`
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

//code = " repeatTimes (1000000, 1+2*3)" // 1M multiply&sum calculations = ~7sec (or ~300K arithmetic ops/sec); this is 30x slower than AppleScript (200ms), and 200x slower than Python (30ms). Currently interpreter is 100% non-optimizing (e.g. every number gets converted from String to Double every time it's used, and every calculated number is converted from Double to String), so interpreted performance will improve (e.g. Text values should include Scalar representation as annotation, avoiding constant String<->Double conversions; Text values might even have dedicated Number/Integer/Real subclasses just to speed up math, although that means adding more asTYPE methods to take advantage of them; Commands should be able to look up Handler once and, if it's read-only & non-maskable, cache [memoize] the Handler for future use; if nested handlers have compatible IO Swift types, how easy/hard to connect those Swift funcs directly via node transforms?); plus need to determine how much runtime optimization is worth the AST interpreter doing, vs cross-compiling program to Swift code?


//code = " 1 + \n 2 * 3" // TO DO: parser currently skips over newline in order to complete operator that it knows to be infix (otoh, if newline appears before `*` it reports syntax error); need to decide on syntax rules for wrapping expressions over multiple lines


code = "[π, 23.4e5, (1+2), “Hello\\nGoodbye”, [1,2,3]]"


code = """

to addOne(n) { + n + - 1 }

if addOne(3) > 0 {

    show ("more")

}

"""


let lexer = Lexer(code: code, operatorRegistry: ops)

let tokens = lexer.tokenize()




let p = Parser(tokens)

do {
    let s = try p.parseScript()
    print(s)
    let res = try s.run(env: e, type: asAnything)
    print(res)
} catch {
    print(error)
}

//for t in tokens { print((t.start.encodedOffset, t.end.encodedOffset), t.type, "  ⟹", code[t.start..<t.end].debugDescription) }




print("Duration: \(Date().timeIntervalSince(sd) * 1000)ms")
