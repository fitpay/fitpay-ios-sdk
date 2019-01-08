import Foundation

open class HendricksObject {
    public var categoryId: Int?
    public var objectId: Int?
    public var data: [UInt8] = []
    
    public init() {
        
    }
    
    public init(categoryId: Int, objectId: Int, data: [UInt8] = []) {
        self.categoryId = categoryId
        self.objectId = objectId
        self.data = data
    }
    
}

enum HendricksObjectType: Int {
    case error
    case identity
    case card
    case miscellaneous
    case image
    case favorite
}
