import Foundation
import Alamofire

class UserEventStream {
    
    private var eventSource: EventSource?
    
    init(user: User, client: RestClient, completion: @escaping UserEventStreamManager.userEventStreamHandler) {
        guard let eventStreamLink = user.eventStreamLink?.href else { return }
        let jsonDecoder = JSONDecoder()
        
        client.prepareAuthAndKeyHeaders { (headers, error) in
            self.eventSource = EventSource(url: eventStreamLink, headers: [:])
            
            self.eventSource?.onOpen {
                log.debug("USER_EVENT_STREAM: connected to event stream for user \(user.id ?? "no user")")
            }
            
            self.eventSource?.onError { (error) in
                guard let error = error else { return }
                if error.code == -999 { //cancelled
                    log.debug("USER_EVENT_STREAM: connection closed for user \(user.id ?? "no user")")
                } else {
                    log.error("USER_EVENT_STREAM: error in event stream: \(error)")
                }
            }
            
            self.eventSource?.onMessage { (_, _, data) in
                guard let jwtBodyString = JWE.decryptSigned(data, expectedKeyId: client.key?.keyId, secret: client.secret) else { return }
                guard let streamEvent = try? jsonDecoder.decode(StreamEvent.self, from: jwtBodyString.data(using: String.Encoding.utf8)!) else { return }
                
                log.debug("USER_EVENT_STREAM: message received: \(String(describing: streamEvent.type))")
                log.verbose("USER_EVENT_STREAM: payload: \(streamEvent.payload ?? [:])")
                
                completion(streamEvent)
            }
        }
    }
    
    func close() {
        eventSource?.close()
    }
    
}
