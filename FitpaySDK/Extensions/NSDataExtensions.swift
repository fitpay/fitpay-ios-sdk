
import Foundation

extension Data
{
    var UTF8String:String?
    {
        return self.stringWithEncoding(String.Encoding.utf8)
    }

    @inline(__always) func stringWithEncoding(_ encoding:String.Encoding) -> String?
    {
        return String(data: self, encoding: encoding)
    }

    var dictionary:Dictionary<String, AnyObject>?
    {
        guard let dictionary:[String : AnyObject] = try? JSONSerialization.jsonObject(with: self, options:.mutableContainers) as! [String : AnyObject] else
        {
            return nil
        }

        return dictionary
    }

    var errorMessages:[String]?
    {
        var messages:[String]?
        if let dict:[String : AnyObject] = self.dictionary
        {
            if let errors = dict["errors"] as? [[String : String]]
            {
                messages = []
                for error in errors
                {
                    if let message = error["message"]
                    {
                        messages!.append(message)
                    }
                }
            }
        }
        return messages
    }
    
    var errorMessage:String?
    {
        if let dict = self.dictionary
        {
            if let messageDict = dict as? [String : String]
            {
                if let message = messageDict["message"]
                {
                    return message
                }
            }
        }
        
        return nil
    }
    
    var SHA1:String?
    {
        return String(data: CC.digest(self, alg: .sha1), encoding: String.Encoding.utf8)
    }
    
    var hex:String
    {
        var s = ""
        
        var byte: UInt8 = 0
        for i in 0 ..< self.count {
            (self as NSData).getBytes(&byte, range: NSMakeRange(i, 1))
            s += String(format: "%02x", byte)
        }
        
        return s
    }
    
    var reverseEndian:Data {
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
}

extension Data {
    func subdata(in range: ClosedRange<Index>) -> Data {
        return subdata(in: range.lowerBound ..< range.upperBound + 1)
    }
}

