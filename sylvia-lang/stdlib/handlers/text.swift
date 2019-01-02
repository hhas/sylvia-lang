//
//  stdlib/handlers.swift
//

/******************************************************************************/
// text manipulation

func uppercase(text: String) -> String { return text.uppercased() }
func lowercase(text: String) -> String { return text.lowercased() }



func formatCode(value: Value) -> String {
    return value.description
}

