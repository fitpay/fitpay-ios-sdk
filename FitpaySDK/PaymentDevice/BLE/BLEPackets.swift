import CoreBluetooth

struct Continuation {
    var uuid: CBUUID
    var dataParts: [Int: Data]
    
    init()  {
        uuid = CBUUID()
        dataParts =  [Int: Data]()
    }
    
    init(uuidValue: CBUUID) {
        uuid = uuidValue
        dataParts =  [Int: Data]()
    }
    
    var data: Data? {
        let dataFromParts = NSMutableData()
        var expectedKey = 0
        for (key, value) in dataParts {
            if (key != expectedKey) {
                return nil
            }
            
            expectedKey += 1
            
            dataFromParts.append(value)
        }
        return dataFromParts as Data
    }
}

struct ContinuationPacketMessage {
    let sortOrder: UInt16
    let data: Data
    
    init(msg: Data) {
        let sortOrderRange : NSRange = NSMakeRange(0, 2)
        var buffer = [UInt8](repeating: 0x00, count: 2)
        (msg as NSData).getBytes(&buffer, range: sortOrderRange)
        
        let sortOrderData = Data(bytes: UnsafePointer<UInt8>(buffer), count: 2)
        var u16: UInt16 = 0
        (sortOrderData as NSData).getBytes(&u16, length: 2)
        sortOrder = UInt16(littleEndian: u16)
        
        let range : NSRange = NSMakeRange(2, msg.count - 2)
        buffer = [UInt8](repeating: 0x00, count: (msg.count) - 2)
        (msg as NSData).getBytes(&buffer, range: range)
        
        data = Data(bytes: UnsafePointer<UInt8>(buffer), count: (msg.count) - 2)
    }
}

struct ContinuationControlMessage {
    let type: UInt8
    let isBeginning: Bool
    let isEnd: Bool
    let data: Data
    let uuid: CBUUID
    let crc32: UInt32
    
    init(withUuid: CBUUID) {
        type = 0
        isBeginning = true
        isEnd = false
        uuid = withUuid
        data = Data()
        crc32 = UInt32()
    }
    
    init(msg: Data) {
        var buffer = [UInt8](repeating: 0x00, count: (msg.count))
        (msg as NSData).getBytes(&buffer, length: buffer.count)
        
        type = buffer[0]
        if (buffer[0] == 0x00) {
            isBeginning = true
            isEnd = false
        } else {
            isBeginning = false
            isEnd = true
        }
        
        let range = NSMakeRange(1, msg.count - 1)
        buffer = [UInt8](repeating: 0x00, count: (msg.count) - 1)
        (msg as NSData).getBytes(&buffer, range: range)
        
        data = Data(bytes: UnsafePointer<UInt8>(buffer), count: (msg.count) - 1)
        if (data.count == 16) {
            //reverse bytes for little endian representation
            var inData = [UInt8](repeating: 0, count: data.count)
            (data as NSData).getBytes(&inData, length: data.count)
            var outData = [UInt8](repeating: 0, count: data.count)
            var outPos = inData.count
            
            for i in 0 ..< inData.count {
                outPos -= 1
                outData[i] = inData[outPos]
            }
            let out = Data(bytes: UnsafePointer<UInt8>(outData), count: outData.count)
            uuid = CBUUID(data: out)
            crc32 = UInt32()
        } else if (data.count == 4) {
            uuid = CBUUID()
            var u32 : UInt32 = 0
            (data as NSData).getBytes(&u32, length: 4)
            crc32 = UInt32(littleEndian: u32)
        } else {
            uuid = CBUUID()
            crc32 = UInt32()
        }
    }
}


struct ApplicationControlMessage {
    let msg: Data
    let deviceAction: UInt8
    let ATRHex: String
    
    init(msg: Data) {
        self.msg = msg
        var buffer = [UInt8](repeating: 0x00, count: (msg.count))
        (msg as NSData).getBytes(&buffer, length: buffer.count)
        
        deviceAction = UInt8(buffer[0])
        
        if msg.count > 1 {
            let range: NSRange = NSMakeRange(1, msg.count - 1)
            buffer = [UInt8](repeating: 0x00, count: msg.count - 1)
            (msg as NSData).getBytes(&buffer, range: range)
            ATRHex = String(data:Data(bytes: UnsafePointer<UInt8>(buffer), count: 2), encoding: String.Encoding.utf8)!
        } else {
            ATRHex = ""
        }
    }
}
