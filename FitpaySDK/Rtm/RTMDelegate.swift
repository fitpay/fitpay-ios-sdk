import Foundation

/// Delegate to get Ream Time Messages to and from the Webview
@objc public protocol RTMDelegate: NSObjectProtocol {

    ///  This method will be called after successful user authorization.
    ///
    /// - Parameter email: email that was authorized
    @objc func didAuthorizeWith(email: String)

    /// This method can be used for user messages customization.
    /// Will be called when status has changed and system going to show message.
    ///
    /// - Parameters:
    ///   - status: New device status
    ///   - defaultMessage: Default message for new status
    ///   - error: If there was an error during status change than it will be here.
    /// - Returns: Message string which will be shown on status board.
    @objc optional func willDisplayStatusMessage(_ status: WVDeviceStatus, defaultMessage: String, error: NSError?) -> String
    
    /// Called when the message from wv was delivered to SDK.
    ///
    /// - Parameter message: message from web view
    @objc optional func onWvMessageReceived(message: RtmMessage)
    
}
