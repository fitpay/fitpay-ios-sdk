import XCTest
@testable import FitpaySDK

class DataExtensionsTests: BaseTestProvider {

    func testBase64URLencoded() {
        let payloadIV = String.random(JWEObject.PayloadIVSize).data(using: String.Encoding.utf8)
        guard let encodedPayloadIV = payloadIV?.base64URLencoded() else {
            XCTAssert(false, "Bad encoding")
            return
        }

        XCTAssertFalse(encodedPayloadIV.contains("/"))
    }

    func testreverseEndian() {
        let original = PAYMENT_CHARACTERISTIC_UUID_APDU_CONTROL.data
        let reversed = original.reverseEndian
        XCTAssertTrue(original.first == reversed.last)
    }

    func testErrorMessage() {
        let errorJSON = "{\"message\":\"The property termsVersion contains an invalid value (null): may not be empty\"}"
        let errorData = errorJSON.data(using: .utf8)
        let errorMessage = errorData?.errorMessage
        XCTAssertEqual(errorMessage, "The property termsVersion contains an invalid value (null): may not be empty")
    }

    func testErrorMessages() {
        let errorsJSON = "{\"errors\": [{\"message\":\"The property termsVersion contains an invalid value (null): may not be empty\"}]}"
        let errorsData = errorsJSON.data(using: .utf8)
        let errorMessages = errorsData?.errorMessages
        XCTAssertEqual(errorMessages?.first, "The property termsVersion contains an invalid value (null): may not be empty")
    }

    func testUTF8String() {
        let string = "The property termsVersion contains an invalid value (null): may not be empty"
        let utf32Data = string.data(using: String.Encoding.utf32)
        let utf8Data = string.data(using: String.Encoding.utf8)
        XCTAssertEqual(string, utf8Data?.UTF8String)
        XCTAssertNotEqual(string, utf32Data?.UTF8String)
    }

    func testBytesArray() {
        let keyPair = MockSECP256R1KeyPair()
        guard let data = keyPair.generateSecretForPublicKey(keyPair.publicKey!) else {
            XCTAssert(false, "bad secret")
            return
        }
        let bytes = data.bytesArray
        XCTAssertEqual(bytes.count, data.count)
    }

    func testHex() {
        let keyPair = MockSECP256R1KeyPair()
        guard let data = keyPair.generateSecretForPublicKey(keyPair.mocPublicKey!) else {
            XCTAssert(false, "bad secret")
            return
        }
        let hexString = data.hex.uppercased()
        XCTAssertEqual(hexString, "D9EA91F550D6C462FB25CC364D3069E84E72E44E9F64351161E30012D450E527")
    }
}
