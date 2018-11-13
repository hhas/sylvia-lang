//
//  main.swift
//
//  genus Sylvia
//




let e = Env()


do {
    try stdlib_load(env: e)
} catch {
    fatalError("Can't load stdlib: \(error)")
}


do { // evaluate to List of Text
    /*
        [“Hello”, “World”] as anything
        => [“Hello”, “World”]
     */
    let v = List([Text("Hello"), Text("World")])
    let t = AsAny()
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
        « subtract(add(1, 2), 6) »
        1 + 2 - 6
        => “-3”
     */
    let v = Command("subtract", [Command("add", [Text("1"), Text("2")]), Text("6")])
    let t = asAny
    print(try t.coerce(value: v, env: e)) // "-3" // native
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
    let h = Handler(name: "addOne",
                    parameters: [(name: "n", type: asDouble)], result: asDouble,
                    body: Command("add", [Text("1"), Identifier("n")]))
    try e.add(h)
    let v = Command("show", [Command("addOne", [Text("3")])])
    let t = asAny
    print(try t.coerce(value: v, env: e)) // prints "4" and returns `nothing`
} catch {
    print(5, error)
}

