import Foundation

import Alamofire

/// Notification model parsed from push notification
///
/// Equivalent to SyncInfo in Android
// TODO: Replace with EventModel for SDK 2.x
open class NotificationDetail: Serializable, ClientModel {
    
    open var type: String?
    open var syncId: String?
    open var deviceId: String?
    open var userId: String?
    open var clientId: String?
    open var creditCardId: String?
    
    weak public var client: RestClient?
    
    var links: [String: Link]?

    private static let creditCardResourceKey = "creditCard"
    private static let deviceResourceKey = "device"
    private static let ackSyncResourceKey = "ackSync"
    private static let completeSyncResourceKey = "completeSync"

    private enum CodingKeys: String, CodingKey {
        case links = "_links"
        case type
        case id
        case syncId
        case deviceId
        case userId
        case clientId
        case creditCardId
    }
    
    // MARK: - Lifecycle
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links = try? container.decode(.links)
        type = try? container.decode(.type)
        
        syncId = try? container.decode(.syncId)
        if syncId == nil { // for old notifications syncId comes through as id
            syncId = try? container.decode(.id)
        }
        
        deviceId = try? container.decode(.deviceId)
        userId = try? container.decode(.userId)
        clientId = try? container.decode(.clientId)
        creditCardId = try? container.decode(.creditCardId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try? container.encodeIfPresent(links, forKey: .links)
        try? container.encode(type, forKey: .type)
        try? container.encode(syncId, forKey: .syncId)
        try? container.encode(deviceId, forKey: .deviceId)
        try? container.encode(userId, forKey: .userId)
        try? container.encode(clientId, forKey: .clientId)
        try? container.encode(creditCardId, forKey: .creditCardId)
    }
    
    // MARK: - Public Functions

    open func sendAckSync(completion: RestClient.ConfirmHandler? = nil) {
        let resource = NotificationDetail.ackSyncResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion?(composeError(resource))
            return
        }
        
        client.acknowledge(url) { error in
            if let error = error {
                log.error("SYNC_ACKNOWLEDGMENT: ackSync failed to send. Error: \(error)")
                
            } else if let syncId = self.syncId {
                log.debug("SYNC_ACKNOWLEDGMENT: ackSync has been sent successfully. syncId: \(syncId)")
            }
            completion?(error)
        }
    }
    
    open func sendCompleteSync(commitMetrics: CommitMetrics, completion: RestClient.ConfirmHandler? = nil) {
        let resource = NotificationDetail.completeSyncResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion?(composeError(resource))
            return
        }
        
        let params: [String: Any]? = commitMetrics.toJSON() != nil ? ["params": commitMetrics.toJSON()!] : nil
        client.makePostCall(url, parameters: params) { (error) in
            if let error = error {
                log.error("SYNC_ACKNOWLEDGMENT: completeSync failed to send. Error: \(error)")
                
            } else if let syncId = self.syncId {
                log.debug("SYNC_ACKNOWLEDGMENT: completeSync has been sent successfully. \(syncId)")
            }
            completion?(error)
        }
    }
    
    open func getCreditCard(completion: @escaping RestClient.CreditCardHandler) {
        let resource = NotificationDetail.creditCardResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }

        client.getCreditCard(url, completion: completion)
    }
    
    open func getDevice(completion: @escaping RestClient.DeviceHandler) {
        let resource = NotificationDetail.deviceResourceKey
        
        guard let url = links?[resource]?.href, let client = client else {
            completion(nil, composeError(resource))
            return
        }
        
        client.getDevice(url, completion: completion)
    }
    
    // MARK: - Private Functions
    
    private func composeError(_ resource: String) -> ErrorResponse? {
        log.error("SYNC: issue with \(resource) link: \(String(describing: links?[resource]?.href)) client: \(String(describing: client))")
        return ErrorResponse.clientUrlError(domain: User.self, client: client, url: links?[resource]?.href, resource: resource)
    }

}
