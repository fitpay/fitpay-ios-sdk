import Foundation

open class RtmMessageResponse: RtmMessage {

    var success: Bool?
    
    public required init(callbackId: Int? = nil, data: [String: Any]? = nil, type: String, success: Bool = true) {
        super.init()
        
        self.callBackId = callbackId
        self.data = data
        self.type = type
        self.success = success
    }

    private enum CodingKeys: String, CodingKey {
        case success = "isSuccess"
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try? container.decode(.success)
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(success, forKey: .success)
    }
}
