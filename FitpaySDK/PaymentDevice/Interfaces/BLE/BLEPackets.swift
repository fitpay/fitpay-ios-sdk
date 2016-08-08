import CoreBluetooth

struct Continuation {
    var uuid : CBUUID
    var dataParts : [Int:NSData]
    init()  {
        uuid = CBUUID()
        dataParts =  [Int:NSData]()
    }
    init(uuidValue: CBUUID) {
        uuid = uuidValue
        dataParts =  [Int:NSData]()
    }
    
    var data : NSData? {
        let dataFromParts = NSMutableData()
        var expectedKey = 0
        for (key, value) in dataParts {
            if (key != expectedKey) {
                return nil
            }
            
            expectedKey += 1
            
            dataFromParts.appendData(value)
        }
        return dataFromParts
    }
}

struct ContinuationPacketMessage {
    let sortOrder: UInt16
    let data: NSData
    init(msg: NSData) {
        let sortOrderRange : NSRange = NSMakeRange(0, 2)
        var buffer = [UInt8](count: 2, repeatedValue: 0x00)
        msg.getBytes(&buffer, range: sortOrderRange)
        
        let sortOrderData = NSData(bytes: buffer, length: 2)
        var u16 : UInt16 = 0
        sortOrderData.getBytes(&u16, length: 2)
        sortOrder = UInt16(littleEndian: u16)
        
        let range : NSRange = NSMakeRange(2, msg.length - 2)
        buffer = [UInt8](count: (msg.length) - 2, repeatedValue: 0x00)
        msg.getBytes(&buffer, range: range)
        
        data = NSData(bytes: buffer, length: (msg.length) - 2)
    }
}

struct ContinuationControlMessage {
    let type: UInt8
    let isBeginning: Bool
    let isEnd: Bool
    let data: NSData
    let uuid: CBUUID
    let crc32: UInt32
    init(withUuid: CBUUID) {
        type = 0
        isBeginning = true
        isEnd = false
        uuid = withUuid
        data = NSData()
        crc32 = UInt32()
    }
    init(msg: NSData) {
        var buffer = [UInt8](count: (msg.length), repeatedValue: 0x00)
        msg.getBytes(&buffer, length: buffer.count)
        
        type = buffer[0]
        if (buffer[0] == 0x00) {
            isBeginning = true
            isEnd = false
        } else {
            isBeginning = false
            isEnd = true
        }
        
        let range : NSRange = NSMakeRange(1, msg.length - 1)
        buffer = [UInt8](count: (msg.length) - 1, repeatedValue: 0x00)
        msg.getBytes(&buffer, range: range)
        
        data = NSData(bytes: buffer, length: (msg.length) - 1)
        if (data.length == 16) {
            //reverse bytes for little endian representation
            var inData = [UInt8](count: data.length, repeatedValue: 0)
            data.getBytes(&inData, length: data.length)
            var outData = [UInt8](count: data.length, repeatedValue: 0)
            var outPos = inData.count;
            for i in 0 ..< inData.count {
                outPos -= 1
                outData[i] = inData[outPos]
            }
            let out = NSData(bytes: outData, length: outData.count)
            uuid = CBUUID(data: out)
            crc32 = UInt32()
        } else if (data.length == 4) {
            uuid = CBUUID()
            var u32 : UInt32 = 0
            data.getBytes(&u32, length: 4)
            crc32 = UInt32(littleEndian: u32)
        } else {
            uuid = CBUUID()
            crc32 = UInt32()
        }
    }
}


public struct ApplicationControlMessage {
    let msg : NSData
    let deviceAction : UInt8
    let ATRHex : String
    init(msg: NSData) {
        self.msg = msg
        var buffer = [UInt8](count: (msg.length), repeatedValue: 0x00)
        msg.getBytes(&buffer, length: buffer.count)
        
        deviceAction = UInt8(buffer[0])
        
        if msg.length > 1 {
            let range : NSRange = NSMakeRange(1, msg.length-1)
            buffer = [UInt8](count: msg.length-1, repeatedValue: 0x00)
            msg.getBytes(&buffer, range: range)
            ATRHex = String(data:NSData(bytes: buffer, length: 2), encoding: NSUTF8StringEncoding)!
        } else {
            ATRHex = ""
        }
    }
}

struct DeviceControlMessage {
    let op : UInt8
    let msg : NSMutableData
    
    init(operation: DeviceControlState) {
        op = UInt8(operation.rawValue)
        msg = NSMutableData()
        var op8 = op
        msg.appendBytes(&op8, length: sizeofValue(op))
    }
}

struct SecurityStateMessage {
    let nfcState: UInt8
    let nfcErrorCode: UInt8
    init(msg: NSData) {
        if (msg.length == 0) {
            nfcState = 0x00
            nfcErrorCode = 0x00
            return
        }
        
        var buffer = [UInt8](count: (msg.length), repeatedValue: 0x00)
        msg.getBytes(&buffer, length: buffer.count)
        
        nfcState = buffer[0]

        if (buffer.count > 1) {
            nfcErrorCode = buffer[1]
        } else {
            nfcErrorCode = 0x00
        }
    }
}
