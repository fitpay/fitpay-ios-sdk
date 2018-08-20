import Foundation
import CoreBluetooth

enum HendrixCommand: UInt8 {
    case ping = 0x01
}

enum HendrixPingResponse: UInt8 {
    case serial = 0x00
    case version = 0x01
    case deviceId = 0x02
    case deviceMode = 0x03
    case bootVersion = 0x04
    case ack = 0x06
}

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
    private var lastCommand: HendrixCommand?
    
    // MARK: - Lifecycle
    
    @objc public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        super.init()
    }
    
    // MARK: - Private Functions
    private func runCommand(_ command: HendrixCommand) {
        lastCommand = command
        
        guard let wearablePeripheral = wearablePeripheral else { return }
        guard let deviceService = wearablePeripheral.services?.filter({ $0.uuid == deviceServiceId }).first else { return }
        
        guard let statusCharacteristic = deviceService.characteristics?.filter({ $0.uuid == statusCharacteristicId }).first else { return }
        guard let commandCharacteristic = deviceService.characteristics?.filter({ $0.uuid == commandCharacteristicId }).first else { return }
        guard let dataCharacteristic = deviceService.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }
        
        wearablePeripheral.writeValue("03".hexToData()!, for: statusCharacteristic, type: .withResponse)
        wearablePeripheral.writeValue("01".hexToData()!, for: statusCharacteristic, type: .withResponse)
        wearablePeripheral.writeValue(command.rawValue.data, for: commandCharacteristic, type: .withResponse)
        wearablePeripheral.writeValue("02".hexToData()!, for: statusCharacteristic, type: .withResponse)
    }
    
    private func handlePingResponse() {
        var index = 0
        let device = deviceInfo()! // hashbang?
        
        device.deviceName = "Hendrix"
        device.deviceType = "ACTIVITY_TRACKER"
        device.manufacturerName = "Fitpay"

        while index < expectedDataSize {
            guard returnedData[index] == 0x24 else { return }
            
            let type = HendrixPingResponse(rawValue: returnedData[index + 1])
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
                
            } else if (type == .deviceId) {
                device.deviceIdentifier = hex
                
            } else if (type == .deviceMode) {
                guard returnedData[index + 3 ..< nextIndex] == [0x02] else { return }

            } else if (type == .bootVersion) {
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
    
    @objc open var isConnected: Bool {
        return wearablePeripheral?.state == CBPeripheralState.connected
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
        print("didDiscover perifpheral: \(peripheral)")
        
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

        runCommand(.ping)
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value: [UInt8] = characteristic.value!.bytesArray
        
        switch characteristic.uuid {
            
        case statusCharacteristicId:
            if (value.count == 1) { //status
                let status = Data(bytes: value).hex
                if (status == "01") {
                    //success
                } else {
                    //error
                }
                
            } else if (value.count == 5) { //length
                let status = Data(bytes: Array([value[0]])).hex
                if (status != "01") {
                    //error
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
                }

            }

        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
}


