import Foundation
import CoreBluetooth

@objc open class HendrixPaymentDeviceConnector: NSObject {
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
    private var lastCommand: Command?
    
    // MARK: - Lifecycle
    
    @objc public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        super.init()
    }
    
    // MARK: - Private Functions
    
    private func runCommand(_ command: Command, data: Data? = nil) {
        lastCommand = command
        
        guard let wearablePeripheral = wearablePeripheral else { return }
        guard let deviceService = wearablePeripheral.services?.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        guard let statusCharacteristic = deviceService.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let commandCharacteristic = deviceService.characteristics?.filter({ $0.uuid == commandCharacteristicId }).first else { return }
        guard let dataCharacteristic = deviceService.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }
        
        wearablePeripheral.writeValue(StatusCommand.abort.rawValue.data, for: statusCharacteristic, type: .withResponse)
        wearablePeripheral.writeValue(StatusCommand.start.rawValue.data, for: statusCharacteristic, type: .withResponse)
        wearablePeripheral.writeValue(command.rawValue.data, for: commandCharacteristic, type: .withResponse)
        
        if let data = data {
            wearablePeripheral.writeValue(data, for: dataCharacteristic, type: .withResponse)
        }
        
        wearablePeripheral.writeValue(StatusCommand.end.rawValue.data, for: statusCharacteristic, type: .withResponse)
    }
    
    private func handlePingResponse() {
        var index = 0
        let device = deviceInfo() ?? Device()
        
        device.deviceName = "Hendrix"
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
                
            } else if (type == .deviceId) { // assign anywhere?
                //device.deviceIdentifier = hex
                
            } else if (type == .deviceMode) {
                guard returnedData[index + 3 ..< nextIndex] == [0x02] else { return }

            } else if (type == .bootVersion) { // looks to have been removed
                device.hardwareRevision = hex
                
            }
            
            index = nextIndex
        }
        
        self._deviceInfo = device
        paymentDevice?.callCompletionForEvent(PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected)
        
        resetClassVariables()
    }
    
    private func resetClassVariables() {
        expectedDataSize = 0
        returnedData = []
        lastCommand = nil
    }
    
}

@objc extension HendrixPaymentDeviceConnector: PaymentDeviceConnectable {

    @objc open func connect() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @objc open func isConnected() -> Bool {
        return wearablePeripheral?.state == CBPeripheralState.connected
    }
    
    public func validateConnection(completion: @escaping (Bool, NSError?) -> Void) {
        completion(isConnected(), nil)
    }
    
    @objc open func executeAPDUCommand(_ apduCommand: APDUCommand) {
        print("executeAPDUCommand \(apduCommand)")
        // TODO: implement
    }
    
    @objc open func deviceInfo() -> Device? {
        return _deviceInfo
    }
    
    @objc open func resetToDefaultState() {
        //what to do here
    }
    
}

@objc extension HendrixPaymentDeviceConnector: CBCentralManagerDelegate {
    
    @objc open func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [deviceServiceId], options: nil)
        }
    }
    
    @objc open func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("didDiscover peripheral: \(peripheral)")
        
        wearablePeripheral = peripheral
        wearablePeripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    @objc open func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        wearablePeripheral?.discoverServices([deviceServiceId])
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("connection failed")
    }
    
}

@objc extension HendrixPaymentDeviceConnector: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        guard let deviceService = services.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        peripheral.discoverCharacteristics(nil, for: deviceService)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        guard let statusCharacteristic = service.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let dataCharacteristic = service.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }

        peripheral.setNotifyValue(true, for: statusCharacteristic)
        peripheral.setNotifyValue(true, for: dataCharacteristic)

//        runCommand(.ping)
        let data = createName(firstName: "Jeremiah", middleName: "B", lastName: "Harris")
//        runCommand(.unassignUser)
//        runCommand(.factoryReset)
        runCommand(.assignUser, data: data)
    
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value: [UInt8] = characteristic.value!.bytesArray
        
        switch characteristic.uuid {
            
        case statusCharacteristicId:
            if (value.count == 1) { //status
                let status = Data(bytes: value).hex
                if (status == "01") {
                    print("success")
                } else {
                    print("error1")
                }
                
            } else if (value.count == 5) { //length
                let status = Data(bytes: Array([value[0]])).hex
                if (status != "01") {
                    print("error2")
                    return
                }
                
                let lengthData = Data(bytes: Array(value[1...4])).hex
                expectedDataSize = Int(lengthData, radix: 16)!
                returnedData = []
            }
            
        case dataCharacteristicId:
            returnedData.append(contentsOf: value)

            if (returnedData.count == expectedDataSize) {
                let hexData = Data(bytes: returnedData).hex
                print("all data received \(hexData)")
                
                if (lastCommand == .ping) {
                   handlePingResponse()
                } else if lastCommand == .assignUser {
                    print("maybeworked")
                }

            }

        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
}

// MARK - Temporary Location

extension HendrixPaymentDeviceConnector {
    
    func createName(firstName: String, middleName: String, lastName: String) -> Data {
        var firstNameData = firstName.prefix(21).data(using: .utf8) ?? Data()
        var middleNameData = middleName.prefix(21).data(using: .utf8) ?? Data()
        var lastNameData = lastName.prefix(21).data(using: .utf8) ?? Data()

        while firstNameData.count < 21 {
            firstNameData.append(0x00)
        }
        
        while middleNameData.count < 21 {
            middleNameData.append(0x00)
        }
        
        while lastNameData.count < 21 {
            lastNameData.append(0x00)
        }
        
        return firstNameData + middleNameData + lastNameData
        
    }
}

// MARK - Nested Enums

extension HendrixPaymentDeviceConnector {
    
    enum Command: UInt8 {
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
}


