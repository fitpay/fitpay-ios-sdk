import XCTest
import ObjectMapper
@testable import FitpaySDK

class PaymentDeviceTests: XCTestCase
{
    var paymentDevice : PaymentDevice!
    
    override func setUp()
    {
        super.setUp()
        
        self.paymentDevice = PaymentDevice()
    }
    
    override func tearDown()
    {
        self.paymentDevice.removeAllBindings()
        self.paymentDevice = nil
        SyncManager.sharedInstance.removeAllSyncBindings()
        super.tearDown()
    }
    
    func testConnectToDeviceCheck()
    {
        let expectation = super.expectationWithDescription("connection to device check")
        self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceConnected, completion:
        {
            (event) in
            debugPrint("event: \(event), eventData: \(event.eventData)")
            let deviceInfo = event.eventData["deviceInfo"] as? DeviceInfo
            let error = event.eventData["error"]
            
            XCTAssertNil(error)
            XCTAssertNotNil(deviceInfo)
            XCTAssertNotNil(deviceInfo?.secureElementId)
            
            self.paymentDevice.disconnect()
            
            expectation.fulfill()
        })
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testDisconnectFromDeviceCheck()
    {
        let expectation = super.expectationWithDescription("disconnect from device check")
        self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceConnected, completion:
        {
            (event) in
            
            let error = event.eventData["error"]
            
            XCTAssertNil(error)
            
            self.paymentDevice.disconnect()
        })
        
        self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceDisconnected, completion:
        {
            _ in
            expectation.fulfill()
        })
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testSecurityNotification()
    {
        let expectation = super.expectationWithDescription("disconnection from device check")
        
        var newState = SecurityNFCState.Disabled
        self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceConnected, completion:
        {
            (event) in
            
            let error = event.eventData["error"]
            
            XCTAssertNil(error)
            
            if self.paymentDevice.nfcState == SecurityNFCState.Disabled {
                newState = SecurityNFCState.Enabled
            }
            
            self.paymentDevice.writeSecurityState(newState)
        })
        
        self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.OnSecurityStateChanged, completion:
        {
            (event) -> Void in
            

            let stateInt = event.eventData["securityState"] as AnyObject as! NSNumber
            
            let state = SecurityNFCState(rawValue: stateInt.integerValue)
            
            XCTAssert(newState == state)
            
            if state == SecurityNFCState.Disabled {
                newState = SecurityNFCState.Enabled
                self.paymentDevice.writeSecurityState(newState)
            } else {
                expectation.fulfill()
            }
        })
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testAPDUPacket()
    {
        let expectation = super.expectationWithDescription("disconnection from device check")
        
        let successResponse = NSData(bytes: [0x90, 0x00] as [UInt8], length: 2)
        
        self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.OnDeviceConnected, completion:
        {
            (event) in
            let error = event.eventData["error"]
            
            XCTAssertNil(error)
            if let _ = error {
                expectation.fulfill()
                return
            }
            
            let command1 = Mapper<APDUCommand>().map("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d515\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"00A4040008A00000000410101100\",\n         \"type\":\"PUT_DATA\"}")
            self.paymentDevice.sendAPDUCommand(command1!, completion:
                {
                    (apduResponse, error) -> Void in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(apduResponse)
                    XCTAssert(apduResponse!.responseCode == successResponse)
                    let command2 = Mapper<APDUCommand>().map("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d517\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D\",\n         \"type\":\"PUT_DATA\"}")
                    self.paymentDevice.sendAPDUCommand(command2!, completion:
                        {
                            (apduResponse, error) -> Void in
                            debugPrint("apduResponse: \(apduResponse)")
                            XCTAssertNil(error)
                            XCTAssertNotNil(apduResponse)
                            XCTAssert(apduResponse!.responseCode == successResponse)
                            
                            expectation.fulfill()
                    })
            })
        })
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }

    func testSync()
    {
        let expectation = super.expectationWithDescription("test sync with commit")
        
        SyncManager.sharedInstance.paymentDevice = self.paymentDevice
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CONNECTING_TO_DEVICE)
        {
            (event) -> Void in
            print("connecting to device started")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CONNECTING_TO_DEVICE_COMPLETED)
        {
            (event) -> Void in
            print("connecting to device finished")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_STARTED)
        {
            (event) -> Void in
            print("sync started")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_FAILED)
        {
            (event) -> Void in
            print("sync failed", event.eventData)
            
            XCTAssertNil(event.eventData)
            
            SyncManager.sharedInstance.removeAllSyncBindings()
            
            expectation.fulfill()
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.COMMIT_PROCESSED)
        {
            (event) -> Void in
            print("COMMIT_PROCESSED")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_PROGRESS)
        {
            (event) -> Void in
            print("sync progress", event.eventData)
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.APDU_COMMANDS_PROGRESS)
        {
            (event) -> Void in
            print("apdu progress", event.eventData)
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_COMPLETED)
        {
            (event) -> Void in
            print("sync finished", event.eventData)
            
            SyncManager.sharedInstance.removeAllSyncBindings()
            expectation.fulfill()
        }
        
        SyncManager.sharedInstance.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.OnNotificationReceived, completion:
        {
            (notificationData)->Void in
            print("notification:", notificationData)
        })
        
        let clientId = "pagare"
        let redirectUri = "https://demo.pagare.me"
        let username = "testableuser2@something.com"
        let password = "1029"
        
        let restSession:RestSession = RestSession(configuration: FitpaySDKConfiguration(clientId:clientId, redirectUri:redirectUri, authorizeURL: AUTHORIZE_URL, baseAPIURL: API_BASE_URL))
        let restClient:RestClient = RestClient(session: restSession)

        restSession.login(username: username, password: password)
        {
            (error) -> Void in
            XCTAssertNil(error)
            XCTAssertTrue(restSession.isAuthorized)
            
            if !restSession.isAuthorized
            {
                return
            }
            
            restClient.user(id: restSession.userId!, completion:
            {
                (user, error) -> Void in
                
                XCTAssertNil(error)
                XCTAssertNotNil(user)
                
//                user?.createNewDevice("SMART_STRAP", manufacturerName: "Fitpay", deviceName: "TestDevice2", serialNumber: "1.0.1", modelNumber: "1.0.0.0.1", hardwareRevision: "1.0.0.0.0.0.0.0.0.0.1", firmwareRevision: "1.0.851", softwareRevision: "1.0.0.1", systemId: "0x123456FFFE9ABCDE", osName: "ANDROID", licenseKey: "Some key", bdAddress: "", secureElementId: "4215b2c7-9999-1111-b224-388820601642", pairing: "2016-02-29T21:42:21.469Z", completion: { (device, error) -> Void in
                    SyncManager.sharedInstance.sync(user!)
//                })
                
                
            })
        }
        
        super.waitForExpectationsWithTimeout(180, handler: nil)
    }
}