import Foundation

/// Identifies the party initiating the lifecycle event
///
/// - cardholder: card holder
/// - issuer: issuer
/// - unknown: unknown
public enum CreditCardInitiator: String, Codable {
    case cardholder = "CARDHOLDER"
    case issuer     = "ISSUER"
    case unknown    = "UNKNOWN"
}
