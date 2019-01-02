import Foundation

public class HendricksCard: HendricksObject {
    
    public var cardId: String
    
    var lastFour: String
    var expDate: String
    var type: String
    var cardArtId = 0
    var towId = 0
    var cardStatus = 0x07
    
    var artSize: Int?
    var towSize: Int?
    
    private var creditCard: CreditCard?
    
    private let lastFourLength = 5
    private let expDateLength = 6
    private let typeLength = 21
    private let cardIdLength = 37
    private let artIdLength = 2
    private let artIdSizeLength = 4
    private let towIdLength = 2
    private let towSizeLength = 4
    private let statusLength = 1
    private let paddingLength: Int //2
    private let metaSizeLength: Int //84
    
    public init(creditCard: CreditCard) {
        self.creditCard = creditCard
        
        lastFour = creditCard.info!.pan!.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        expDate = String(format: "%02d", creditCard.info!.expMonth ?? 00) + "/" + String(creditCard.info!.expYear ?? 0000).dropFirst(2)
        type = creditCard.cardType!
        cardId = creditCard.creditCardId!
        
        paddingLength = 4 - ((lastFourLength + expDateLength + typeLength + cardIdLength + artIdLength + artIdSizeLength + towIdLength + towSizeLength + statusLength) % 4)
        metaSizeLength = lastFourLength + expDateLength + typeLength + cardIdLength + artIdLength + artIdSizeLength + towIdLength + towSizeLength + statusLength + paddingLength
        
        super.init()
        
    }
    
