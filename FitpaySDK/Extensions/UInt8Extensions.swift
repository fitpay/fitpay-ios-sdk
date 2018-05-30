import Foundation

extension UInt8 {
    var data: Data {
        return Data(bytes: [self])
    }
}
