import CoreBluetooth

internal class BluetoothPaymentDeviceConnector : NSObject, IPaymentDeviceConnector {
    weak var paymentDevice : PaymentDevice!
    
    var centralManager : CBCentralManager?
    var wearablePeripheral : CBPeripheral?
    var lastState : CBCentralManagerState = CBCentralManagerState.PoweredOff
    
    var continuationCharacteristicControl: CBCharacteristic?
    var continuationCharacteristicPacket: CBCharacteristic?
    var apduControlCharacteristic: CBCharacteristic?
    var securityWriteCharacteristic: CBCharacteristic?
    var deviceControlCharacteristic: CBCharacteristic?
    var applicationControlCharacteristic: CBCharacteristic?
    var notificationCharacteristic: CBCharacteristic?
    
    var continuation : Continuation = Continuation()
    var deviceInfoCollector : BLEDeviceInfoCollector?
    
    private var _deviceInfo : DeviceInfo?
    private var _nfcState : SecurityNFCState?
    
    let maxPacketSize : Int = 20
    let apduSecsTimeout : Double = 5
    var sequenceId: UInt16 = 0
    var sendingAPDU : Bool = false
    
    var timeoutTimer : NSTimer?
    
    required init(paymentDevice device: PaymentDevice) {
        self.paymentDevice = device
    }
    
