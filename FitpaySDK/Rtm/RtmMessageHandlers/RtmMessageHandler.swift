//
//  RtmMessageHandler.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 30.05.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation

public typealias MessageTypeHandler = (_ message: RtmMessage) -> Void

protocol RtmMessageTypeWithHandler {
    init?(rawValue: RtmMessageType)
    
    
    func msgHandlerFor(handlerObject: RtmMessageHandler) -> MessageTypeHandler?
}

protocol RtmMessageHandler {
    weak var wvConfigStorage: WvConfigStorage! { get }
    
    weak var outputDelegate: RtmOutputDelegate? { get set }
    weak var wvRtmDelegate: WvRTMDelegate? { get set }
    weak var cardScannerPresenterDelegate: FitpayCardScannerPresenterDelegate? { get set }
    weak var cardScannerDataSource: FitpayCardScannerDataSource? { get set }
    weak var a2aVerificationDelegate: FitpayA2AVerificationDelegate? { get set }

    
    init(wvConfigStorage: WvConfigStorage)
    
    func handle(message: [String: Any])
    func handlerFor(rtmMessage: RtmMessageType) -> MessageTypeHandler?
    
    func handleSync(_ message: RtmMessage)
    func handleSessionData(_ message: RtmMessage)

    func handleSdkVersion(_ message: RtmMessage)

    func resolveSync()
    
    func logoutResponseMessage() -> RtmMessageResponse?
    func statusResponseMessage(message: String, type: WVMessageType) -> RtmMessageResponse?
    func versionResponseMessage(version: RtmProtocolVersion) -> RtmMessageResponse?

}

extension RtmMessageHandler {
    func handleSdkVersion(_ message: RtmMessage) {
    }
}
