import Foundation
import CoreBluetooth

@objc open class HendricksPaymentDeviceConnector: NSObject {
    private var centralManager: CBCentralManager!
    private var wearablePeripheral: CBPeripheral?
    private var _deviceInfo: Device?
    private var paymentDevice: PaymentDevice?

    private let genericServiceId = CBUUID(string: "00001800-0000-1000-8000-00805f9b34fb")
    private let deviceServiceId = CBUUID(string: "7DB2E9EA-ADF6-4F18-A110-61055D64B287")
    
    // in generic service
    private let deviceNameCharacteristicId = CBUUID(string: "00002a00-0000-1000-8000-00805f9b34fb")
    private let appearanceCharacteristicId = CBUUID(string: "00002a01-0000-1000-8000-00805f9b34fb")
    private let preferredParametersCharacteristicId = CBUUID(string: "00002a04-0000-1000-8000-00805f9b34fb")
    private let centralAddressCharacteristicId = CBUUID(string: "00002aa6-0000-1000-8000-00805f9b34fb")
    
    // in device service
    private let statusCharacteristicId = CBUUID(string: "7DB2134A-ADF6-4F18-A110-61055D64B287")
    private let commandCharacteristicId = CBUUID(string: "7DB20256-ADF6-4F18-A110-61055D64B287")
    private let dataCharacteristicId = CBUUID(string: "7DB2E528-ADF6-4F18-A110-61055D64B287")
    private let eventCharacteristicId = CBUUID(string: "7DB2AE05-ADF6-4F18-A110-61055D64B287")
    
    private var expectedDataSize = 0
    private var returnedData: [UInt8] = []
    private var currentCommand: BLECommandPackage?
    private var commandQueue: [BLECommandPackage] = []
    
    private var apduCompletion: ((Error?) -> Void)?
    private var apduCommands: [APDUCommand]?
    
    // MARK: - Lifecycle
    
