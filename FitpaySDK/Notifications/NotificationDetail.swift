
open class NotificationDetail: Serializable {
    
    open var type: String?
    open var syncId: String?
    open var deviceId: String?
    open var userId: String?
    open var clientId: String?
    
    var restClient: RestClientInterface?
    var links: [ResourceLink]?

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case type
        case syncId = "id"
        case deviceId
        case userId
        case clientId
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try container.decode(.links, transformer: ResourceLinkTypeTransform())
        type = try? container.decode(.type)
        syncId = try? container.decode(.syncId)
        deviceId = try? container.decode(.deviceId)
        userId = try? container.decode(.userId)
        clientId = try? container.decode(.clientId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encode(links, forKey: .links, transformer: ResourceLinkTypeTransform())
        try? container.encode(type, forKey: .type)
        try? container.encode(syncId, forKey: .syncId)
        try? container.encode(deviceId, forKey: .deviceId)
        try? container.encode(userId, forKey: .userId)
        try? container.encode(clientId, forKey: .clientId)
    }

    
    open func sendAckSync() {
        guard let ackSync = self.links?.url("ackSync") else {
            log.error("SYNC_ACKNOWLEDGMENT: trying to send ackSync without URL.")
            return
        }

        guard let client = self.restClient else {
            log.error("SYNC_ACKNOWLEDGMENT: trying to send ackSync without rest client.")
            return
        }

        client.makePostCall(ackSync, parameters:nil) { (error) in
            if let error = error {
                log.error("SYNC_ACKNOWLEDGMENT: ackSync failed to send. Error: \(error)")
            } else {
                log.debug("SYNC_ACKNOWLEDGMENT: ackSync has been sent successfully.")
            }
        }
    }
}

