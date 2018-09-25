import XCTest
import Nimble

@testable import FitpaySDK

class UIImageExtensionsTests: XCTestCase {
    
    func testPixelData() {
        let image = setupImage()
        guard let pixelData = image?.pixelData() else {
            fail()
            return
        }
        
        expect(pixelData.isEmpty).to(beFalse())
        
        var transparentPixel = false
        var grayPixel = false
        var redPixel = false
        var semiTransparent = false
        
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = pixelData[i]
            let g = pixelData[i + 1]
            let b = pixelData[i + 2]
            let a = pixelData[i + 3]
            
            if r == 0 && g == 0 && b == 0 && a == 0 {
                transparentPixel = true
            } else if r == 64 && g == 64 && b == 65 && a == 255 {
                grayPixel = true
            } else if r == 238 && g == 49 && b == 36 && a == 255 {
                redPixel = true
            } else if r == 32 && g == 32 && b == 33 && a == 128 {
                semiTransparent = true
            }

        }
        
        expect(transparentPixel).to(beTrue())
        expect(grayPixel).to(beTrue())
        expect(redPixel).to(beTrue())
        expect(semiTransparent).to(beTrue())

    }
    
    // MARK: - Private Functions
    
    private func setupImage() -> UIImage? {
        let t = type(of: self)
        let bundle = Bundle(for: t.self)
        
        guard let path = bundle.path(forResource: "fitpay-logo", ofType: "png") else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else { return nil }
        guard let image = UIImage(data: data) else { return nil }
        
        return image
    }
    
}
