extension KeyedEncodingContainer {
    
    mutating func encode<Transformer: EncodingContainerTransformer>(_ value: Transformer.Output?,
                                                                    forKey key: KeyedEncodingContainer.Key,
                                                                    transformer: Transformer) throws where Transformer.Input: Encodable {
        let transformed: Transformer.Input? = transformer.transform(value)
        try self.encode(transformed, forKey: key)
    }
    
    mutating func encode(_ value: [String: Any], forKey key: Key) throws {
        var container = nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        try container.encodeJSONDictionary(value)
    }
    
    mutating func encodeIfPresent(_ value: [String: Any]?, forKey key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        }
    }
    
    mutating func encode(_ value: [Any], forKey key: Key) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encodeJSONArray(value)
    }
    
    mutating func encodeIfPresent(_ value: [Any]?, key: Key) throws {
        if let value = value {
            try encode(value, forKey: key)
        }
    }

}

extension KeyedEncodingContainerProtocol where Key == JSONCodingKeys {
    
    mutating func encodeJSONDictionary(_ value: [String: Any]) throws {
        try value.forEach { (key, value) in
            let key = JSONCodingKeys(stringValue: key)!
            switch value {
            case let value as Bool:
                try encode(value, forKey: key)
            case let value as Int:
                try encode(value, forKey: key)
            case let value as String:
                try encode(value, forKey: key)
            case let value as Double:
                try encode(value, forKey: key)
            default:
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath + [key], debugDescription: "Invalid JSON value"))
            }
        }
    }
    
}
