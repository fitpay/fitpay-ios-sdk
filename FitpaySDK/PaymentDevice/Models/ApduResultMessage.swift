//
//  ApduResultMessage.swift
//  FitpaySDK
//
//  Created by Carol Bloch on 5/19/16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

open class ApduResultMessage : NSObject, APDUResponseProtocol {
    open var responseData: Data?

    public init(hexResult: String) {
        responseData = hexResult.hexToData() 
    }
    
    override init() {
        super.init()
    }
    
    var concatenationAPDUPayload: Data? {
        guard self.responseType == .concatenation, let responseCodeDataType = responseCode else {
            return nil
        }
        
        let concatenationSize = responseCodeDataType.bytesArray[1]
        return Data(bytes: [0x00, 0xc0, 0x00, 0x00, concatenationSize])
    }
}

class BLEApduResultMessage: ApduResultMessage {
    var msg: Data
    var resultCode: UInt8
    var sequenceId: UInt16
    var responseCode: Data?
    
    public init(hexResult: String, sequenceId: String) {
        self.msg = hexResult.hexToData()! as Data
        self.sequenceId = UInt16(sequenceId)!
        self.resultCode = UInt8(00)
        
        super.init()

        let range : NSRange = NSMakeRange(msg.count - 2, 2)
        var buffer = [UInt8](repeating: 0x00, count: 2)
        (msg as NSData).getBytes(&buffer, range: range)
        
        responseCode = Data(bytes: UnsafePointer<UInt8>(buffer), count: 2)
        responseData = self.msg
        print("responseCode \(responseCode ?? Data())")
    }
    
    public init(msg: Data) {
        self.msg = msg
        var buffer = [UInt8](repeating: 0x00, count: (msg.count))
        (msg as NSData).getBytes(&buffer, length: buffer.count)
        
        self.resultCode = UInt8(buffer[0])

        var recvSeqId:UInt16?
        recvSeqId = UInt16(buffer[2]) << 8
        recvSeqId = recvSeqId! | UInt16(buffer[1])
        self.sequenceId = recvSeqId!
        
        super.init()

        var range : NSRange = NSMakeRange(msg.count - 2, 2)
        buffer = [UInt8](repeating: 0x00, count: 2)
        (msg as NSData).getBytes(&buffer, range: range)
        self.responseCode = Data(bytes: UnsafePointer<UInt8>(buffer), count: 2)
        
        range = NSMakeRange(1, msg.count - 2)
        buffer = [UInt8](repeating: 0x00, count: msg.count - 2)
        (msg as NSData).getBytes(&buffer, range: range)
        self.responseData = Data(bytes: UnsafePointer<UInt8>(buffer), count:  msg.count - 2)
    }

}
