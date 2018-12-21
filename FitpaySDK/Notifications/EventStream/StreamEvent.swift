import Foundation

// TODO: Replace with EventModel for SDK 2.x
public class StreamEvent: Decodable {
    public var type: StreamEventType?
    public var payload: [String: Any]?

    public required init(from decoder: Decoder) throws {
        let container =  try decoder.container(keyedBy: CodingKeys.self)
        
        type = try? container.decode(.type)
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
    case cardCreated = "CREDITCARD_CREATED"
    case cardActivated = "CREDITCARD_ACTIVATED"
    case cardDeactivated = "CREDITCARD_DEACTIVATED"
    case cardReactivated = "CREDITCARD_REACTIVATED"
    case cardPendingVerfication = "CREDITCARD_PENDING_VERIFICATION"
    case cardDeleted = "CREDITCARD_DELETED"
    case setDefaultCard = "SET_DEFAULT_CREDITCARD"
    case resetDefaultCard = "RESET_DEFAULT_CREDITCARD"
    case userCreated = "USER_CREATED"
    case userDeleted = "USER_DELETED"
    case APDUPackage = "APDU_PACKAGE"
    case APDUResponse = "APDU_RESPONSE"
    case cardProvisionFailed = "CREDITCARD_PROVISION_FAILED"
    case cardProvisionSuccess = "CREDITCARD_PROVISION_SUCCESS"
    case cardMetadataUpdated = "CREDITCARD_METADATA_UPDATED"
    case deviceCreated = "DEVICE_CREATED"
    case deviceStateUpdated = "DEVICE_STATE_UPDATED"
    case deviceDeleted = "DEVICE_DELETED"
    case transferUpdate = "TRANSFER_UPDATE"
    case seOperationUpdate = "SE_OPERATION_UPDATE"
    case resetDefaultCredential = "RESET_DEFAULT_CREDENTIAL"
    case credentialDeactivated = "CREDENTIAL_DEACTIVATED"
    case credentialReactivated = "CREDENTIAL_REACTIVATED"
}