    @objc public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        super.init()
    }
    
    // MARK: - Public Functions
    
    public func addCommandtoQueue(_ bleCommand: BLECommandPackage) {
        commandQueue.enqueue(bleCommand)
        processNextCommand()
    }
    
    // MARK: - Private Functions
    
    private func runCommand() {
        guard currentCommand == nil else {
            log.error("HENDRICKS: Cannot run command while one is already running")
            return
        }
        
        currentCommand = commandQueue.dequeue()
        
        guard let command = currentCommand else {
            log.debug("HENDRICKS: commandQueue is empty")
            return
        }
        
        guard let wearablePeripheral = wearablePeripheral else { return }
        guard let deviceService = wearablePeripheral.services?.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        guard let statusCharacteristic = deviceService.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let commandCharacteristic = deviceService.characteristics?.filter({ $0.uuid == commandCharacteristicId }).first else { return }
        guard let dataCharacteristic = deviceService.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }
        
        log.debug("HENDRICKS: Running command: \(command.command.rawValue)")
        
        // start
        wearablePeripheral.writeValue(StatusCommand.start.rawValue.data, for: statusCharacteristic, type: .withResponse)
        
        // add data
        var fullCommandData = command.command.rawValue.data
        if let commandData = command.commandData {
            fullCommandData += commandData
        }
        
        log.debug("HENDRICKS: Running full command: \(fullCommandData.hex)")
        wearablePeripheral.writeValue(fullCommandData, for: commandCharacteristic, type: .withResponse)
        
        if let data = command.data {
            log.debug("HENDRICKS: putting data: \(data.hex)")
            wearablePeripheral.writeValue(data, for: dataCharacteristic, type: .withResponse)
        }
        
        // end
        wearablePeripheral.writeValue(StatusCommand.end.rawValue.data, for: statusCharacteristic, type: .withResponse)
    }
    
    private func handlePingResponse() {
        var index = 0
        let device = deviceInfo() ?? Device()
        
        device.deviceName = "Hendricks"
        device.osName = "Hendricks OS"
        device.deviceType = "WATCH"
        device.manufacturerName = "Fitpay"

        while index < expectedDataSize {
            guard returnedData[index] == 0x24 else { return }
            
            let type = PingResponse(rawValue: returnedData[index + 1])
            let length = Int(returnedData[index + 2])
            let nextIndex = index + 3 + length
            let hex = Data(bytes: Array(returnedData[index + 3 ..< nextIndex])).hex
            
            if (type == .serial) {
                device.serialNumber = hex
                
            } else if (type == .version) {
                var version = "v"
                for i in index + 3 ..< nextIndex {
                    version += String(returnedData[i]) + "."
                }
                device.firmwareRevision = String(version.dropLast())
                
            } else if (type == .deviceMode) {
                guard returnedData[index + 3 ..< nextIndex] == [0x02] else { return }

            } else if (type == .bootVersion) {
                device.hardwareRevision = hex
                
            }
            
            index = nextIndex
        }
        
        self._deviceInfo = device
        paymentDevice?.callCompletionForEvent(PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected)
    }
    
    private func handleAPDUResponse() {
        var index = 0
        while index < expectedDataSize {
            let groupId = returnedData[index]
            let sequence = returnedData[index + 1] + returnedData[index + 2] << 8 // shift second bit
            let length = Int(returnedData[index + 4])
            let apduBytes = returnedData[index + 5 ..< index + length + 5]
            index = index + 5 + length
            
            let packet = ApduResultMessage(responseData: Data(bytes: apduBytes))
            
            // update responseData on the appropriate apduCommand
            apduCommands?.first(where: { $0.groupId == groupId && $0.sequence == sequence })?.responseData = packet.responseData
        }
        
        apduCompletion?(nil)
        apduCompletion = nil
        apduCommands = nil
    }
    
    private func resetState() {
        expectedDataSize = 0
        returnedData = []
        currentCommand = nil
        
        processNextCommand()
    }
    
    private func processNextCommand() {
        if currentCommand == nil {
            runCommand()
        }
    }
    
    private func buildAPDUData(apdus: [APDUCommand]) -> Data {
        var data = Data()
        
        for apdu in apdus {
            guard let command = apdu.command else { continue }
            let continueInt: UInt8 = apdu.continueOnFailure ? 0x01 : 0x00

            let groupIdData = UInt8(apdu.groupId).data
            let sequenceData = UInt16(apdu.sequence).data
            let continueData = continueInt.data
            let lengthData = UInt8(command.count / 2).data
            guard let commandData = command.hexToData() else { continue }
            
            let fullCommandData = groupIdData + sequenceData + continueData + lengthData + commandData
            print("\(groupIdData.hex) \(sequenceData.hex) \(continueData.hex) \(lengthData.hex) \(commandData.hex)")
            data.append(fullCommandData)
        }
        
        return data
    }

}

@objc extension HendricksPaymentDeviceConnector: PaymentDeviceConnectable {

    public func connect() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func isConnected() -> Bool {
        return wearablePeripheral?.state == CBPeripheralState.connected
    }
    
    public func validateConnection(completion: @escaping (Bool, NSError?) -> Void) {
        completion(isConnected(), nil)
    }
    
    public func executeAPDUPackage(_ apduPackage: ApduPackage, completion: @escaping (Error?) -> Void) {
        log.debug("HENDRICKS: executeAPDUPackage started")
        guard let apdus = apduPackage.apduCommands else { return }
        
        apduCompletion = completion
        apduCommands = apduPackage.apduCommands
        
        let data = buildAPDUData(apdus: apdus)
        
        var apdusCount = apdus.count
        var dataCount = data.count
        
        let apduCountData = Data(bytes: &apdusCount, count: 2)
        let apduLengthData = Data(bytes: &dataCount, count: 4)

        let commandData = apduCountData + apduLengthData

        let bleCommand = BLECommandPackage(.apduPackage, commandData: commandData, data: data)

        addCommandtoQueue(bleCommand)
    }
    
    public func executeAPDUCommand(_ apduCommand: APDUCommand) {
        log.error("HENDRICKS: Not implemented. using packages instead")
    }
    
    public func deviceInfo() -> Device? {
        return _deviceInfo
    }
    
    public func resetToDefaultState() {
        addCommandtoQueue(BLECommandPackage(.factoryReset))
    }
    
}

