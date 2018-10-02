import Foundation

// TODO: Document well
/// don't store / must have agreement to display outside of fitpay webview
open class Transaction: NSObject, ClientModel, Serializable {
    
    open var transactionId: String?
    open var transactionType: String?
    open var amount: NSDecimalNumber?
    open var currencyCode: String?
    open var authorizationStatus: String?
    open var transactionTime: String?
    open var transactionTimeEpoch: TimeInterval?
    open var merchantName: String?
    open var merchantCode: String?
    open var merchantType: String?
    
    weak var client: RestClient?
    
    var links: [ResourceLink]?
    
    private static let selfResourceKey = "self"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case transactionId
        case transactionType
        case amount
        case currencyCode
        case authorizationStatus
        case transactionTime
        case transactionTimeEpoch
        case merchantName
        case merchantCode
        case merchantType
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        transactionId = try? container.decode(.transactionId)
        transactionType = try? container.decode(.transactionType)
        if let stringNumber: String = try? container.decode(.amount) {
            amount = DecimalNumberTypeTransform().transform(stringNumber)
        } else if let intNumber: Double = try? container.decode(.amount) {
            amount = DecimalNumberTypeTransform().transform(intNumber)
        }
        currencyCode = try? container.decode(.currencyCode)
        authorizationStatus = try? container.decode(.authorizationStatus)
        transactionTime = try? container.decode(.transactionTime)
        transactionTimeEpoch = try container.decode(.transactionTimeEpoch, transformer: NSTimeIntervalTypeTransform())
        merchantName = try? container.decode(.merchantName)
        merchantCode = try? container.decode(.merchantCode)
        merchantType = try? container.decode(.merchantType)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(transactionId, forKey: .transactionId)
        try? container.encode(transactionType, forKey: .transactionType)
        try? container.encode(amount?.description, forKey: .amount)
        try? container.encode(currencyCode, forKey: .currencyCode)
        try? container.encode(authorizationStatus, forKey: .authorizationStatus)
        try? container.encode(transactionTime, forKey: .transactionTime)
        try? container.encode(transactionTimeEpoch, forKey: .transactionTimeEpoch, transformer: NSTimeIntervalTypeTransform())
        try? container.encode(merchantName, forKey: .merchantName)
        try? container.encode(merchantCode, forKey: .merchantCode)
        try? container.encode(merchantType, forKey: .merchantType)
    }
}
