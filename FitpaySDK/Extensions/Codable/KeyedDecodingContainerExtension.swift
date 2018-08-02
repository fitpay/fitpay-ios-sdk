extension KeyedDecodingContainer {
    
    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        let dictionary = try container.decode(type)
        return dictionary
    }

    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }

        return dictionary
    }

    func decode<Transformer: DecodingContainerTransformer>(_ key: KeyedDecodingContainer.Key, transformer: Transformer) throws -> Transformer.Output? where Transformer.Input: Decodable {
        do {
            let decoded: Transformer.Input? = try self.decode(key)
            return transformer.transform(decoded)
        } catch {
            return nil
        }
    }

    func decode<T>(_ key: KeyedDecodingContainer.Key) throws -> T where T: Decodable {
        let object = try self.decode(T.self, forKey: key)
        return object
    }
    
    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        let object = try container.decode(type, array: true)
        return object
    }
    
    func decode<T>(_ type: Array<T>.Type, key: K) throws -> Array<T> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        let object = try container.decode(type, array: true)
        return object!
    }

}

