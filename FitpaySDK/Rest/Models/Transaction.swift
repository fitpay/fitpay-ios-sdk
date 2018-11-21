import Foundation

// TODO: Document well
/// Transactions - These can not be stored
open class Transaction: NSObject, ClientModel, Serializable, SecretApplyable {

    open var transactionId: String?
    open var transactionType: String?
    open var amount: NSDecimalNumber? // TODO: update to Decimal or String with V2
    open var currencyCode: String?
    open var authorizationStatus: String?
    open var transactionTime: String?
    open var transactionTimeEpoch: TimeInterval?
    open var merchantName: String?
    open var merchantCode: String?
    open var merchantType: String?
    
    var encryptedData: String?

    weak var client: RestClient?
    
    private enum CodingKeys: String, CodingKey {
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
        case encryptedData
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        transactionId = try? container.decode(.transactionId)
        transactionType = try? container.decode(.transactionType)
        
        if let stringNumber: String = try? container.decode(.amount), let doubleNumber = Double(stringNumber) {
            amount = NSDecimalNumber(value: doubleNumber)
        } else if let doubleNumber: Double = try? container.decode(.amount) {
            amount = NSDecimalNumber(value: doubleNumber)
        }
        
        currencyCode = try? container.decode(.currencyCode)
        authorizationStatus = try? container.decode(.authorizationStatus)
        transactionTime = try? container.decode(.transactionTime)
        transactionTimeEpoch = try container.decode(.transactionTimeEpoch, transformer: NSTimeIntervalTypeTransform())
        merchantName = try? container.decode(.merchantName)
        merchantCode = try? container.decode(.merchantCode)
        merchantType = try? container.decode(.merchantType)
        encryptedData = try? container.decode(.encryptedData)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
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
        try? container.encode(encryptedData, forKey: .encryptedData)
    }
    
    // MARK: - Internal Functions
    
    func applySecret(_ secret: Data, expectedKeyId: String?) {
        guard let tmpTransaction: Transaction = JWE.decrypt(encryptedData, expectedKeyId: expectedKeyId, secret: secret) else { return }

        transactionId = tmpTransaction.transactionId
        transactionType = tmpTransaction.transactionType
        amount = tmpTransaction.amount
        currencyCode = tmpTransaction.currencyCode
        authorizationStatus = tmpTransaction.authorizationStatus
        transactionTime = tmpTransaction.transactionTime
        transactionTimeEpoch = tmpTransaction.transactionTimeEpoch
        merchantName = tmpTransaction.merchantName
        merchantCode = tmpTransaction.merchantCode
        merchantType = tmpTransaction.merchantType
    }
    
}