    init(categoryId: Int, objectId: Int, returnedData: [UInt8], index: Int) {
        var runningIndex = index
        
        lastFour = String(bytes: Array(returnedData[runningIndex..<runningIndex + lastFourLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        runningIndex += lastFourLength
        expDate = String(bytes: Array(returnedData[runningIndex..<runningIndex + expDateLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        runningIndex += expDateLength
        type = String(bytes: Array(returnedData[runningIndex..<runningIndex + typeLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        runningIndex += typeLength
        cardId = String(bytes: Array(returnedData[runningIndex..<runningIndex + cardIdLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        runningIndex += cardIdLength
        
        paddingLength = 4 - ((lastFourLength + expDateLength + typeLength + cardIdLength + artIdLength + artIdSizeLength + towIdLength + towSizeLength + statusLength) % 4)
        metaSizeLength = lastFourLength + expDateLength + typeLength + cardIdLength + artIdLength + artIdSizeLength + towIdLength + towSizeLength + statusLength + paddingLength
        
        super.init()
        
        self.categoryId = categoryId
        self.objectId = objectId
        
    }
    
    public func getCreditCardData(completion: @escaping (_ commandData: Data, _ data: Data) -> Void) {
        guard let creditCard = creditCard else { return }
        
        processCreditCardImage(creditCard) { (cardArtData) in
            
            // data
            guard let lastFourData = self.lastFour.data(using: .utf8)?.paddedTo(byteLength: self.lastFourLength) else { return }
            guard let expData = self.expDate.data(using: .utf8)?.paddedTo(byteLength: self.expDateLength) else { return }
            guard let financialServiceData = self.type.data(using: .utf8)?.paddedTo(byteLength: self.typeLength) else { return }
            guard let cardIdData = self.cardId.data(using: .utf8)?.paddedTo(byteLength: self.cardIdLength) else { return }
            
            var tempCardArtId = self.cardArtId
            let cardArtIdData = Data(bytes: &tempCardArtId, count: 2)
            
            var tempTowId = self.towId
            let towIdData = Data(bytes: &tempTowId, count: 2)
            
            // card status
            let cardStatusData = UInt8(self.cardStatus).data
            
            var padding = 0
            let paddingData = Data(bytes: &padding, count: 2)
            
            var cardArtSize = cardArtData.count
            let cardArtSizeData = Data(bytes: &cardArtSize, count: 4)
            
            let towApduData = creditCard.topOfWalletAPDUCommands != nil ? HendricksUtils.buildTOWAPDUData(apdus: creditCard.topOfWalletAPDUCommands!) : Data()
            var towSize = towApduData.count
            let towSizeData = Data(bytes: &towSize, count: 4)
            
            //split for compiler
            let dataFirstHalf = lastFourData + expData + financialServiceData + cardIdData + cardArtIdData
            let dataSecondHalf = cardArtSizeData + towIdData + towSizeData + cardStatusData + paddingData
            let dataSection = cardArtData + towApduData
            let data = dataFirstHalf + dataSecondHalf + dataSection
            
            // command data
            var tempMetaSize = self.metaSizeLength
            let metaSizeData = Data(bytes: &tempMetaSize, count: 4)
            
            let commandData = cardIdData + metaSizeData + cardArtSizeData + towSizeData
            
            completion(commandData, data)
        }
    }
    
    // MARK: - Private Functions
    
    private func processCreditCardImage(_ creditCard: FitpaySDK.CreditCard, completion: @escaping (_ data: Data) -> Void) {
        let defaultCardWidth = 200
        let defaultCardHeight = 126
        guard let cardImage = creditCard.cardMetaData?.cardBackgroundCombined?.first else {
            completion(processPixelData(image: UIImage(named: "mastercard")!))
            return
        }
        
        cardImage.retrieveAssetWith(options: [ImageAssetOption.width(defaultCardWidth), ImageAssetOption.height(defaultCardHeight), ImageAssetOption.fontScale(20), ImageAssetOption.fontBold(false)]) { (asset, _) in
            guard let image = asset?.image ?? UIImage(named: "mastercard") else {
                completion(Data())
                return
            }
            
            completion(self.processPixelData(image: image))
        }
    }
    
    private func processPixelData(image: UIImage) -> Data {
        let pixelData = image.pixelData()!
        
        // determine if there is tranparency
        var transparency = true // false - no transparency currently not working
        
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let a = pixelData[i + 3]
            if a < 255 {
                transparency = true
                break
            }
        }
        
        // create main data
        var previousColor: (color: UInt16, alpha: UInt16)?
        var mainData = Data()
        var pixelCounter: UInt16 = 0
        let maxPixelCount = transparency ? 15 : 255
        
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = UInt16(pixelData[i]) & 0xF0
            let g = UInt16(pixelData[i + 1]) & 0xF0
            let b = UInt16(pixelData[i + 2]) & 0xF0
            let a = UInt16(pixelData[i + 3])
            
            let red =   ((31 * (r + 4)) / 255)
            let green = ((63 * (g + 2)) / 255)
            let blue =  ((31 * (b + 4)) / 255)
            let alpha = (((15 * (a + 8)) / 255) & 0x0F)
            
            var color: UInt16 = (red << 11) | (green << 5) | blue
            
            if i == 0 { // handle first case differently
                previousColor = (color: color, alpha: alpha)
            } else {
                pixelCounter += 1
            }
            
            if alpha == 0 { // if fully transparent wipe color
                color = 0
            }
            
            let lastPixel = i + 4 == pixelData.count
            
            if (color: color, alpha: alpha) != previousColor! || pixelCounter >= maxPixelCount || lastPixel {
                if !lastPixel {
                    pixelCounter -= 1
                }
                
                if transparency {
                    let pixelPlusAlpha: UInt8 = (UInt8(pixelCounter) << 4) | (UInt8(previousColor!.alpha))
                    mainData += pixelPlusAlpha.data + previousColor!.color.data
                    
                } else {
                    mainData += pixelCounter.data + previousColor!.color.data
                }
                
                pixelCounter = 0
            }
            
            previousColor = (color: color, alpha: alpha)
            
        }
        
        // header
        let imageVersion: UInt8 = 0x41
        let imageMode: UInt8 = transparency ? 0x01 : 0x00
        var width = Int(image.size.width)
        let widthData = Data(bytes: &width, count: 2)
        var height = Int(image.size.height)
        let heightData = Data(bytes: &height, count: 2)
        
        var mainDataSize = mainData.count
        let mainDataSizeData = Data(bytes: &mainDataSize, count: 2)
        
        let imageHeader = imageVersion.data + imageMode.data + widthData + heightData + mainDataSizeData
        
        return imageHeader + mainData
    }

}
