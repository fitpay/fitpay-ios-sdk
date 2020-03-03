import Foundation

enum EventSourceState {
    case connecting
    case open
    case closed
}

class EventSource: NSObject {
    
    let url: URL
    
    private let lastEventIDKey: String
    private let receivedString: NSString?
    private var onOpenCallback: (() -> Void)?
    private var onErrorCallback: ((NSError?) -> Void)?
    private var onMessageCallback: ((_ id: String?, _ event: String?, _ data: String?) -> Void)?
    
    var readyState: EventSourceState
    private(set) var retryTime = 3000
    
    private var eventListeners: [String: (_ id: String?, _ event: String?, _ data: String?) -> Void] = [:]
    private var headers: [String: String]
    
    var urlSession: Foundation.URLSession?
    var task: URLSessionDataTask?
    
    private var operationQueue: OperationQueue
    private var errorBeforeSetErrorCallBack: NSError?
    
    let receivedDataBuffer: NSMutableData
    
    private let uniqueIdentifier: String
    private let validNewlineCharacters = ["\r\n", "\n", "\r"]
    
    var event = [String: String]()
    
    var lastEventID: String? {
        set {
            if let lastEventID = newValue {
                let defaults = UserDefaults.standard
                defaults.set(lastEventID, forKey: lastEventIDKey)
            }
        }
        
        get {
            let defaults = UserDefaults.standard
            let lastEventID = defaults.string(forKey: lastEventIDKey)
            
            return lastEventID
        }
    }
    
    init(url: String, headers: [String: String] = [:]) {
        
        self.url = URL(string: url)!
        self.headers = headers
        self.readyState = EventSourceState.closed
        self.operationQueue = OperationQueue()
        self.receivedString = nil
        self.receivedDataBuffer = NSMutableData()
        
        let port = String(self.url.port ?? 80)
        let relativePath = self.url.relativePath
        let host = self.url.host ?? ""
        let scheme = self.url.scheme ?? ""
        
        self.uniqueIdentifier = "\(scheme).\(host).\(port).\(relativePath)"
        self.lastEventIDKey = "\(self.uniqueIdentifier)"
        
        super.init()
        self.connect()
    }
    
    // MARK: - Connect
    func connect() {
        var additionalHeaders = self.headers
        if let eventID = self.lastEventID {
            additionalHeaders["Last-Event-Id"] = eventID
        }
        
        additionalHeaders["Accept"] = "text/event-stream"
        additionalHeaders["Cache-Control"] = "no-cache"
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
        configuration.httpAdditionalHeaders = additionalHeaders
        
        readyState = EventSourceState.connecting
        urlSession = newSession(configuration)
        task = urlSession?.dataTask(with: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: TimeInterval(INT_MAX)))
        
