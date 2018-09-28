import Foundation

extension Dictionary {
    var JSONString: String? {
        return Foundation.JSONSerialization.JSONString(self)
    }
}

func += <KeyType, ValueType> (left: inout [KeyType: ValueType], right: [KeyType: ValueType]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

func + <KeyType, ValueType> (left: [KeyType: ValueType], right: [KeyType: ValueType]) -> [KeyType: ValueType] {
    var dict: [KeyType: ValueType] = [KeyType: ValueType]()
    
    for (k, v) in left {
        dict.updateValue(v, forKey: k)
    }
    
    for (k, v) in right {
        dict.updateValue(v, forKey: k)
    }
    
    return dict
}
