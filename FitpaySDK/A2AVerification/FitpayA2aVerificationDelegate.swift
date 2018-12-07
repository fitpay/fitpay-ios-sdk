import Foundation

/// Get app-to-app verification response
/// On completion of the issuer intent the OEM app must then open the web-view using the returnLocation.
/// <baseUrl>/<returnLocation>?config=<base64 encoded config>&a2a=<a2aissuerRequest encoded>
@objc public protocol FitpayA2AVerificationDelegate: NSObjectProtocol {

    /// Called when the user taps the app-to-app verification method
    /// Should be used to open the issuer's app programatically
    ///
    /// - Parameter verificationInfo: The Verification Information
    func verificationFinished(verificationInfo: A2AVerificationRequest?)
}
