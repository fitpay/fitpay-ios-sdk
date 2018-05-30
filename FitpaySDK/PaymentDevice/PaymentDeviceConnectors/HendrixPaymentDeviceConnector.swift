import Foundation
import CoreBluetooth

@objc open class HendrixPaymentDeviceConnector: NSObject {
    private var centralManager: CBCentralManager!
    private var wearablePeripheral: CBPeripheral?
    private var deviceInfo: DeviceInfo?
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
    
    var expectedDataSize = 0
    var returnedData: [UInt8] = []

    // MARK: - Lifecycle
    
    @objc public init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
        super.init()
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
    
    @objc open func getDeviceInfo() -> DeviceInfo? {
        return deviceInfo
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
        
        paymentDevice?.callCompletionForEvent(PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected)
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
        guard let commandCharacteristic = service.characteristics?.filter({ $0.uuid == commandCharacteristicId }).first else { return }
        guard let dataCharacteristic = service.characteristics?.filter({ $0.uuid == dataCharacteristicId }).first else { return }

        peripheral.setNotifyValue(true, for: statusCharacteristic)
        peripheral.setNotifyValue(true, for: dataCharacteristic)

        //reset, start, version, stop
        peripheral.writeValue("03".hexToData()!, for: statusCharacteristic, type: .withResponse)
        peripheral.writeValue("01".hexToData()!, for: statusCharacteristic, type: .withResponse)
        peripheral.writeValue("01".hexToData()!, for: commandCharacteristic, type: .withResponse)
        peripheral.writeValue("02".hexToData()!, for: statusCharacteristic, type: .withResponse)
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value: [UInt8] = characteristic.value!.bytesArray
        
        switch characteristic.uuid {
            
        case statusCharacteristicId:
            if (value.count == 1) {
                let status = Data(bytes: value).hex
                if (status == "01") {
                    //success
                } else {
                    //error
                }
                
            } else if (value.count == 5) {
                let status = Data(bytes: Array([value[0]])).hex
                if (status != "01") {
                    //error
                    return
                }
                
                let lengthData = Data(bytes: Array(value[1...4])).hex
                expectedDataSize = Int(lengthData, radix: 16)!
                returnedData = []
                
                print("size: \( Int(lengthData, radix: 16)!)")
            }
            
        case dataCharacteristicId:
            returnedData.append(contentsOf: value)

            if (returnedData.count == expectedDataSize) {
                let hexData = Data(bytes: returnedData).hex
                print("all data received \(hexData)")
            }

        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
}


