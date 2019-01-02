import Foundation

public enum ImageAssetOption {
    case width(Int)
    case height(Int)
    case embossedText(String)
    case embossedForegroundColor(String)
    case fontScale(Int)
    case textPositionXScale(Float)
    case textPositionYScale(Float)
    case fontName(String)
    case fontBold(Bool)
    case roundedCorners(Bool)
    
    public var urlKey: String {
        switch self {
        case .width:
            return "w"
        case .height:
            return "h"
        case .embossedText:
            return "embossedText"
        case .embossedForegroundColor:
            return "embossedForegroundColor"
        case .fontScale:
            return "fs"
        case .textPositionXScale:
            return "txs"
        case .textPositionYScale:
            return "tys"
        case .fontName:
            return "fn"
        case .fontBold:
            return "fb"
        case .roundedCorners:
            return "rc"
        }
    }
    
    public var urlValue: String {
        switch self {
        case .width(let value),
             .height(let value),
             .fontScale(let value):
            return String(value)
            
        case .embossedText(let value),
             .embossedForegroundColor(let value),
             .fontName(let value):
            return value
            
        case .textPositionXScale(let value),
             .textPositionYScale(let value):
            return String(value)
            
        case .fontBold(let value),
             .roundedCorners(let value):
            return String(value)
        }
    }
}