    func connect() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        if lastState == CBCentralManagerState.PoweredOn {
            self.centralManager?.scanForPeripheralsWithServices(nil, options: nil)
        }
    }
    
    func disconnect() {
        resetToDefaultState()
        
        self.paymentDevice?.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceDisconnected)
        self.paymentDevice?.connectionState = ConnectionState.Disconnected
    }
    
    func resetToDefaultState() {
        if let wearablePeripheral = self.wearablePeripheral {
            centralManager?.cancelPeripheralConnection(wearablePeripheral)
            
            wearablePeripheral.delegate = nil
        }
        
        centralManager?.stopScan()
        centralManager?.delegate = nil
        centralManager = nil
        _deviceInfo = nil
        sequenceId = 0
        sendingAPDU = false
        deviceInfoCollector = nil
    }
    
    func isConnected() -> Bool {
        guard let wearablePeripheral = self.wearablePeripheral else {
            return false
        }
        return wearablePeripheral.state == CBPeripheralState.Connected && self._deviceInfo != nil
    }
    
    func deviceInfo() -> DeviceInfo? {
        return self._deviceInfo
    }
    
    func nfcState() -> SecurityNFCState {
        return self._nfcState ?? SecurityNFCState.Disabled
    }
    
    func executeAPDUCommand(apduCommand: APDUCommand) {
        guard let commandData = apduCommand.command?.hexToData() else {
            if let completion = self.paymentDevice.apduResponseHandler {
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.APDUDataNotFull, domain: IPaymentDeviceConnector.self))
            }
            return
        }
        
        sendAPDUData(commandData, sequenceNumber: UInt16(apduCommand.sequence))
    }
    
    func sendAPDUData(data: NSData, sequenceNumber: UInt16) {
        guard let wearablePeripheral = self.wearablePeripheral, apduControlCharacteristic = self.apduControlCharacteristic else {
            if let completion = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self))
            }
            return
        }
        
        guard !self.sendingAPDU else {
            if let completion = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.WaitingForAPDUResponse, domain: BluetoothPaymentDeviceConnector.self))
            }
            return
        }
        
        
        self.sequenceId = sequenceNumber
        
        let apduPacket = NSMutableData()
        var sq16 = UInt16(littleEndian: sequenceId)
        apduPacket.appendData(NSData(bytes: [0x00] as [UInt8], length: 1)) // reserved for future use
        apduPacket.appendBytes(&sq16, length: sizeofValue(sequenceId))
        apduPacket.appendData(data)
        
        self.sendingAPDU = true
        
        if apduPacket.length <= maxPacketSize {
            wearablePeripheral.writeValue(apduPacket, forCharacteristic: apduControlCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        } else {
            sendAPDUContinuation(apduPacket)
        }
        
        startAPDUTimeoutTimer(self.apduSecsTimeout)
    }
    
    func startAPDUTimeoutTimer(secs: Double) {
        timeoutTimer?.invalidate()
        timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(secs, target:self, selector: #selector(timeoutCheck), userInfo: nil, repeats: false)
    }
    
    func stopAPDUTimeout() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    func timeoutCheck() {
        if (self.sendingAPDU) {
            self.sendingAPDU = false
            
            self.continuation.uuid = CBUUID()
            self.continuation.dataParts.removeAll()
            
            if let completion = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.APDUSendingTimeout, domain: BluetoothPaymentDeviceConnector.self))
            }
        }
    }
    
    func sendDeviceControl(state: DeviceControlState) -> NSError? {
        guard let deviceControlCharacteristic = self.deviceControlCharacteristic else {
            return NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self)
        }
        
        let msg = DeviceControlMessage.init(operation: state).msg
        wearablePeripheral?.writeValue(msg, forCharacteristic: deviceControlCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        
        return nil
    }
    
    func sendNotification(notificationData: NSData) -> NSError? {
        guard let notificationCharacteristic = self.notificationCharacteristic else {
            return NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self)
        }
        
        wearablePeripheral?.writeValue(notificationData, forCharacteristic: notificationCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        
        return nil
    }
    
    func writeSecurityState(state: SecurityNFCState) -> NSError? {
        guard let wearablePeripheral = self.wearablePeripheral, securityWriteCharacteristic = self.securityWriteCharacteristic else {
            return NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self)
        }
        
        wearablePeripheral.writeValue(NSData(bytes: [UInt8(state.rawValue)] as [UInt8], length: 1), forCharacteristic: securityWriteCharacteristic, type: CBCharacteristicWriteType.WithResponse)
        
        return nil
    }
    
    private func sendAPDUContinuation(data: NSData) {
        guard let continuationCharacteristicPacket = self.continuationCharacteristicPacket else {
            if let completion = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self))
            }
            return
        }
        
        var packetNumber : UInt16 = 0
        let maxDataSize = maxPacketSize - sizeofValue(packetNumber)
        
        var bytesSent: Int = 0
        
        sendSignalAboutContiniationStart()
        
        while (bytesSent < data.length) {
            var amountToSend:Int = data.length - bytesSent
            if amountToSend > maxDataSize  {
                amountToSend = maxDataSize
            }
            
            let chunk = NSData(bytes: data.bytes + bytesSent, length: amountToSend)
            
            let continuationPacket = NSMutableData()
            var pn16 = UInt16(littleEndian: packetNumber)
            continuationPacket.appendBytes(&pn16, length: sizeofValue(packetNumber))
            continuationPacket.appendData(chunk)
            
            wearablePeripheral?.writeValue(continuationPacket, forCharacteristic: continuationCharacteristicPacket, type: CBCharacteristicWriteType.WithResponse)
            
            bytesSent = bytesSent + amountToSend
            packetNumber += 1
        }
        
        sendSignalAboutContiniationEnd(checkSumValue: data.CRC32HashValue)
    }
    
    private func sendSignalAboutContiniationStart() {
        guard let continuationCharacteristicControl = self.continuationCharacteristicControl else {
            if let completion = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self))
            }
            return
        }
        
        let msg = NSMutableData()
        msg.appendData(NSData(bytes: [0x00] as [UInt8], length: 1)) // 0x00 - is start flag
        // UUID is little endian
        msg.appendData(PAYMENT_CHARACTERISTIC_UUID_APDU_CONTROL.data.reverseEndian)
        
        self.wearablePeripheral?.writeValue(msg, forCharacteristic: continuationCharacteristicControl, type: CBCharacteristicWriteType.WithResponse)
    }
    
    private func sendSignalAboutContiniationEnd(checkSumValue checkSumValue: Int) {
        guard let continuationCharacteristicControl = self.continuationCharacteristicControl else {
            if let completion = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.DeviceDataNotCollected, domain: BluetoothPaymentDeviceConnector.self))
            }
            return
        }
        
        var crc32 = UInt32(littleEndian: UInt32(checkSumValue))
        let msg = NSMutableData()
        msg.appendData(NSData(bytes: [0x01] as [UInt8], length: 1)) // 0x01 - is end flag
        msg.appendBytes(&crc32, length: sizeofValue(crc32))
        
        wearablePeripheral?.writeValue(msg, forCharacteristic: continuationCharacteristicControl, type: CBCharacteristicWriteType.WithResponse)
    }
    
    private func processAPDUResponse(packet:ApduResultMessage) {
        stopAPDUTimeout()
        
        self.sendingAPDU = false
        
        if self.sequenceId != packet.sequenceId {
            if let apduResponseHandler = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                apduResponseHandler(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.APDUWrongSequenceId, domain: BluetoothPaymentDeviceConnector.self))
            }
            return
        }
        
        self.sequenceId += 1
        
        if let apduResponseHandler = self.paymentDevice.apduResponseHandler {
            self.paymentDevice.apduResponseHandler = nil
            apduResponseHandler(apduResponse: packet, error: nil)
        }
    }
}

