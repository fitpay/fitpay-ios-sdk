import XCTest
import Nimble

@testable import FitpaySDK

class AssetTests: XCTestCase {
    let mockModels = MockModels()
    
    func testInit() {
        let testData = Data()
        let dataAsset = Asset(data: testData)
        
        expect(dataAsset.data).to(equal(testData))
        expect(dataAsset.text).to(beNil())
        expect(dataAsset.image).to(beNil())
        
        let text = "Hello World"
        let textAsset = Asset(text: text)
        
        expect(textAsset.data).to(beNil())
        expect(textAsset.text).to(equal(text))
        expect(textAsset.image).to(beNil())
        
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        guard let path = bundle.path(forResource: "fitpay-logo", ofType: "png"),
            let imageData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let image = UIImage(data: imageData) else {
                fail()
                return
        }
        
        let imageAsset = Asset(image: image)
        
        expect(imageAsset.data).to(beNil())
        expect(imageAsset.text).to(beNil())
        expect(imageAsset.image).to(equal(image))
        
    }
    
}
