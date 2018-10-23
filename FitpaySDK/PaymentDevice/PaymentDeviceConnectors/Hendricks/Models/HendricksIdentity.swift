import Foundation

public class HendricksIdentity: HendricksObject {
    
    public var firstName: String?
    public var middleName: String?
    public var lastName: String?
    
    let totalLength = 63
    private let nameLength = 21
    
    public init(firstName: String?, middleName: String?, lastName: String?) {
        super.init()
        
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
    }
    
    init(categoryId: Int, objectId: Int, returnedData: [UInt8], index: Int) {
        super.init()
        
        self.categoryId = categoryId
        self.objectId = objectId
        
        var runningIndex = index
        firstName = String(bytes: Array(returnedData[runningIndex..<runningIndex + nameLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        runningIndex += nameLength
        middleName = String(bytes: Array(returnedData[runningIndex..<runningIndex + nameLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
        runningIndex += nameLength
        lastName = String(bytes: Array(returnedData[runningIndex..<runningIndex + nameLength]), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")

    }
    
    public func getData() -> Data {
        var firstNameData = firstName?.prefix(21).data(using: .utf8) ?? Data()
        var middleNameData = middleName?.prefix(21).data(using: .utf8) ?? Data()
        var lastNameData = lastName?.prefix(21).data(using: .utf8) ?? Data()
        
        while firstNameData.count < nameLength {
            firstNameData.append(0x00)
        }
        
        while middleNameData.count < nameLength {
            middleNameData.append(0x00)
        }
        
        while lastNameData.count < nameLength {
            lastNameData.append(0x00)
        }
        
        return firstNameData + middleNameData + lastNameData
    }
}
