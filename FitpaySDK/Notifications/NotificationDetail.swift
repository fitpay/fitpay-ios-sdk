import ObjectMapper

open class NotificationDetail: Mappable {
    open var ackSync: String?
    open var completeSync: String?
    open var type: String?
    open var syncId: String?
    open var deviceId: String?
    open var userId: String?
    open var clientId: String?
    var restClient: RestClient?

    public required init?(map: Map) {
    }
    
    open func mapping(map: Map) {
        ackSync <- map["_links.ackSync.href"]
        completeSync <- map["_links.completeSync.href"]
        type <- map["type"]
        syncId <- map["id"]
        deviceId <- map["deviceId"]
        userId <- map["userId"]
        clientId <- map["clientId"]
    }
    
    open func sendAckSync() {
        guard let ackSync = self.ackSync else {
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

