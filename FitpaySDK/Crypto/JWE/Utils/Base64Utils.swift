extension Data {
    func base64URLencoded() -> String {
        var base64 = self.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        
        return base64
    }
}

extension String {
    func base64URLencoded() -> String? {
        return self.data(using: String.Encoding.utf8)?.base64URLencoded()
    }
    
    func base64URLdecoded() -> Data? {
        let base64EncodedString = convertBase64URLtoBase64(self)
        if let decodedData = Data(base64Encoded: base64EncodedString, options:NSData.Base64DecodingOptions(rawValue: 0)) {
            return decodedData
        }
        return nil
    }
    
    private func convertBase64URLtoBase64(_ encodedString: String) -> String {
        var tempEncodedString = encodedString.replacingOccurrences(of: "-", with: "+")
        tempEncodedString = tempEncodedString.replacingOccurrences(of: "_", with: "/")
        
        let equalsToBeAdded = encodedString.count % 4
        if (equalsToBeAdded > 0) {
            for _ in 0..<equalsToBeAdded {
                tempEncodedString += "="
            }
        }
        return tempEncodedString
    }
}
