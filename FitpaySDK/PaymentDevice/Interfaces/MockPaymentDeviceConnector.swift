//
//  MockPaymentDeviceConnector.swift
//  FitpaySDK
//
//  Created by Tim Shanahan on 5/6/16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

public class MockPaymentDeviceConnector : NSObject, IPaymentDeviceConnector {
    
    weak var paymentDevice : PaymentDevice!
    var responseData : ApduResultMessage!
    var connected = false;
    var _nfcState = SecurityNFCState.Disabled
    var sendingAPDU : Bool = false
    let maxPacketSize : Int = 20
    let apduSecsTimeout : Double = 5
    var sequenceId: UInt16 = 0
    
    var timeoutTimer : NSTimer?
    
    required public init(paymentDevice device:PaymentDevice) {
        self.paymentDevice = device
    }
    
    public func connect() {
        print("connecting")
        dispatch_after(getDelayTime(), dispatch_get_main_queue(), {
            self.connected = true
            self._nfcState = SecurityNFCState.Enabled
            let deviceInfo = self.deviceInfo()
            print("triggering device data")
            self.paymentDevice?.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceConnected, params: ["deviceInfo": deviceInfo!])
            self.paymentDevice?.connectionState = ConnectionState.Connected
        })
    }
    
    public func disconnect() {
        dispatch_after(getDelayTime(), dispatch_get_main_queue(), {
            self.connected = false
            self.paymentDevice?.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceDisconnected)
            self.paymentDevice?.connectionState = ConnectionState.Disconnected
        })
    }
    
    public func isConnected() -> Bool {
        debugPrint("checking is connected")
        return connected;
    }
    
    public func writeSecurityState(state: SecurityNFCState) -> NSError?{
        _nfcState = state
        self.paymentDevice.callCompletionForEvent(PaymentDeviceEventTypes.OnSecurityStateChanged, params: ["securityState":state.rawValue])
        return nil
    }
    
    public func sendDeviceControl(state: DeviceControlState) -> NSError? {
        return nil

    }
    
    public func sendNotification(notificationData: NSData) -> NSError? {
        return nil

    }
    
    public func executeAPDUCommand(apduCommand: APDUCommand) {
        guard let commandData = apduCommand.command?.hexToData() else {
            if let completion = self.paymentDevice.apduResponseHandler {
                completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.APDUDataNotFull, domain: IPaymentDeviceConnector.self))
            }
            return
        }
        
        sendAPDUData(commandData, sequenceNumber: UInt16(apduCommand.sequence))
    }
    
    public func sendAPDUData(data: NSData, sequenceNumber: UInt16) {
        let response = "9000"
        let packet = ApduResultMessage(hexResult: response, sequenceId: String(sequenceNumber))
        
        if let apduResponseHandler = self.paymentDevice.apduResponseHandler {
            self.paymentDevice.apduResponseHandler = nil
            apduResponseHandler(apduResponse: packet, error: nil)
        }
    }
    
    
    public func deviceInfo() -> DeviceInfo? {
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

    public func nfcState() -> SecurityNFCState {
       return SecurityNFCState.Disabled
    }
    
    public func resetToDefaultState() {
        
    }
    
    public func getDelayTime() -> UInt64{
        let seconds = 4.0
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        return dispatchTime
    }

    
    
}

