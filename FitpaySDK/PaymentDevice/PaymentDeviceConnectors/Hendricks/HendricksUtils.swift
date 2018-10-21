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
    
    static func buildTOWAPDUData(apdus: [APDUCommand]) -> Data {
        var data = Data()
        
        guard let aidCommand = apdus.first(where: { $0.command?.uppercased().starts(with: "80F00202") == true }) else {
            return buildAPDUData(apdus: apdus)
        }
        
        let selectCRS = APDUCommand()
        selectCRS.groupId = 0
        selectCRS.sequence = 0
        selectCRS.command = "00A4040009A00000015143525300"
        selectCRS.type = "SELECT_CRS"
        selectCRS.continueOnFailure = false
        
        let deactivateDefaultAID = APDUCommand()
        selectCRS.groupId = 0
        selectCRS.sequence = 1
        selectCRS.command = "80C3010000"
        selectCRS.type = "DEACTIVATE_DEFAULT_CARD"
        selectCRS.continueOnFailure = true
        
        let lowerBound = aidCommand.command!.index(aidCommand.command!.startIndex, offsetBy: 12)
        let aid = String(aidCommand.command![lowerBound...])

        let setDefaultAID = APDUCommand()
        selectCRS.groupId = 0
        selectCRS.sequence = 2
        selectCRS.command = "80C3010000" + aid
        selectCRS.type = "SET_DEFAULT_CARD"
        selectCRS.continueOnFailure = false
        
        let activateDefaultAID = APDUCommand()
        selectCRS.groupId = 0
        selectCRS.sequence = 3
        selectCRS.command = "80C3010100"
        selectCRS.type = "ACTIVATE_DEFAULT_CARD"
        selectCRS.continueOnFailure = false
        
        let translatedAPDUs = [selectCRS, deactivateDefaultAID, setDefaultAID, activateDefaultAID]
        return buildAPDUData(apdus: translatedAPDUs)
    }
    
}
