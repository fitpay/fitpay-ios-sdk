import UIKit

open class RtmMessage: NSObject, Serializable {
    
    open var callBackId: Int?
    open var data: [String: Any]?
    open var type: String?
    
    override init() {
        super.init()
    }

    private enum CodingKeys: String, CodingKey {
        case callBackId
        case data
        case type
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        callBackId = try? container.decode(.callBackId)
        data = try? container.decode([String: Any].self, forKey: .data)
        type = try? container.decode(.type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let callBackId = callBackId {
            try? container.encode(callBackId, forKey: .callBackId)
        }
        if let data = data {
            try? container.encode(data, forKey: .data)
        }
        if let type = type {
            try? container.encode(type, forKey: .type)
        }
    }
}

