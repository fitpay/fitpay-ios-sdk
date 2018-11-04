import XCTest
import Nimble

@testable import FitpaySDK

class TransformTests: XCTestCase {
    
    func testNSTimeIntervalTypeTransformIn() {
        let baseInt: Int64 = 2000
        let baseTimeInterval: TimeInterval = 2
        let transform = NSTimeIntervalTypeTransform()

        let testTimeInterval = transform.transform(baseInt)
        expect(testTimeInterval).to(equal(baseTimeInterval))
        
        let timeIntervalMirror = Mirror(reflecting: testTimeInterval!)
        expect(String(describing: timeIntervalMirror.subjectType)).to(equal("Double"))
        
        let nilInt: Int64? = nil
        let testNilTimeInterval = transform.transform(nilInt)
        expect(testNilTimeInterval).to(beNil())
    }
    
    func testNSTimeIntervalTypeTransformOut() {
        let baseInt: Int64 = 2000
        let baseTimeInterval: TimeInterval = 2
        let transform = NSTimeIntervalTypeTransform()
        
        let testInt = transform.transform(baseTimeInterval)
        expect(testInt).to(equal(baseInt))
        
        let intMirror = Mirror(reflecting: testInt!)
        expect(String(describing: intMirror.subjectType)).to(equal("Int64"))
        
        let nilTimeInterval: TimeInterval? = nil
        let testNilInt = transform.transform(nilTimeInterval)
        expect(testNilInt).to(beNil())
    }
    
    func testCustomDateFormatTransformIn() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY-DD-MM"
        let transform = CustomDateFormatTransform(formatString: "YY-DD-MM")
        
        let testDate = transform.transform(dateFormatter.string(from: twoDaysAgo))
        expect(calendar.isDate(testDate!, inSameDayAs: twoDaysAgo)).to(beTrue())
        
        let nilString: String? = nil
        let testNilDate = transform.transform(nilString)
        expect(testNilDate).to(beNil())
    }
    
    func testCustomDateFormatTransformOut() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY-DD-MM"
        let transform = CustomDateFormatTransform(formatString: "YY-DD-MM")
        
        let testSring = transform.transform(twoDaysAgo)
        expect(testSring).to(equal(dateFormatter.string(from: twoDaysAgo)))
        
        let nilDate: Date? = nil
        let testNilInt = transform.transform(nilDate)
        expect(testNilInt).to(beNil())
    }
    
    func testDateToIntTransformIn() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let transform = DateToIntTransform()
        
        let testDate = transform.transform(2)
        expect(calendar.isDate(testDate!, inSameDayAs: twoDaysAgo)).to(beTrue())
        
        let nilInt: Int? = nil
        let testNilDate = transform.transform(nilInt)
        expect(testNilDate).to(beNil())
    }
    
    func testDateToIntTransformOut() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let transform = DateToIntTransform()
        
        let testInt = transform.transform(twoDaysAgo)
        expect(testInt).to(equal(2))
        
        let nilDate: Date? = nil
        let testNilInt = transform.transform(nilDate)
        expect(testNilInt).to(beNil())
    }
    
}
