import Foundation

typealias MessageTypeHandler = (_ message: RtmMessage) -> Void

protocol RtmMessageTypeWithHandler {
    init?(rawValue: String)
    func msgHandlerFor(handlerObject: RtmMessageHandler) -> MessageTypeHandler?
}

protocol RtmMessageHandler {
    var wvConfigStorage: WvConfigStorage! { get }
    
    var outputDelegate: RtmOutputDelegate? { get set }
    var wvRtmDelegate: RTMDelegate? { get set }
    var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate? { get set }
    var cardScannerDataSource: FitpayCardScannerDataSource? { get set }
    var a2aVerificationDelegate: FitpayA2AVerificationDelegate? { get set }

    init(wvConfigStorage: WvConfigStorage)
    
    func handle(message: [String: Any])
    func handlerFor(rtmMessage: String) -> MessageTypeHandler?
    
    func handleSync(_ message: RtmMessage)
    func handleSessionData(_ message: RtmMessage)

    func handleSdkVersion(_ message: RtmMessage)

    func resolveSync()
    func appToAppVerificationResponse(success: Bool, reason: A2AVerificationError?)

    func logoutResponseMessage() -> RtmMessageResponse?
    func statusResponseMessage(message: String, type: WvConfig.WVMessageType) -> RtmMessageResponse?
    func versionResponseMessage(version: WvConfig.RtmProtocolVersion) -> RtmMessageResponse?

}

extension RtmMessageHandler {
    func handleSdkVersion(_ message: RtmMessage) {
    }
}
