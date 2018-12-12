import Foundation

public class HendricksFavorite: HendricksObject {
    
    public var favoriteCategoryId: Int
    public var favoriteObjectId: Int
    
    let totalLength = 7

    init(categoryId: Int, objectId: Int, returnedData: [UInt8], index: Int) {
        favoriteCategoryId = Int(returnedData[index] + returnedData[index + 1] << 8)
        favoriteObjectId = Int(returnedData[index + 2] + returnedData[index + 3] << 8)
        
        super.init(categoryId: categoryId, objectId: objectId)
    }
    
}