@objc extension HendricksPaymentDeviceConnector: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            log.debug("HENDRICKS: central.state is .unknown")
        case .resetting:
            log.debug("HENDRICKS: central.state is .resetting")
        case .unsupported:
            log.debug("HENDRICKS: central.state is .unsupported")
        case .unauthorized:
            log.debug("HENDRICKS: central.state is .unauthorized")
        case .poweredOff:
            log.debug("HENDRICKS: central.state is .poweredOff")
        case .poweredOn:
            log.debug("HENDRICKS: central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [deviceServiceId], options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        log.verbose("HENDRICKS: didDiscover peripheral: \(peripheral)")
        
        wearablePeripheral = peripheral
        wearablePeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log.debug("HENDRICKS: Connected")
        wearablePeripheral?.discoverServices([deviceServiceId])
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log.warning("HENDRICKS: Failed to Connect")
    }
    
}

@objc extension HendricksPaymentDeviceConnector: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        guard let deviceService = services.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        peripheral.discoverCharacteristics(nil, for: deviceService)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let statusCharacteristic = service.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let dataCharacteristic = service.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }

        wearablePeripheral?.writeValue(StatusCommand.abort.rawValue.data, for: statusCharacteristic, type: .withResponse)
        
        peripheral.setNotifyValue(true, for: statusCharacteristic)
        peripheral.setNotifyValue(true, for: dataCharacteristic)

        addCommandtoQueue(BLECommandPackage(.ping))
//        addCommandtoQueue(BLECommandPackage(.factoryReset))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value: [UInt8] = characteristic.value!.bytesArray
        
        switch characteristic.uuid {
            
        case statusCharacteristicId:
            let status = Data(bytes: Array([value[0]]))
            guard status == BLEResponses.ok.rawValue.data else {
                log.error("HENDRICKS: BLE Response Status not OK")
                resetState()
                return
            }
            
            if (value.count == 1) { //status
                log.debug("HENDRICKS: BLE Response OK with no length")
                resetState()
                
            } else if (value.count == 5) { //length
                log.debug("HENDRICKS: BLE Response OK with length")
                let lengthData = Data(bytes: Array(value[1...4])).hex
                expectedDataSize = Int(UInt32(lengthData, radix: 16)!.bigEndian)
                
                returnedData = []
                
                //todo add timeout
                
            } else {
                
            }
            
        case dataCharacteristicId:
            returnedData.append(contentsOf: value)

            if (returnedData.count == expectedDataSize) {
                let hexData = Data(bytes: returnedData).hex
                log.verbose("HENDRICKS: all data received \(hexData)")
                
                if currentCommand?.command == .ping {
                   handlePingResponse()
                } else if currentCommand?.command == .apduPackage {
                    handleAPDUResponse()
                }
                
                resetState()
            }

        default:
            log.warning("HENDRICKS: Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
}

// MARK - Nested Enums

extension HendricksPaymentDeviceConnector {
    
    public enum Command: UInt8 {
        case ping           = 0x01
        case restart        = 0x02
        case bootLoader     = 0x03
        case setDeviceId    = 0x05
        case unsetDeviceId  = 0x06
        case factoryReset   = 0x07
        case sleep          = 0x08
        case lock           = 0x09
        case unlock         = 0x0A
        case heartbeat      = 0x0B

        case assignUser     = 0x10
        case unassignUser   = 0x11
        case getUser        = 0x12
        case addCard        = 0x13
        case addCardCont    = 0x14
        case deleteCard     = 0x15
        case activateCard   = 0x16
        case getCardInfo    = 0x17
        case deactivateCard = 0x18
        case reactivateCard = 0x19
        
        case apduPackage    = 0x20 // + 0xXX - apdu count
    }
    
    enum StatusCommand: UInt8 {
        case start  = 0x01
        case end    = 0x02
        case abort  = 0x03
    }
    
    enum PingResponse: UInt8 {
        case serial         = 0x00
        case version        = 0x01
        case deviceId       = 0x02
        case deviceMode     = 0x03
        case bootVersion    = 0x04
        case ack            = 0x06
    }
    
    enum BLEResponses: UInt8 {
        case ok     = 0x01
        case error  = 0x02
    }
    
    public struct BLECommandPackage {
        var command: Command
        var commandData: Data?
        var data: Data?
        
        public init(_ command: Command, commandData: Data? = nil, data: Data? = nil) {
            self.command = command
            self.commandData = commandData
            self.data = data
        }
        
    }

}
