import Foundation

open class ApduResultMessage: NSObject, APDUResponseProtocol {
    open var responseData: Data?

    public init(hexResult: String) {
        responseData = hexResult.hexToData() 
    }
    
    public init(responseData: Data) {
        self.responseData = responseData
    }

    var concatenationAPDUPayload: Data? {
        guard self.responseType == .concatenation, let responseCodeDataType = responseCode else { return nil }
        
        let concatenationSize = responseCodeDataType.bytesArray[1]
        return Data(bytes: [0x00, 0xc0, 0x00, 0x00, concatenationSize])
    }
}
