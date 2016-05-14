//
//  MockPaymentDeviceInterface.swift
//  FitpaySDK
//
//  Created by Tim Shanahan on 5/6/16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

public class MockPaymentDeviceInterface : NSObject, PaymentDeviceBaseInterface {
    
    weak var paymentDevice : PaymentDevice!
    var connected = false;
    
    required public init(paymentDevice device:PaymentDevice) {
        self.paymentDevice = device
    }
    
    public func connect() {
        connected = true
    }
    
    public func disconnect() {
        connected = false
    }
    
    public func isConnected() -> Bool {
        return connected;
    }
    
    public func writeSecurityState(state: SecurityNFCState) -> NSError? {
        return nil
    }
    
    public func sendDeviceControl(state: DeviceControlState) -> NSError? {
        return nil

    }
    
    public func sendNotification(notificationData: NSData) -> NSError? {
        return nil

    }
    
    public func sendAPDUData(data: NSData, sequenceNumber: UInt16) {
        var score: Double = 0x90000000000000
        let data = NSData(bytes: &score, length: sizeof(Double))
        let packet = ApduResultMessage(msg: data)
        
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
        deviceInfo.osName = "ANDROID"
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

    
    
}

