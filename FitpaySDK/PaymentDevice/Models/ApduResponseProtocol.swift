import Foundation

public enum APDUResponseType: Int {
    case success = 0x0
    case concatenation
    case warning
    case error
    
    init(withCode code: [UInt8]) {
        guard code.count == 2 else {
            self = .error
            return
        }
        
        if code[0] == APDUResponseType.concatenationResponse {
            self = .concatenation
            return
        }
        
        for successCode in APDUResponseType.successResponses {
            if code[0] != successCode[0] {
                continue
            }
            
            if successCode.count == 1 {
                self = .success
                return
            }
            
            if code.count > 1 && successCode.count > 1 {
                if code[1] == successCode[1] {
                    self = .success
                    return
                }
            }
        }
        
        for warningCode in APDUResponseType.warningResponses {
            if code[0] != warningCode[0] {
                continue
            }
            
            if warningCode.count == 1 {
                self = .warning
                return
            }
            
            if code.count > 1 && warningCode.count > 1 {
                if code[1] == warningCode[1] {
                    self = .warning
                    return
                }
            }
        }
        
        self = APDUResponseType.error
    }
    
    static let successResponses : [[UInt8]] = [
        [0x90, 0x00],
    ]
    
    static let warningResponses : [[UInt8]] = [
        [0x62/*, XX */],
        [0x63/*, XX */],
    ]
    
    static let concatenationResponse: UInt8 = 0x61
}


public protocol APDUResponseProtocol {
    var responseData: Data? { get set }
    var responseCode: Data? { get }
    var responseType: APDUResponseType? { get }
}

extension APDUResponseProtocol {
    public var responseType: APDUResponseType? {
        guard let responseCode = self.responseCode else {
            return nil
        }
        
        return APDUResponseType(withCode: responseCode.bytesArray)
    }
    
    public var responseCode: Data? {
        guard let responseData = self.responseData, responseData.count >= 2 else {
            return nil
        }
        
        return responseData.subdata(in: responseData.count - 2..<responseData.count)
    }
}
