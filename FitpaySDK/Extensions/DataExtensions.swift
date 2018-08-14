import Foundation

extension Data {
    
    var UTF8String: String? {
        return self.stringWithEncoding(String.Encoding.utf8)
    }
    
    @inline(__always) func stringWithEncoding(_ encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
    
    var dictionary: Dictionary<String, Any>? {
        guard let dictionary: [String: Any] = try? JSONSerialization.jsonObject(with: self, options:.mutableContainers) as! [String: Any] else { return nil }
        
        return dictionary
    }
    
    var errorMessages: [String]? {
        var messages: [String]? = []
        
        guard let dict: [String: Any] = self.dictionary,
            let errors = dict["errors"] as? [[String: String]] else {
                return messages
        }
        
        for error in errors {
            if let message = error["message"] {
                messages!.append(message)
            }
        }
        
        return messages
    }
    
    var errorMessage: String? {
        guard let dict = self.dictionary,
            let messageDict = dict as? [String: String],
            let message = messageDict["message"] else {
                return nil
        }
        
        return message
    }
    
    var hex: String {
        var s = ""
        
        var byte: UInt8 = 0
        for i in 0 ..< self.count {
            (self as NSData).getBytes(&byte, range: NSMakeRange(i, 1))
            s += String(format: "%02x", byte)
        }
        
        return s
    }
    
    var reverseEndian: Data {
        var inData = [UInt8](repeating: 0, count: self.count)
        (self as NSData).getBytes(&inData, length: self.count)
        var outData = [UInt8](repeating: 0, count: self.count)
        var outPos = inData.count;
        for i in 0 ..< inData.count {
            outPos -= 1
            outData[i] = inData[outPos]
        }
        let out = Data(bytes: UnsafePointer<UInt8>(outData), count: outData.count)
        return out
    }
    
    func base64URLencoded() -> String {
        var base64 = self.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        
        return base64
    }
    
}

