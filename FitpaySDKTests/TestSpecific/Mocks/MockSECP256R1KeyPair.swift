@testable import FitpaySDK

class MockSECP256R1KeyPair: SECP256R1KeyPair {

    private let unknownPrefix = "3059301306072a8648ce3d020106082a8648ce3d030107034200" // TODO: Bouncy Castle issue?

    // we should provide public key
    // with unknown prefix
    var mocPublicKey: String? = "3059301306072a8648ce3d020106082a8648ce3d03010703420004fc1b33fba86e15ff35938d60a8fdf3c6de640d70cf21ef966fb4f27356f9b72624ed9772b845f3c1ab2efd17211e7867c22e82ad60643d03839b6e57aabad16f"

     var mocPrivateKey: String?  = "04b9e39c8a2af9ab895f976db545fdc25c49f134889d170e828e5bb5b3a7bb4350e810cf0d82ae904af6aca9410c72b1721cf0a57e4b330b69233fce3690c0eb8a56fd827b9017f60eed32ab1db440352ee037e3ecfc47881a460e87ad229be4c8"

    override func generateSecretForPublicKey(_ publicKey: String) -> Data? {
        let publicKey = mocPublicKey!
        // removing prefix from public key
        let start = publicKey.index(publicKey.startIndex, offsetBy: 0)
        let end   = publicKey.index(publicKey.startIndex, offsetBy: unknownPrefix.count)

        let publicKeyWithoutPrefix = publicKey.replacingCharacters(in: start..<end, with: "")

        // compute secret for public key without prefix
        return try? CC.EC.computeSharedSecret(mocPrivateKey!.hexToData()!, publicKey: publicKeyWithoutPrefix.hexToData()!)
    }
}