        task?.resume()
    }
    
    func newSession(_ configuration: URLSessionConfiguration) -> URLSession {
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Close
    func close() {
        self.readyState = EventSourceState.closed
        self.urlSession?.invalidateAndCancel()
    }

    // MARK: - EventListeners
    func onOpen(_ onOpenCallback: @escaping (() -> Void)) {
        self.onOpenCallback = onOpenCallback
    }
    
    func onError(_ onErrorCallback: @escaping ((NSError?) -> Void)) {
        self.onErrorCallback = onErrorCallback
        
        if let errorBeforeSet = self.errorBeforeSetErrorCallBack {
            self.onErrorCallback!(errorBeforeSet)
            self.errorBeforeSetErrorCallBack = nil
        }
    }
    
    func onMessage(_ onMessageCallback: @escaping ((_ id: String?, _ event: String?, _ data: String?) -> Void)) {
        self.onMessageCallback = onMessageCallback
    }
    
    func addEventListener(_ event: String, handler: @escaping ((_ id: String?, _ event: String?, _ data: String?) -> Void)) {
        eventListeners[event] = handler
    }
    
    func removeEventListener(_ event: String) {
        eventListeners.removeValue(forKey: event)
    }
    
    func events() -> [String] {
        return Array(eventListeners.keys)
    }

    // MARK: - Private Helpers
    private func extractEventsFromBuffer() -> [String] {
        var events = [String]()
        
        // Find first occurrence of delimiter
        var searchRange =  NSRange(location: 0, length: receivedDataBuffer.length)
        while let foundRange = searchForEventInRange(searchRange) {
            // Append event
            if foundRange.location > searchRange.location {
                let dataChunk = receivedDataBuffer.subdata(
                    with: NSRange(location: searchRange.location, length: foundRange.location - searchRange.location)
                )
                
                if let text = String(bytes: dataChunk, encoding: .utf8) {
                    events.append(text)
                }
            }
            // Search for next occurrence of delimiter
            searchRange.location = foundRange.location + foundRange.length
            searchRange.length = receivedDataBuffer.length - searchRange.location
        }
        
        // Remove the found events from the buffer
        self.receivedDataBuffer.replaceBytes(in: NSRange(location: 0, length: searchRange.location), withBytes: nil, length: 0)
        
        return events
    }
    
    private func searchForEventInRange(_ searchRange: NSRange) -> NSRange? {
        let delimiters = validNewlineCharacters.map { "\($0)\($0)".data(using: String.Encoding.utf8)! }
        
        for delimiter in delimiters {
            let foundRange = receivedDataBuffer.range(of: delimiter, options: NSData.SearchOptions(), in: searchRange)
            if foundRange.location != NSNotFound {
                return foundRange
            }
        }
        
        return nil
    }
    
    private func parseEventStream(_ events: [String]) {
        var parsedEvents: [(id: String?, event: String?, data: String?)] = Array()
        
        for event in events {
            if event.isEmpty { continue }
            if event.hasPrefix(":") { continue }
            
            if event.contains("retry:") {
                if let reconnectTime = parseRetryTime(event) {
                    self.retryTime = reconnectTime
                }
                continue
            }
            
            parsedEvents.append(parseEvent(event))
        }
        
        for parsedEvent in parsedEvents {
            self.lastEventID = parsedEvent.id
            
            if parsedEvent.event == nil {
                if let data = parsedEvent.data, let onMessage = self.onMessageCallback {
                    DispatchQueue.main.async {
                        onMessage(self.lastEventID, "message", data)
                    }
                }
            }
            
            if let event = parsedEvent.event, let data = parsedEvent.data, let eventHandler = self.eventListeners[event] {
                DispatchQueue.main.async {
                    eventHandler(self.lastEventID, event, data)
                }
            }
        }
    }

    private func parseEvent(_ eventString: String) -> (id: String?, event: String?, data: String?) {
        var event = [String: String]()
        
        for line in eventString.components(separatedBy: CharacterSet.newlines) as [String] {
            autoreleasepool {
                let (k, value) = self.parseKeyValuePair(line)
                guard let key = k else { return }
                
                if let value = value {
                    if event[key] != nil {
                        event[key] = "\(event[key]!)\n\(value)"
                    } else {
                        event[key] = value
                    }
                } else if value == nil {
                    event[key] = ""
                }
            }
        }
        
        return (event["id"], event["event"], event["data"])
    }
    
    private func parseKeyValuePair(_ line: String) -> (String?, String?) {
        var key: NSString?, value: NSString?
        let scanner = Scanner(string: line)
        scanner.scanUpTo(":", into: &key)
        scanner.scanString(":", into: nil)
        
        for newline in validNewlineCharacters {
            if scanner.scanUpTo(newline, into: &value) {
                break
            }
        }
        
        return (key as String?, value as String?)
    }
    
    private func parseRetryTime(_ eventString: String) -> Int? {
        var reconnectTime: Int?
        let separators = CharacterSet(charactersIn: ":")
        if let milli = eventString.components(separatedBy: separators).last {
            let milliseconds = trim(milli)
            
            if let intMiliseconds = Int(milliseconds) {
                reconnectTime = intMiliseconds
            }
        }
        return reconnectTime
    }
    
    private func trim(_ string: String) -> String {
        return string.trimmingCharacters(in: CharacterSet.whitespaces)
    }
 
    private func receivedMessageToClose(_ httpResponse: HTTPURLResponse?) -> Bool {
        guard let response = httpResponse  else { return false }
        
        if response.statusCode == 204 {
            self.close()
            return true
        }
        return false
    }
    
    private func receivedInvalidResponse(_ httpResponse: HTTPURLResponse?) -> Bool {
        guard let response = httpResponse else { return false }
        
        if response.statusCode == 200 {
            return false
        }
        FitpaySDKLogger.sharedInstance.error("USER_EVENT_STREAM error status code: \(response.statusCode)")
        return true
    }
    
}

extension EventSource: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if self.receivedMessageToClose(dataTask.response as? HTTPURLResponse) {
            return
        }
        
        if self.readyState != EventSourceState.open {
            return
        }
        
        self.receivedDataBuffer.append(data)
        let eventStream = extractEventsFromBuffer()
        self.parseEventStream(eventStream)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(URLSession.ResponseDisposition.allow)

        if self.receivedMessageToClose(dataTask.response as? HTTPURLResponse) {
            return
        }
        
        if self.receivedInvalidResponse(dataTask.response as? HTTPURLResponse) {
            return
        }
        
        //Set ready state to open when the open when callback is known not to be nil
        if self.onOpenCallback != nil {
            self.readyState = .open
            DispatchQueue.main.async {
                self.onOpenCallback!()
            }
        } else {
            FitpaySDKLogger.sharedInstance.error("USER_EVENT_STREAM error onOpenCallback nil")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.readyState = EventSourceState.closed
        
        if self.receivedMessageToClose(task.response as? HTTPURLResponse) {
            return
        }
        
        if error == nil || (error! as NSError).code != -999 {
            //could reconnect but we can't
        }
        
        DispatchQueue.main.async {
            if let errorCallback = self.onErrorCallback {
                errorCallback(error as NSError?)
            } else {
                self.errorBeforeSetErrorCallBack = error as NSError?
            }
        }
    }
    
}
