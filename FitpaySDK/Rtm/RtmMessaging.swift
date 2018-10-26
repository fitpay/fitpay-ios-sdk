import Foundation

protocol RtmOutputDelegate: class {
    func send(rtmMessage: RtmMessageResponse, retries: Int)
    func show(status: WVDeviceStatus, message: String?, error: Error?)
}

class RtmMessaging {
    weak var outputDelegate: RtmOutputDelegate?
    weak var rtmDelegate: RTMDelegate?
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate?
    weak var cardScannerDataSource: FitpayCardScannerDataSource?
    weak var a2aVerificationDelegate: FitpayA2AVerificationDelegate?
    
    lazy var handlersMapping: [WvConfig.RtmProtocolVersion: RtmMessageHandler?] = {
        return [WvConfig.RtmProtocolVersion.ver1: nil,
                WvConfig.RtmProtocolVersion.ver2: RtmMessageHandlerV2(wvConfigStorage: self.wvConfigStorage),
                WvConfig.RtmProtocolVersion.ver3: RtmMessageHandlerV3(wvConfigStorage: self.wvConfigStorage),
                WvConfig.RtmProtocolVersion.ver4: RtmMessageHandlerV4(wvConfigStorage: self.wvConfigStorage),
                WvConfig.RtmProtocolVersion.ver5: RtmMessageHandlerV5(wvConfigStorage: self.wvConfigStorage)]
    }()
    
    private(set) var messageHandler: RtmMessageHandler?
    private var wvConfigStorage: WvConfigStorage
    
    private struct BufferedMessage {
        var message: [String: Any]
        var completion: RtmRawMessageCompletion?
    }
    
    private var preVersionBuffer: [BufferedMessage]
    private var receivedWrongVersion = false
    
    init(wvConfigStorage: WvConfigStorage) {
        self.wvConfigStorage = wvConfigStorage
        self.preVersionBuffer = []
    }
    
    typealias RtmRawMessageCompletion = ((_ success: Bool) -> Void)
    
    func received(message: [String: Any], completion: RtmRawMessageCompletion? = nil) {        
        guard let rtmMessage = try? RtmMessage(message) else {
            log.error("WV_DATA: Can't create RtmMessage.")
            completion?(false)
            return
        }

        defer {
            rtmDelegate?.onWvMessageReceived?(message: rtmMessage)
        }
        
        guard messageHandler == nil else {
            messageHandler?.handle(message: message)
            completion?(true)
            return
        }
        
        switch rtmMessage.type ?? "" {
        case "version":
            guard let versionDictionary = rtmMessage.data as? [String: Int], let versionInt = versionDictionary["version"] else {
                log.error("WV_DATA: Can't get version of rtm protocol. Data: \(String(describing: rtmMessage.data)).")
                completion?(false)
                return
            }
            
            guard let version = WvConfig.RtmProtocolVersion(rawValue: versionInt) else {
                log.error("WV_DATA: Unknown rtm version - \(versionInt).")
                receivedWrongVersion = true
                completion?(false)
                return
            }
            
            log.debug("WV_DATA: received \(version) rtm version.")
            
            guard handlersMapping.index(forKey: version) != nil, var handler = handlersMapping[version]! else {
                log.error("WV_DATA: There is no message handler for version: \(version).")
                completion?(false)
                return
            }
            
            handler.wvRtmDelegate = self.rtmDelegate
            handler.outputDelegate = self.outputDelegate
            handler.cardScannerDataSource = self.cardScannerDataSource
            handler.cardScannerPresenterDelegate = self.cardScannerPresenterDelegate
            handler.a2aVerificationDelegate = self.a2aVerificationDelegate

            self.messageHandler = handler
            
            defer {
                for message in preVersionBuffer {
                    received(message: message.message, completion: message.completion)
                }
                preVersionBuffer = []
            }
            
        default:
            if !receivedWrongVersion {
                log.debug("WV_DATA: Adding message to the buffer. Will be used after we will receive rtm version.")
                preVersionBuffer.append(BufferedMessage(message: message, completion: completion))
            } else {
                log.error("WV_DATA: Can't handle message because version ack was failed.")
                completion?(false)
            }
            return
        }
        
        completion?(true)
    }
    
}
