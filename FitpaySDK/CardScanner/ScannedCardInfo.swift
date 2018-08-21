import Foundation

/// Object returned from FitpayCardScannerDelegate scanned
@objc public class ScannedCardInfo: NSObject, Serializable {
    
    /// Credit card number
    @objc public var cardNumber: String?
    
    /// Expiration month between 1-12
    public var expiryMonth: UInt?
    
    /// 4 digit Expiration year
    public var expiryYear: UInt?
    
    /// 3-4 digit CVV
    @objc public var cvv: String?
    
}
