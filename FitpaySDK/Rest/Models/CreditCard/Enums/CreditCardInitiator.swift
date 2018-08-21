import Foundation

/// Identifies the party initiating the deactivation/reactivation request
///
/// - cardholder: card holder
/// - issuer: issuer
public enum CreditCardInitiator: String, Codable {
    case cardholder = "CARDHOLDER"
    case issuer     = "ISSUER"
}
