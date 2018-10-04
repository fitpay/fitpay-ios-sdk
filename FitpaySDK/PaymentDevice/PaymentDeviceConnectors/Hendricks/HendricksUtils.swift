import Foundation

struct HendricksUtils {
    
    static func buildAPDUData(apdus: [APDUCommand]) -> Data {
        var data = Data()
        
        for apdu in apdus {
            guard let command = apdu.command else { continue }
            guard let commandData = command.hexToData() else { continue }
            
            let continueInt: UInt8 = apdu.continueOnFailure ? 0x01 : 0x00
            
            let groupIdData = UInt8(apdu.groupId).data
            let sequenceData = UInt16(apdu.sequence).data
            let continueData = continueInt.data
            let lengthData = UInt8(command.count / 2).data
            
            let fullCommandData = groupIdData + sequenceData + continueData + lengthData + commandData
            
            data.append(fullCommandData)
        }
        
        return data
    }
    
}
