import Foundation

protocol SecretApplyable {
    func applySecret(_ secret: Foundation.Data, expectedKeyId: String?)
}
