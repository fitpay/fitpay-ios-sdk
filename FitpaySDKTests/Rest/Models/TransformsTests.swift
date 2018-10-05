import XCTest
@testable import FitpaySDK

class TransformTests: XCTestCase {
    
    func testNSTimeIntervalToInt() {
        let currentTime = Date().timeIntervalSince1970
        let timeTransform = NSTimeIntervalTypeTransform()
        
        guard let timeAsInt = timeTransform.transform(currentTime) else {
            XCTAssert(false, "Can't get int value for time.")
            return
        }

        let intMirror = Mirror(reflecting: timeAsInt)
        
        XCTAssert(String(describing: intMirror.subjectType) == "Int64")
    }
    
    func testDateToIntTransformIn() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let transform = DateToIntTransform()
        
        let testDate = transform.transform(2)
        XCTAssert(calendar.isDate(testDate!, inSameDayAs: twoDaysAgo))
    }
    
    func testDateToIntTransformOut() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let transform = DateToIntTransform()
        
        let testInt = transform.transform(twoDaysAgo)
        XCTAssertEqual(testInt, 2)
    }

}
