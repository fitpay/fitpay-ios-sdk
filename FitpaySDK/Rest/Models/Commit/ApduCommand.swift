import Foundation

open class APDUCommand: NSObject, Serializable, APDUResponseProtocol {
    
    open var commandId: String?
    open var groupId: Int = 0
    open var sequence: Int = 0
    open var command: String?
    open var type: String?
    open var continueOnFailure: Bool = false
    
    open var responseData: Data?
    
    private enum CodingKeys: String, CodingKey {
        case commandId
        case groupId
        case sequence
        case command
        case type
        case continueOnFailure 
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        commandId = try? container.decode(.commandId)
        groupId = try container.decodeIfPresent(Int.self, forKey: .groupId) ?? 0
        sequence = try container.decodeIfPresent(Int.self, forKey: .sequence) ?? 0
        command = try? container.decode(.command)
        type = try? container.decode(.type)
        continueOnFailure = try container.decodeIfPresent(Bool.self, forKey: .continueOnFailure) ?? false
    }

    open var responseDictionary: [String: Any] {
        get {
            var dic: [String: Any] = [:]
            
            if let commandId = commandId {
                dic["commandId"] = commandId
            }
            
            if let responseCode = responseCode {
                dic["responseCode"] = responseCode.hex
            }
            
            if let responseData = responseData {
                dic["responseData"] = responseData.hex
            }
            
            return dic
        }
    }
}
