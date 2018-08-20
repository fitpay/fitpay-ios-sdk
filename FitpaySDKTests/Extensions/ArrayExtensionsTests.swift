import XCTest
@testable import FitpaySDK

class ArrayExtensionsTests: XCTestCase {
    
    func testToString() {
        let testArray = ["Foo", "Bar", "FooBar"]
        let jsonString = testArray.JSONString
        
        XCTAssertEqual(jsonString, "[\"Foo\",\"Bar\",\"FooBar\"]")
    }
    
    func testFIFO() {
        var testArray: [String] = []
        
        testArray.enqueue("Test")
        XCTAssertEqual(testArray.count, 1)
        XCTAssertEqual(testArray[0], "Test")

        testArray.enqueue("Test2")
        XCTAssertEqual(testArray.count, 2)
        XCTAssertEqual(testArray[1], "Test2")
        
        XCTAssertEqual(testArray.peekAtQueue(), "Test")
        
        XCTAssertEqual(testArray.dequeue(), "Test")
        XCTAssertEqual(testArray.count, 1)
        
        XCTAssertEqual(testArray.dequeue(), "Test2")
        XCTAssertEqual(testArray.count, 0)
    }

    func testUrl() {
        let resourceLink1 = ResourceLink()
        resourceLink1.target = "Foo"
        resourceLink1.href = "FooHref"
        let resourceLink2 = ResourceLink()
        resourceLink2.target = "Bar"
        resourceLink2.href = "BarHref"

        let testArray: [ResourceLink] = [resourceLink1, resourceLink2]
        
        XCTAssertEqual(testArray.url("Foo"), resourceLink1.href)
        XCTAssertEqual(testArray.url("Bar"), resourceLink2.href)
        XCTAssertNil(testArray.url("FooBar"))
    }

    func testElementAt() {
        let resourceLink1 = ResourceLink()
        resourceLink1.target = "Foo"
        resourceLink1.href = "FooHref"
        let resourceLink2 = ResourceLink()
        resourceLink2.target = "Bar"
        resourceLink2.href = "BarHref"
        
        let testArray: [ResourceLink] = [resourceLink1, resourceLink2]
        
        XCTAssertEqual(testArray.elementAt("Foo"), resourceLink1)
        XCTAssertEqual(testArray.elementAt("Bar"), resourceLink2)
        XCTAssertNil(testArray.elementAt("FooBar"))
    }
    
    func testRemoveObject() {
        var testArray = ["Foo", "Bar", "FooBar", "FooBar2"]
        
        testArray.removeObject("NotHere")
        XCTAssertEqual(testArray.count, 4)

        testArray.removeObject("Bar")
        XCTAssertEqual(testArray.count, 3)
        XCTAssertEqual(testArray[1], "FooBar")
        
        testArray.removeObject("FooBar")
        XCTAssertEqual(testArray.count, 2)
        XCTAssertEqual(testArray[1], "FooBar2")

    }

}