extension BluetoothPaymentDeviceConnector : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            self.paymentDevice?.connectionState = ConnectionState.Initialized
            central.scanForPeripheralsWithServices(nil, options: nil)
        } else {
            central.delegate = nil
            self.centralManager = nil
            
            if lastState == CBCentralManagerState.PoweredOn {
                resetToDefaultState()
                self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceDisconnected)
                self.paymentDevice?.connectionState = ConnectionState.Disconnected
            } else {
                self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceConnected, params: ["error":NSError.error(code: PaymentDevice.ErrorCode.BadBLEState, domain: BluetoothPaymentDeviceConnector.self, message: String(format: PaymentDevice.ErrorCode.BadBLEState.description,  central.state.rawValue))])
                self.paymentDevice?.connectionState = ConnectionState.Connected
            }
        }
        
        self.lastState = central.state
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if let nameOfDeviceFound = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if (nameOfDeviceFound.lowercaseString == PAYMENTDEVICE_DEVICE_NAME.lowercaseString) {
                self.centralManager?.stopScan()
                self.wearablePeripheral = peripheral
                self.wearablePeripheral?.delegate = self
                
                self.centralManager?.connectPeripheral(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        
        self.deviceInfoCollector = BLEDeviceInfoCollector()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        resetToDefaultState()
        
        self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceDisconnected)
        
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceConnected, params: ["error":error ?? ""])
    }
}

