import CoreBluetooth

class BLEDeviceInfoCollector {
    static let characteristicBindings: [CBUUID: String] = [
        PAYMENT_CHARACTERISTIC_UUID_MANUFACTURER_NAME: "manufacturerName",
        PAYMENT_CHARACTERISTIC_UUID_MODEL_NUMBER: "modelNumber",
        PAYMENT_CHARACTERISTIC_UUID_SERIAL_NUMBER: "serialNumber",
        PAYMENT_CHARACTERISTIC_UUID_FIRMWARE_REVISION: "firmwareRevision",
        PAYMENT_CHARACTERISTIC_UUID_HARDWARE_REVISION: "hardwareRevision",
        PAYMENT_CHARACTERISTIC_UUID_SOFTWARE_REVISION: "softwareRevision",
        PAYMENT_CHARACTERISTIC_UUID_SYSTEM_ID: "systemId",
        PAYMENT_CHARACTERISTIC_UUID_SECURE_ELEMENT_ID: "secureElementId"
    ]
    
    private var deviceInfoMap: [String: Any] = [:]
    
    func collectDataFromCharacteristicIfPossible(_ characteristic: CBCharacteristic) {
        if let deviceInfoKey = BLEDeviceInfoCollector.characteristicBindings[characteristic.uuid],
           let value = characteristic.value {
            deviceInfoMap[deviceInfoKey] = String(data: value, encoding: String.Encoding.utf8)
        }
    }
    
    var isCollected: Bool {
        return deviceInfoMap.count == BLEDeviceInfoCollector.characteristicBindings.count
    }
    
    var deviceInfo: Device? {
        guard isCollected else { return nil }
        
        if let secureElementId = deviceInfoMap["secureElementId"] {
            deviceInfoMap["secureElement"] = ["secureElementId": secureElementId]
        }
        
        return try? Device(deviceInfoMap)
    }
}
