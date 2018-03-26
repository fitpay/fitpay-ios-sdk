extension String {
    static func random(_ size: Int) -> String {
        var randomNum = ""
        var randomBytes = [UInt8](repeating: 0, count: size)
        
        guard SecRandomCopyBytes(kSecRandomDefault, size, &randomBytes) == 0 else {
            return ""
        }
        
        // Turn randomBytes into array of hexadecimal strings
        // Join array of strings into single string
        randomNum = randomBytes.map({String(format: "%02hhx", $0)}).joined(separator: "")
        
        return randomNum.subString(0, length: size)
    }
    
    func subString(_ startIndex: Int, length: Int) -> String
    {
        let start = self.index(self.startIndex, offsetBy: startIndex)
        let end = self.index(self.startIndex, offsetBy: startIndex + length)
        return String(self[start ..< end])
    }
}
