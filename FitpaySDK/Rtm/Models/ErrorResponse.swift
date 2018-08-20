import Foundation

/// Error model for Session, Client and Web errors
@objc public class ErrorResponse: NSError, Serializable {
    
    /// HTTP Status Code
    public let status: Int?
    
    /// Created Timestamp when run
    public let created: TimeInterval?
    
    @objc public let requestId: String?
    
    /// URL relative path
    @objc public let path: String?
    
    /// Short summary of error. ie: \"Not Found\"
    @objc public let summary: String?
    
    /// Longer summary of error
    @objc public let messageDescription: String?
    
    /// Specific issue
    // Parsed from different locations in the object
    @objc public let message: String?
    
    /// Specific issue
    // Parsed from different locations in the object
    @objc public let details: String?

    enum CodingKeys: String, CodingKey {
        case status
        case created
        case requestId
        case path
        case summary
        case messageDescription = "description"
        case details
        case message
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        status = try? container.decode(.status)
        created = try container.decode(.created, transformer: NSTimeIntervalTypeTransform())
        requestId = try? container.decode(.requestId)
        path = try? container.decode(.path)
        summary = try? container.decode(.summary)
        messageDescription = try? container.decode(.messageDescription)

        if let detailsString: String = try? container.decode(.details), let data = detailsString.data(using: .utf8) {
            if let dict: [String: Any] = (try? JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])?.first {
                details = dict["message"] as? String
            } else {
                details = detailsString
            }
        } else {
            details = nil
        }

        if let messageString: String = try? container.decode(.message), let data = messageString.data(using: .utf8) {
            if let dict: [String: Any] = (try? JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])?.first {
                message = dict["message"] as? String
            } else {
                message = messageString
            }
        } else {
            message = nil
        }
        
        super.init(domain: "", code: status ?? 0, userInfo: [NSLocalizedDescriptionKey: messageDescription ?? ""])
        
        logError()
    }

    init(domain: AnyClass, errorCode: Int?, errorMessage: String?) {
        status = errorCode
        created = nil
        requestId = nil
        path = nil
        summary = nil
        messageDescription = errorMessage
        details = nil
        message = nil
        super.init(domain: "\(domain)", code: status ?? 0, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
        
        logError()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Static Methods

    class func unhandledError(domain: AnyClass) -> ErrorResponse {
        return ErrorResponse(domain: domain, errorCode: 0, errorMessage: "Unhandled error")
    }

    class func clientUrlError(domain: AnyClass, client: RestClient?, url: String?, resource: String) -> ErrorResponse? {
        if client == nil {
            return ErrorResponse(domain: domain, errorCode: 0, errorMessage: "\(RestClient.self) is not set.")
        }
        if url == nil {
            return ErrorResponse(domain: domain, errorCode: 0, errorMessage: "Failed to retrieve url for resource '\(resource)'")
        }
        
        return nil
    }

    // MARK: - Private
    
    private func logError() {
        let status = "\(self.status ?? 0)"
        let messageDescription = "\(self.messageDescription ?? "")"
        log.error("Error. Status: \(status) Message: \(messageDescription).")
    }

}
