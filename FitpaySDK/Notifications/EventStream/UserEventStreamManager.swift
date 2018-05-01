import Foundation

public class UserEventStreamManager {
    public static let sharedInstance = UserEventStreamManager()
    
    private var client: RestClient?
    private var userEventStream: UserEventStream?
    
    public typealias userEventStreamHandler = (_ event: StreamEvent) -> Void
    
    public func subscribe(userId: String, sessionData: SessionData, config: FitpaySDKConfiguration, completion: @escaping userEventStreamHandler) {
        let session = RestSession(configuration: config, sessionData: sessionData)
        client = RestClient(session: session)

        client!.user(id: userId) { (user, error) in
            guard let user = user else { return }
            
            self.userEventStream = UserEventStream(user: user, client: self.client!, completion: completion)
        }
    }
}
