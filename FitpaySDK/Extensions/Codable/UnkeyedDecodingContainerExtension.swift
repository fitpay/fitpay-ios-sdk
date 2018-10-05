import Foundation

extension UnkeyedDecodingContainer {
    
    mutating func decode(_ type: [Any].Type, array: Bool) throws -> [Any] {
        var array: [Any] = []
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self, array: true) {
                array.append(nestedArray)
            }
        }
        return array
    }
    
    // TODO: better way to do this?
    mutating func decode<T>(_ type: [T].Type, array: Bool) throws -> [T]? {
        var array: [T] = []
        
        while isAtEnd == false {
            // See if the current value in the JSON array is `null` first and prevent infite recursion with nested arrays.
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(Double.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(String.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(Device.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(CreditCard.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(Transaction.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(Commit.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let value = try? decode(User.self) as? T, let nonNullValue = value {
                array.append(nonNullValue)
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) as? T, let nonNullValue = nestedDictionary {
                array.append(nonNullValue)
            } else if let nestedArray = try? decode(Array<Any>.self, array: true) as? T, let nonNullValue = nestedArray {
                array.append(nonNullValue)
            }
        }
        return array
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
    
}