extension BluetoothPaymentDeviceConnector : CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service in peripheral.services! {
            if service.UUID == PAYMENT_SERVICE_UUID_PAYMENT {
                peripheral.discoverCharacteristics(nil, forService: service)
            } else if service.UUID == PAYMENT_SERVICE_UUID_DEVICE_INFO {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics! {
            if service.UUID == PAYMENT_SERVICE_UUID_DEVICE_INFO {
                peripheral.readValueForCharacteristic(characteristic)
            }
            
            if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_CONTINUATION_CONTROL {
                self.continuationCharacteristicControl = characteristic
                wearablePeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_CONTINUATION_PACKET {
                self.continuationCharacteristicPacket = characteristic
                wearablePeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_APDU_CONTROL {
                self.apduControlCharacteristic = characteristic
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_APDU_RESULT {
                wearablePeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_NOTIFICATION {
                wearablePeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_SECURITY_READ {
                wearablePeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
                peripheral.readValueForCharacteristic(characteristic)
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_SECURITY_WRITE {
                self.securityWriteCharacteristic = characteristic
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_SECURE_ELEMENT_ID {
                peripheral.readValueForCharacteristic(characteristic)
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_DEVICE_CONTROL {
                self.deviceControlCharacteristic = characteristic
            } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_APPLICATION_CONTROL {
                self.applicationControlCharacteristic = characteristic
                wearablePeripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if _deviceInfo == nil {
            if let deviceInfoCollector = self.deviceInfoCollector {
                deviceInfoCollector.collectDataFromCharacteristicIfPossible(characteristic)
                if deviceInfoCollector.isCollected {
                    _deviceInfo = deviceInfoCollector.deviceInfo
                    self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceConnected, params: ["deviceInfo":_deviceInfo!])
                    self.deviceInfoCollector = nil
                }
            }
        }
        
        if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_APDU_RESULT {
            let apduResultMessage = ApduResultMessage(msg: characteristic.value!)
            processAPDUResponse(apduResultMessage)
        } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_CONTINUATION_CONTROL {
            let continuationControlMessage = ContinuationControlMessage(msg: characteristic.value!)
            if (continuationControlMessage.isBeginning) {
                if (continuation.uuid.UUIDString != CBUUID().UUIDString) {
                    debugPrint("Previous continuation item exists")
                }
                continuation.uuid = continuationControlMessage.uuid
                continuation.dataParts.removeAll()
                
            } else {
                guard let completeResponse = continuation.data else {
                    if let completion = self.paymentDevice.apduResponseHandler {
                        self.paymentDevice.apduResponseHandler = nil
                        completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.APDUPacketCorrupted, domain: BluetoothPaymentDeviceConnector.self))
                    }
                    return
                }
                
                let crc = completeResponse.CRC32HashValue
                let crc32 = UInt32(littleEndian: UInt32(crc))
                
                if (crc32 != continuationControlMessage.crc32) {
                    if let completion = self.paymentDevice.apduResponseHandler {
                        self.paymentDevice.apduResponseHandler = nil
                        completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.APDUPacketCorrupted, domain: BluetoothPaymentDeviceConnector.self))
                    }
                    continuation.uuid = CBUUID()
                    continuation.dataParts.removeAll()
                    return
                }
                
                if continuation.uuid.UUIDString == PAYMENT_CHARACTERISTIC_UUID_APDU_RESULT.UUIDString {
                    let apduResultMessage = ApduResultMessage(msg: completeResponse)
                    processAPDUResponse(apduResultMessage)
                } else {
                    if let completion = self.paymentDevice.apduResponseHandler {
                        self.paymentDevice.apduResponseHandler = nil
                        completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.UnknownError, domain: BluetoothPaymentDeviceConnector.self))
                    }
                }
                
                // clear the continuation contents
                continuation.uuid = CBUUID()
                continuation.dataParts.removeAll()
            }
            
        } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_CONTINUATION_PACKET {
            let msg : ContinuationPacketMessage = ContinuationPacketMessage(msg: characteristic.value!)
            let pos = Int(msg.sortOrder);
            continuation.dataParts[pos] = msg.data
        } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_NOTIFICATION {
            self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnNotificationReceived, params: ["notificationData":characteristic.value ?? NSData()])
        } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_SECURITY_READ {
            if let value = characteristic.value {
                let msg = SecurityStateMessage(msg: value)
                if let securityState = SecurityNFCState(rawValue: Int(msg.nfcState)) {
                    _nfcState = securityState
                    
                    self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnSecurityStateChanged, params: ["securityState":securityState.rawValue])
                }
            }
        } else if characteristic.UUID == PAYMENT_CHARACTERISTIC_UUID_APPLICATION_CONTROL {
            if let value = characteristic.value {
//                let message = ApplicationControlMessage(msg: value)

                self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnSecurityStateChanged, params: ["applicationControl":value])
            }
        }
    }
}
