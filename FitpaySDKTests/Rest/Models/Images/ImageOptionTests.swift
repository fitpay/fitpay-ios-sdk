import XCTest
import Nimble

@testable import FitpaySDK

class ImageAssetOptionTests: XCTestCase {
    
    func testEmbossedForegroundColor() {
        let testOption = ImageAssetOption.embossedForegroundColor("color")
        expect(testOption.urlKey).to(equal("embossedForegroundColor"))
        expect(testOption.urlValue).to(equal("color"))
    }
    
    func testEmbossedText() {
        let testOption = ImageAssetOption.embossedText("text")
        expect(testOption.urlKey).to(equal("embossedText"))
        expect(testOption.urlValue).to(equal("text"))
    }
    
    func testFontBold() {
        let testOption = ImageAssetOption.fontBold(true)
        expect(testOption.urlKey).to(equal("fb"))
        expect(testOption.urlValue).to(equal("true"))
    }
    
    func testFontName() {
        let testOption = ImageAssetOption.fontName("helvetica")
        expect(testOption.urlKey).to(equal("fn"))
        expect(testOption.urlValue).to(equal("helvetica"))
    }
    
    func testFontScale() {
        let testOption = ImageAssetOption.fontScale(12)
        expect(testOption.urlKey).to(equal("fs"))
        expect(testOption.urlValue).to(equal("12"))
    }
    
    func testHeight() {
        let testOption = ImageAssetOption.height(30)
        expect(testOption.urlKey).to(equal("h"))
        expect(testOption.urlValue).to(equal("30"))
    }
    
    func testTextPositionXScale() {
        let testOption = ImageAssetOption.textPositionXScale(1.2)
        expect(testOption.urlKey).to(equal("txs"))
        expect(testOption.urlValue).to(equal("1.2"))
    }
    
    func testTextPositionYScale() {
        let testOption = ImageAssetOption.textPositionYScale(1.3)
        expect(testOption.urlKey).to(equal("tys"))
        expect(testOption.urlValue).to(equal("1.3"))
    }
    
    func testWidth() {
        let testOption = ImageAssetOption.width(20)
        expect(testOption.urlKey).to(equal("w"))
        expect(testOption.urlValue).to(equal("20"))
    }

}
