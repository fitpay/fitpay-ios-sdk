import Foundation

public class HendricksCard: HendricksObject {
    
    var creditCard: CreditCard?
    
    init(creditCard: CreditCard) {
        super.init()
        self.creditCard = creditCard
    }
    
    public func getCreditCardData(completion: @escaping (_ commandData: Data, _ data: Data) -> Void) {
        guard let creditCard = creditCard else { return }
        
        processCreditCardImage(creditCard) { (cardArtData) in
            
            // data
            let lastFour = creditCard.info?.pan?.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            guard let lastFourData = lastFour?.data(using: .utf8)?.paddedTo(byteLength: 5) else { return }
            
            let exp = String(format: "%02d", creditCard.info!.expMonth!) + "/" + String(creditCard.info!.expYear!).dropFirst(2)
            guard let expData = exp.data(using: .utf8)?.paddedTo(byteLength: 6) else { return }
            
            guard let financialServiceData =  creditCard.cardType!.data(using: .utf8)?.paddedTo(byteLength: 21) else { return }
            guard let cardIdData = creditCard.creditCardId?.data(using: .utf8)?.paddedTo(byteLength: 37) else { return }
            
            var cardArtId = 0
            let cardArtIdData = Data(bytes: &cardArtId, count: 2)
            
            var towId = 0
            let towIdData = Data(bytes: &towId, count: 2)
            
            // card status
            let cardStatusData = UInt8(0x07).data // TODO: map correct card status
            
            let towApduData = creditCard.topOfWalletAPDUCommands != nil ? HendricksUtils.buildAPDUData(apdus: creditCard.topOfWalletAPDUCommands!) : Data()
            var towSize = towApduData.count
            let towSizeData = Data(bytes: &towSize, count: 4)
            
            var cardArtSize = cardArtData.count
            let cardArtSizeData = Data(bytes: &cardArtSize, count: 4)
            
            //split for compiler
            let dataFirstHalf = lastFourData + expData + financialServiceData + cardIdData + cardArtIdData
            let dataSecondHalf = cardArtSizeData + towIdData + towSizeData + cardStatusData + cardArtData + towApduData
            let data = dataFirstHalf + dataSecondHalf
            
            // command data
            var metaSize = 82
            let metaSizeData = Data(bytes: &metaSize, count: 4)
            
            let commandData = cardIdData + metaSizeData + cardArtSizeData + towSizeData
            
            completion(commandData, data)
        }
    }
    
    // MARK: - Private Functions
    
    private func processCreditCardImage(_ creditCard: FitpaySDK.CreditCard, completion: @escaping (_ data: Data) -> Void) {
        let defaultCardWidth = 200
        let defaultCardHeight = 125
        let cardImage = creditCard.cardMetaData?.cardBackgroundCombined?.first
        
        cardImage?.retrieveAssetWith(options: [ImageAssetOption.width(defaultCardWidth), ImageAssetOption.height(defaultCardHeight)]) { (asset, _) in
            guard let image = asset?.image else {
                completion(Data())
                return
            }
            let pixelData = image.pixelData()!
            
            // determine if there is tranparency
            var transparency = false
            
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
                let r = UInt16(pixelData[i])
                let g = UInt16(pixelData[i + 1])
                let b = UInt16(pixelData[i + 2])
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
            
            completion(imageHeader + mainData)
        }
    }

    
}

