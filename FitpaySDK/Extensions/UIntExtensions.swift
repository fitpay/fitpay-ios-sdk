import Foundation

extension UInt8 {
    var data: Data {
        return Data(bytes: [self])
    }
}

extension UInt16 {
    var data: Data {
        return Data(bytes: self.twoBytes)
    }
    
    private var twoBytes: [UInt8] {
        let unsignedSelf = UInt16(bitPattern: Int16(self))
        return [UInt8(truncatingIfNeeded: unsignedSelf), UInt8(truncatingIfNeeded: unsignedSelf >> 8)]
    }
}
