import Foundation

struct WvConfigStorage {
    private let defaults = UserDefaults.standard

    var paymentDevice: PaymentDevice?
    var user: User?
    var device: Device?
    var rtmConfig: RtmConfigProtocol?
    
    var a2aReturnLocation: String? {
        get {
            return defaults.string(forKey: "a2aReturnLocation")
        }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: "a2aReturnLocation")
            } else {
                defaults.removeObject(forKey: "a2aReturnLocation")
            }
        }
    }
}
