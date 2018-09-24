import Foundation

public class StreamEvent: Decodable {
    public var type: StreamEventType
    public var payload: [String: Any]?

    public required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(StreamEventType.self, forKey: .type)
        payload = try? container.decode([String: Any].self, forKey: .payload)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case payload
    }
    
}

public enum StreamEventType: String, Decodable {
    case connected = "STREAM_CONNECTED"
    case disconnected = "STREAM_DISCONNECTED"
    case heartbeat = "STREAM_HEARTBEAT"
    case sync = "SYNC"
}
