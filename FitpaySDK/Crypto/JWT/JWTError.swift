import Foundation

enum JWTError: Error {
    case headerNotSpecified
    case encryptionNotSpecified
    case algorithmNotSpecified
    case headersIVNotSpecified
    case headersTagNotSpecified
    case invalidPartCount
    case invalidJSON
    case invalidBase64Url
}
