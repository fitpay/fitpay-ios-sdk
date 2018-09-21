import Foundation

open class Payload: NSObject, Serializable {
    
    open var creditCard: CreditCard?
    
    var payloadDictionary: [String: Any]?
    var apduPackage: ApduPackage?
    
    private enum CodingKeys: String, CodingKey {
        case creditCardId
        case packageId
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apduPackage = try? ApduPackage(from: decoder)
        creditCard = try? CreditCard(from: decoder)
        
        self.payloadDictionary = try? container.decode([String: Any].self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(creditCard, forKey: .creditCardId)
        try? container.encode(apduPackage, forKey: .packageId)
    }
}
