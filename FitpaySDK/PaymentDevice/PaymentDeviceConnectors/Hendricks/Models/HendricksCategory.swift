import Foundation

public class HendricksCategory {
    
    public var categoryId: Int
    public var categoryUid: Int
    public var title: String
    public var objects: [HendricksObject] = []
    
    init(_ returnedData: [UInt8], index: Int) {
        categoryId = Int(returnedData[index] + returnedData[index + 1] << 8)
        categoryUid =  Int(returnedData[index + 2] + returnedData[index + 3] << 8)
        title = String(bytes: Array(returnedData[index + 4..<index + 4 + 11]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        let count = Int(returnedData[index + 15])
        
        //get objects
        var runningIndex = index + 16
        for _ in 0..<count {
            let objectId = Int(returnedData[runningIndex] + returnedData[runningIndex + 1] << 8)
            runningIndex += 2
            let object = HendricksObject(categoryId: categoryId, obectjId: objectId)
            objects.append(object)
        }
    }

}
