//
//  MockPaymentDeviceConnector.swift
//  FitpaySDK
//
//  Created by Tim Shanahan on 5/6/16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

open class MockPaymentDeviceConnector : NSObject, IPaymentDeviceConnector {
    weak var paymentDevice : PaymentDevice!
    var responseData : ApduResultMessage!
    var connected = false;
    var _nfcState = SecurityNFCState.disabled
    var sendingAPDU : Bool = false
    let maxPacketSize : Int = 20
    let apduSecsTimeout : Double = 5
    var sequenceId: UInt16 = 0
    
    var timeoutTimer : Timer?
    
    required public init(paymentDevice device:PaymentDevice) {
        self.paymentDevice = device
    }
    
    open func connect() {
        log.verbose("connecting")
        DispatchQueue.main.asyncAfter(deadline: getDelayTime(), execute: {
            self.connected = true
            self._nfcState = SecurityNFCState.enabled
            let deviceInfo = self.deviceInfo()
            log.verbose("triggering device data")
            self.paymentDevice?.callCompletionForEvent(PaymentDeviceEventTypes.onDeviceConnected, params: ["deviceInfo": deviceInfo!])
            self.paymentDevice?.connectionState = ConnectionState.connected
        })
    }
    
    open func disconnect() {
        DispatchQueue.main.asyncAfter(deadline: getDelayTime(), execute: {
            self.connected = false
            self.paymentDevice?.callCompletionForEvent(PaymentDeviceEventTypes.onDeviceDisconnected)
            self.paymentDevice?.connectionState = ConnectionState.disconnected
        })
    }
    
    open func isConnected() -> Bool {
        log.verbose("checking is connected")
        return connected;
    }
    
    open func validateConnection(completion: @escaping (Bool, NSError?) -> Void) {
        completion(isConnected(), nil)
    }
    
    open func writeSecurityState(_ state: SecurityNFCState) -> NSError?{
        _nfcState = state
        self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.onSecurityStateChanged, params: ["securityState":state.rawValue])
        return nil
    }
    
    open func sendDeviceControl(_ state: DeviceControlState) -> NSError? {
        return nil

    }
    
    open func sendNotification(_ notificationData: Data) -> NSError? {
        return nil

    }
    
    open func executeAPDUCommand(_ apduCommand: APDUCommand) {
        guard let commandData = apduCommand.command?.hexToData() else {
            if let completion = self.paymentDevice.apduResponseHandler {
                completion(nil, NSError.error(code: PaymentDevice.ErrorCode.apduDataNotFull, domain: IPaymentDeviceConnector.self))
            }
            return
        }
        
        sendAPDUData(commandData as Data, sequenceNumber: UInt16(apduCommand.sequence))
    }
    
    open func sendAPDUData(_ data: Data, sequenceNumber: UInt16) {
        let response = "9000"
        let packet = ApduResultMessage(hexResult: response, sequenceId: String(sequenceNumber))
        
        if let apduResponseHandler = self.paymentDevice.apduResponseHandler {
            self.paymentDevice.apduResponseHandler = nil
            apduResponseHandler(packet, nil)
        }
    }
    
    
    open func deviceInfo() -> DeviceInfo? {
        let deviceInfo = DeviceInfo()
        
        deviceInfo.deviceType = "WATCH"
        deviceInfo.manufacturerName = "Fitpay"
        deviceInfo.deviceName = "PSPS"
        deviceInfo.serialNumber = "074DCC022E14"
        deviceInfo.modelNumber = "FB404"
        deviceInfo.hardwareRevision = "1.0.0.0"
        deviceInfo.firmwareRevision = "1030.6408.1309.0001"
        deviceInfo.softwareRevision = "2.0.242009.6"
        deviceInfo.systemId = "0x123456FFFE9ABCDE"
        deviceInfo.osName = "IOS"
        deviceInfo.licenseKey = "6b413f37-90a9-47ed-962d-80e6a3528036"
        deviceInfo.bdAddress = "977214bf-d038-4077-bdf8-226b17d5958d"
        deviceInfo.secureElementId = "8615b2c7-74c5-43e5-b224-38882060161b"

        return deviceInfo;
    }

    open func nfcState() -> SecurityNFCState {
       return SecurityNFCState.disabled
    }
    
    open func resetToDefaultState() {
        
    }
    
    open func getDelayTime() -> DispatchTime {
        let seconds = 4.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        return dispatchTime
    }

    
    
}

