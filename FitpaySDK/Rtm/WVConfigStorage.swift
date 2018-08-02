import Foundation

struct WvConfigStorage {
    var paymentDevice: PaymentDevice?
    var user: User?
    var device: Device?
    var a2aReturnLocation: String?
    var rtmConfig: RtmConfigProtocol?
}
