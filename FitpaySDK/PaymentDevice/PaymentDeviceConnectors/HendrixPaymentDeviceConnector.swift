import Foundation
import CoreBluetooth

@objc open class HendrixPaymentDeviceConnector: NSObject {
    private var centralManager: CBCentralManager!
    private var wearablePeripheral: CBPeripheral?
    private var deviceInfo: DeviceInfo?

    private let genericService = CBUUID(string: "00001800-0000-1000-8000-00805f9b34fb")
    private let deviceService = CBUUID(string: "7DB2E9EA-ADF6-4F18-A110-61055D64B287")
    
    // in generic service
    private let deviceNameCharacteristic = CBUUID(string: "00002a00-0000-1000-8000-00805f9b34fb")
    private let appearanceCharacteristic = CBUUID(string: "00002a01-0000-1000-8000-00805f9b34fb")
    private let preferredParametersCharacteristic = CBUUID(string: "00002a04-0000-1000-8000-00805f9b34fb")
    private let centralAddressCharacteristic = CBUUID(string: "00002aa6-0000-1000-8000-00805f9b34fb")

    
    // in device service
    private let statusCharacteristic = CBUUID(string: "7DB2134A-ADF6-4F18-A110-61055D64B287")
    private let commandCharacteristic = CBUUID(string: "7DB20256-ADF6-4F18-A110-61055D64B287")
    private let dataCharacteristic = CBUUID(string: "7DB2E528-ADF6-4F18-A110-61055D64B287")
    private let eventCharacteristic = CBUUID(string: "7DB2AE05-ADF6-4F18-A110-61055D64B287")
    
}

@objc extension HendrixPaymentDeviceConnector: PaymentDeviceConnectable {


    @objc open func connect() {
        print("connect called")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @objc open var isConnected: Bool {
        return wearablePeripheral?.state == CBPeripheralState.connected
    }
    
    @objc open func executeAPDUCommand(_ apduCommand: APDUCommand) {
        
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
            centralManager.scanForPeripherals(withServices: [deviceService], options: nil)
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
        wearablePeripheral?.discoverServices([deviceService])
    }
    
}

@objc extension HendrixPaymentDeviceConnector: CBPeripheralDelegate {

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("didDiscoverServices: \(service)")
            
            if service.uuid == deviceService {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}

