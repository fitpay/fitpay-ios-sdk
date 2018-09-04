import Foundation
import Alamofire

class UserEventStream {
    
    init(user: User, client: RestClient, completion: @escaping UserEventStreamManager.userEventStreamHandler) {
        guard let eventStreamLink = user.links?.url("eventStream") else { return }
        let jsonDecoder = JSONDecoder()
        
        client.prepareAuthAndKeyHeaders { (headers, error) in
            let eventSource = EventSource(url: eventStreamLink, headers: [:])
            eventSource.onOpen {
                log.debug("USER_EVENT_STREAM: connected to event stream for user \(user.id ?? "no user")")
            }
            
            eventSource.onError { (error) in
                guard let error = error else { return }
                log.error("USER_EVENT_STREAM: error in event stream: \(error)")
            }
            
            eventSource.onMessage { (id, event, data) in
                guard let jwtBodyString = JWE.decryptSigned(data, expectedKeyId: client.key?.keyId, secret: client.secret) else { return }
                guard let streamEvent = try? jsonDecoder.decode(StreamEvent.self, from: jwtBodyString.data(using: String.Encoding.utf8)!) else { return }
                
                log.debug("USER_EVENT_STREAM: message received: \(streamEvent.type)")
                log.verbose("USER_EVENT_STREAM: payload: \(streamEvent.payload ?? [:])")
                
                completion(streamEvent)
            }
        }
    }
    
}
