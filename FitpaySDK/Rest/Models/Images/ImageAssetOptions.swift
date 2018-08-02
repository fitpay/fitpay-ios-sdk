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
        }
    }
    
    public var urlValue: String {
        switch self {
        case .width(let value):
            return String(value)
        case .height(let value):
            return String(value)
        case .embossedText(let value):
            return value
        case .embossedForegroundColor(let value):
            return value
        case .fontScale(let value):
            return String(value)
        case .textPositionXScale(let value):
            return String(value)
        case .textPositionYScale(let value):
            return String(value)
        case .fontName(let value):
            return value
        case .fontBold(let value):
            return String(value)
        }
    }
}
