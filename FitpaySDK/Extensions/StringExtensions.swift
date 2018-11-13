extension String {
    
    func hexToData() -> Data? {
        let trimmedString = self.trimmingCharacters(in: CharacterSet(charactersIn: "<> ")).replacingOccurrences(of: " ", with: "")
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)
        let found = regex.firstMatch(in: trimmedString, options: [], range: NSRange(location: 0, length: trimmedString.count))
        
        if found == nil || found?.range.location == NSNotFound || trimmedString.count % 2 != 0 { return nil }
        
        let data = NSMutableData(capacity: trimmedString.count / 2)
        
        var index = trimmedString.startIndex
        while index < trimmedString.endIndex {
            let byteString = String(trimmedString[index ..< trimmedString.index(after: trimmedString.index(after: index))])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.append([num] as [UInt8], length: 1)
            index = trimmedString.index(after: trimmedString.index(after: index))
        }
        
        return data as Data?
    }
    
    // MARK: - Used in JWE
    
    static func random(_ size: Int) -> String {
        var randomNum = ""
        var randomBytes = [UInt8](repeating: 0, count: size)
        
        guard SecRandomCopyBytes(kSecRandomDefault, size, &randomBytes) == 0 else {
            return ""
        }
        
        // Turn randomBytes into array of hexadecimal strings
        // Join array of strings into single string
        randomNum = randomBytes.map({ String(format: "%02hhx", $0 )}).joined(separator: "")
        
        return randomNum.subString(0, length: size)
    }
    
    func base64URLdecoded() -> Data? {
        let base64EncodedString = convertBase64URLtoBase64(self)
        return Data(base64Encoded: base64EncodedString, options: NSData.Base64DecodingOptions(rawValue: 0))
    }
    
    // MARK: - Private
    
    private func subString(_ startIndex: Int, length: Int) -> String {
        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: startIndex + length)
        return String(self[start ..< end])
    }
    
    private func convertBase64URLtoBase64(_ encodedString: String) -> String {
        var tempEncodedString = encodedString.replacingOccurrences(of: "-", with: "+")
        tempEncodedString = tempEncodedString.replacingOccurrences(of: "_", with: "/")
        
        let equalsToBeAdded = encodedString.count % 4
        if equalsToBeAdded > 0 {
            for _ in 0..<equalsToBeAdded {
                tempEncodedString += "="
            }
        }
        return tempEncodedString
    }
    
}
