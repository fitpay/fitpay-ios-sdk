import Foundation

open class HendricksObject {
    public var categoryId: Int?
    public var objectId: Int?
    
    public init() {
        
    }
    
    init(categoryId: Int, obectjId: Int) {
        self.categoryId = categoryId
        self.objectId = obectjId
    }
    
}

enum HendricksObjectType: Int {
    case error
    case identity
    case card
    case miscellaneous
    case image
}
