import Foundation

/// Credit card info
@objc open class CardInfo: NSObject, Serializable {
    
    /// The credit card number, also known as a Primary Account Number (PAN)
    @objc open var pan: String?
    
    /// The credit card expiration month
    open var expMonth: Int?
    
    /// The credit card expiration year in 4 digits
    open var expYear: Int?
    
    /// The credit card cvv2 code
    @objc open var cvv: String?
    
    /// Card holder name
    @objc open var name: String?
    
    /// Credit card language. Should use the format [language designator ISO-639-1]‌
    @objc open var language: String?
    
    /// Card holder billing address
    @objc open var address: Address?
    
    /// Card holder risk data
    @objc open var riskData: IdVerification?
    
    /// Initialize class with all variables
    public init(pan: String?, expMonth: Int?, expYear: Int?, cvv: String?, name: String?, language: String? = nil, address: Address?, riskData: IdVerification?) {
        super.init()
        
        self.pan = pan
        self.expMonth = expMonth
        self.expYear = expYear
        self.cvv = cvv
        self.name = name
        self.language = language
        self.address = address
        self.riskData = riskData
    }
    
}
