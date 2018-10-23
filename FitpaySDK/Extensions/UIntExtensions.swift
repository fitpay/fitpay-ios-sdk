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
        return [UInt8(truncatingIfNeeded: self), UInt8(truncatingIfNeeded: self >> 8)]
    }
}
