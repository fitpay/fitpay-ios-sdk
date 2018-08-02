import XCTest
@testable import FitpaySDK

class NSErrorExtensionTests: XCTestCase {

    func testErrorWithData() {
        let errorsJson = "{\"errors\": [{\"message\":\"Error\"}]}"
        let errorJson = "{\"message\":\"Error\"}"
        let message = "Error"

        var error =  NSError.errorWithData(code: 1, domain: self, data: errorsJson.data(using: .utf8))
        XCTAssertEqual(error.code, 1)
        XCTAssertEqual(error.localizedDescription, "Error")

        error =  NSError.errorWithData(code: 1, domain: self, data: errorJson.data(using: .utf8))
        XCTAssertEqual(error.code, 1)
        XCTAssertEqual(error.localizedDescription, "Error")

        error =  NSError.errorWithData(code: 1, domain: self, data: message.data(using: .utf8))
        XCTAssertEqual(error.code, 1)
        XCTAssertEqual(error.localizedDescription, "Error")

        let userInfo:[String: Any] = [NSLocalizedDescriptionKey: "Error"]
        let artenativeError = NSError(domain: "Some", code: 1, userInfo: userInfo)
        error = NSError.errorWithData(code: 1, domain: self, data: nil, alternativeError: artenativeError)
        XCTAssertEqual(error.code, 1)
        XCTAssertEqual(error.localizedDescription, "Error")
    }

    func testNoClientUrlError() {
        let error = NSError.clientUrlError(domain: self, code: 1, client: nil, url: nil, resource: "")
        XCTAssertEqual(error?.code, 0)
        XCTAssertEqual(error?.localizedDescription, "\(RestClient.self) is not set.")
    }

    func testNoUrlError() {
        let error = NSError.clientUrlError(domain: self, code: 1, client: RestClient(session: RestSession(restRequest: MockRestRequest()), restRequest: MockRestRequest()), url: nil, resource: "some")
        XCTAssertEqual(error?.code, 0)
        XCTAssertEqual(error?.localizedDescription, "Failed to retrieve url for resource \'some\'")
    }
}
