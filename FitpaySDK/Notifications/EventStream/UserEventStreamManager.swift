import Foundation

public class UserEventStreamManager {
    public static let sharedInstance = UserEventStreamManager()
    
    private var client: RestClient?
    private var userEventStream: UserEventStream?
    
    public typealias userEventStreamHandler = (_ event: StreamEvent) -> Void
    
    public func subscribe(userId: String, sessionData: SessionData, completion: @escaping userEventStreamHandler) {
        let session = RestSession(sessionData: sessionData)
        client = RestClient(session: session)
        
        client!.getPlatformConfig { (platformConfig, _) in
            guard let isUserEventStreamsEnabled = platformConfig?.isUserEventStreamsEnabled, isUserEventStreamsEnabled else {
                log.debug("USER_EVENT_STREAM: userEventStreamsEnabled has been disabled at the platform level, skipping user event stream subscription")
                return
            }
            
            self.client!.user(id: userId) { (user, _) in
                guard let user = user else { return }
                
                self.userEventStream = UserEventStream(user: user, client: self.client!, completion: completion)
            }
        }
    }
}
