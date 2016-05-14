import CoreBluetooth

internal let PAYMENTDEVICE_DEVICE_NAME = "FitPayPD"

enum FitpayServiceUUID: String {
    case PaymentServiceUUID    = "d7cc1dc2-3603-4e71-bce6-e3b1551633e0"
    case DeviceInfoServiceUUID = "0000180a-0000-1000-8000-00805f9b34fb"
}

enum FitpayPaymentCharacteristicUUID: String {
    
    case APDUControlCharacteristic         = "0761f49b-5f56-4008-b203-fd2406db8c20"
    case APDUResultCharacteristic          = "840f2622-ff4a-4a56-91ab-b1e6dd977db4"
    case ContinuationControlCharacteristic = "cacc2825-0a2b-4cf2-a1a4-b9db27691382"
    case ContinuationPacketCharacteristic  = "52d26993-6d10-4080-8166-35d11cf23c8c"
    case SecureElementIdCharacteristic     = "1251697c-0826-4166-a3c0-72704954c32d"
    case NotificationCharacteristic        = "37051cf0-d70e-4b3c-9e90-0f8e9278b4d3"
    case SecurityWriteCharacteristic       = "e4bbb38f-5aaa-4056-8cf0-57461082d598"
    case SecurityStateCharacteristic       = "ab1fe5e7-4e9d-4b8c-963f-5265dc7de466"
    case DeviceControlCharacteristic       = "50b50f72-d10a-444b-945d-d574bd67ec91"
    case ApplicationControlCharacteristic  = "6fea71ab-14ca-4921-b166-e8742e349975"
}

enum FitpayDeviceInfoCharacteristicUUID: String {
    
    case CHARACTERISTIC_MANUFACTURER_NAME_STRING = "00002a29-0000-1000-8000-00805f9b34fb"
    case CHARACTERISTIC_MODEL_NUMBER_STRING      = "00002a24-0000-1000-8000-00805f9b34fb"
    case CHARACTERISTIC_SERIAL_NUMBER_STRING     = "00002a25-0000-1000-8000-00805f9b34fb"
    
    case CHARACTERISTIC_FIRMWARE_REVISION_STRING = "00002a26-0000-1000-8000-00805f9b34fb"
    case CHARACTERISTIC_HARDWARE_REVISION_STRING = "00002a27-0000-1000-8000-00805f9b34fb"
    case CHARACTERISTIC_SOFTWARE_REVISION_STRING = "00002a28-0000-1000-8000-00805f9b34fb"
    case CHARACTERISTIC_SYSTEM_ID                = "00002a23-0000-1000-8000-00805f9b34fb"
}

internal let PAYMENT_SERVICE_UUID_PAYMENT = CBUUID(string: FitpayServiceUUID.PaymentServiceUUID.rawValue)
internal let PAYMENT_SERVICE_UUID_DEVICE_INFO = CBUUID(string: FitpayServiceUUID.DeviceInfoServiceUUID.rawValue)

internal let PAYMENT_CHARACTERISTIC_UUID_CONTINUATION_CONTROL = CBUUID(string: FitpayPaymentCharacteristicUUID.ContinuationControlCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_CONTINUATION_PACKET = CBUUID(string: FitpayPaymentCharacteristicUUID.ContinuationPacketCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_APDU_CONTROL = CBUUID(string: FitpayPaymentCharacteristicUUID.APDUControlCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_APDU_RESULT = CBUUID(string: FitpayPaymentCharacteristicUUID.APDUResultCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_NOTIFICATION = CBUUID(string: FitpayPaymentCharacteristicUUID.NotificationCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_SECURE_ELEMENT_ID = CBUUID(string: FitpayPaymentCharacteristicUUID.SecureElementIdCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_SECURITY_WRITE = CBUUID(string: FitpayPaymentCharacteristicUUID.SecurityWriteCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_SECURITY_READ = CBUUID(string: FitpayPaymentCharacteristicUUID.SecurityStateCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_DEVICE_CONTROL = CBUUID(string: FitpayPaymentCharacteristicUUID.DeviceControlCharacteristic.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_APPLICATION_CONTROL = CBUUID(string: FitpayPaymentCharacteristicUUID.ApplicationControlCharacteristic.rawValue)

internal let PAYMENT_CHARACTERISTIC_UUID_MANUFACTURER_NAME = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_MANUFACTURER_NAME_STRING.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_MODEL_NUMBER = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_MODEL_NUMBER_STRING.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_SERIAL_NUMBER = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_SERIAL_NUMBER_STRING.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_HARDWARE_REVISION = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_HARDWARE_REVISION_STRING.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_FIRMWARE_REVISION = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_FIRMWARE_REVISION_STRING.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_SOFTWARE_REVISION = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_SOFTWARE_REVISION_STRING.rawValue)
internal let PAYMENT_CHARACTERISTIC_UUID_SYSTEM_ID = CBUUID(string: FitpayDeviceInfoCharacteristicUUID.CHARACTERISTIC_SYSTEM_ID.rawValue)