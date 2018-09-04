import XCTest
import Nimble

@testable import FitpaySDK

class ArrayExtensionsTests: XCTestCase {
    
    func testToString() {
        let testArray = ["Foo", "Bar", "FooBar"]
        let jsonString = testArray.JSONString
        
        expect(jsonString).to(equal("[\"Foo\",\"Bar\",\"FooBar\"]"))
    }
    
    func testFIFO() {
        var testArray: [String] = []
        
        let nilString = testArray.dequeue()
        expect(nilString).to(beNil())
        
        testArray.enqueue("Test")
        expect(testArray.count).to(equal(1))
        expect(testArray[0]).to(equal("Test"))

        testArray.enqueue("Test2")
        expect(testArray.count).to(equal(2))
        expect(testArray[1]).to(equal("Test2"))
        
        expect(testArray.peekAtQueue()).to(equal("Test"))
        
        expect(testArray.dequeue()).to(equal("Test"))
        expect(testArray.count).to(equal(1))
        
        expect(testArray.dequeue()).to(equal("Test2"))
        expect(testArray.count).to(equal(0))
    }

    func testUrl() {
        let resourceLink1 = ResourceLink()
        resourceLink1.target = "Foo"
        resourceLink1.href = "FooHref"
        let resourceLink2 = ResourceLink()
        resourceLink2.target = "Bar"
        resourceLink2.href = "BarHref"

        let testArray: [ResourceLink] = [resourceLink1, resourceLink2]
        
        expect(testArray.url("Foo")).to(equal(resourceLink1.href))
        expect(testArray.url("Bar")).to(equal(resourceLink2.href))
        expect(testArray.url("FooBar")).to(beNil())
    }

    func testElementAt() {
        let resourceLink1 = ResourceLink()
        resourceLink1.target = "Foo"
        resourceLink1.href = "FooHref"
        let resourceLink2 = ResourceLink()
        resourceLink2.target = "Bar"
        resourceLink2.href = "BarHref"
        
        let testArray: [ResourceLink] = [resourceLink1, resourceLink2]
        
        expect(testArray.elementAt("Foo")).to(equal(resourceLink1))
        expect(testArray.elementAt("Bar")).to(equal(resourceLink2))
        expect(testArray.elementAt("FooBar")).to(beNil())
    }
    
    func testRemoveObject() {
        var testArray = ["Foo", "Bar", "FooBar", "FooBar2"]
        
        testArray.removeObject("NotHere")
        expect(testArray.count).to(equal(4))

        testArray.removeObject("Bar")
        expect(testArray.count).to(equal(3))
        expect(testArray[1]).to(equal("FooBar"))
        
        testArray.removeObject("FooBar")
        expect(testArray.count).to(equal(2))
        expect(testArray[1]).to(equal("FooBar2"))
    }

}
