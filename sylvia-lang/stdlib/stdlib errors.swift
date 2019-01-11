//
//  stdlib_errors.swift
//


class UnsupportedSelectorError: GeneralError {
    let name: String
    let value: Value
    
    init(name: String, value: Value) {
        self.name = name
        self.value = value
    }
    
    override var message: String {
        return "The following \(self.value.nominalType) value doesn’t support the “\(self.name)” selector: \(self.value)"
    }
}


class OutOfRangeError: GeneralError {
    let value: Value
    let selector: Value
    
    init(value: Value, selector: Value) {
        self.value = value
        self.selector = selector
    }
    
    override var message: String {
        return "Can’t select \(self.selector) of the following value as it is out of range: \(self.value)"
    }
}

