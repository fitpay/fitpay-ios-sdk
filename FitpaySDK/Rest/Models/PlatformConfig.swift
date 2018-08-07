import Foundation

/// Used to be able to enable/disable features remotely from the server
///
/// Primarily used for internal SDK purposes
public struct PlatformConfig: Serializable {
    
    /// Can be used disable the user event stream from being initialized
    ///
    /// server defaults to true
    public let isUserEventStreamsEnabled: Bool
    
    private enum CodingKeys: String, CodingKey {
        case isUserEventStreamsEnabled = "userEventStreamsEnabled"
    }
}
