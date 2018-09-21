import XCTest
@testable import FitpaySDK

class PaymentDeviceTests: XCTestCase {
    var paymentDevice: PaymentDevice!
    
    override func setUp() {
        super.setUp()
        
        self.paymentDevice = PaymentDevice()
    }
    
    override func tearDown() {
        self.paymentDevice.removeAllBindings()
        self.paymentDevice = nil
        SyncManager.sharedInstance.removeAllSyncBindings()
        super.tearDown()
    }
    
    func testConnectToDeviceCheck() {
        let expectation = super.expectation(description: "connection to device check")
        _ = self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected) { (event) in
            debugPrint("event: \(event), eventData: \(event.eventData)")
            let deviceInfo = (event.eventData as? [String: Any])?["deviceInfo"] as AnyObject as? DeviceInfo
            let error = (event.eventData as? [String: Any])?["error"]
            
            XCTAssertNil(error)
            XCTAssertNotNil(deviceInfo)
            XCTAssertNotNil(deviceInfo?.secureElementId)
            
            expectation.fulfill()
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testAPDUPacket() {
        let expectation = super.expectation(description: "disconnection from device check")
        
        let successResponse = Data(bytes: UnsafePointer<UInt8>([0x90, 0x00] as [UInt8]), count: 2)
        
        _ = self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected) { (event) in
            let error = (event.eventData as? [String: Any])?["error"]
            
            XCTAssertNil(error)
            if error != nil {
                expectation.fulfill()
                return
            }
            
            let command1 = try? APDUCommand("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d515\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"00A4040008A00000000410101100\",\n         \"type\":\"PUT_DATA\"}")
            self.paymentDevice.executeAPDUCommand(command1!) { (command, _, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(command)
                XCTAssert(command!.responseCode == successResponse)
                let command2 = try? APDUCommand("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d517\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D\",\n         \"type\":\"PUT_DATA\"}")
                self.paymentDevice.executeAPDUCommand(command2!) { (command, _, error) -> Void in
                    debugPrint("apduResponse: \(String(describing: command))")
                    XCTAssertNil(error)
                    XCTAssertNotNil(command)
                    XCTAssert(command!.responseCode == successResponse)
                    
                    expectation.fulfill()
                }
            }
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }

    func testAPDUPackage() {
        let expectation = super.expectation(description: "package check")
        let successResponse = Data(bytes: UnsafePointer<UInt8>([0x90, 0x00] as [UInt8]), count: 2)

        _ = self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected, completion: { (event) in
            let error = (event.eventData as? [String: Any])?["error"]

            XCTAssertNil(error)
            if error != nil {
                expectation.fulfill()
                return
            }

            let command1 = try! APDUCommand("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d515\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"00A4040008A00000000410101100\",\n         \"type\":\"PUT_DATA\"}")
            let command2 = try! APDUCommand("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d517\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D\",\n         \"type\":\"PUT_DATA\"}")
            let package = ApduPackage()
            package.apduCommands = [command1, command2]

            self.paymentDevice.executeAPDUPackage(package) { (error) in
                var commandCounter = 0
                let commands = package.apduCommands!

                func execute(command: APDUCommand) {
                    self.paymentDevice.executeAPDUCommand(command, completion: { (command, _, error) -> Void in
                        debugPrint("apduResponse: \(String(describing: command))")
                        XCTAssertNil(error)
                        XCTAssertNotNil(command)
                        XCTAssert(command!.responseCode == successResponse)

                        commandCounter += 1

                        if commandCounter < commands.count {
                            execute(command: commands[commandCounter])
                        } else {
                            expectation.fulfill()
                        }
                    })
                }

                execute(command: commands[commandCounter])
            }

        })
        self.paymentDevice.connect()
        super.waitForExpectations(timeout: 20, handler: nil)
    }

    func testSync() {
        let expectation = super.expectation(description: "test sync with commit")
        
        SyncManager.sharedInstance.paymentDevice = self.paymentDevice
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.connectingToDevice) { (_) -> Void in
            print("connecting to device started")
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.connectingToDeviceCompleted) { (_) -> Void in
            print("connecting to device finished")
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncStarted) { (_) -> Void in
            print("sync started")
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncFailed) { (event) -> Void in
            print("sync failed", event.eventData)
            
            XCTAssertNil(event.eventData)
            
            SyncManager.sharedInstance.removeAllSyncBindings()
            
            expectation.fulfill()
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.commitProcessed) { (_) -> Void in
            print("COMMIT_PROCESSED")
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncProgress) { (event) -> Void in
            print("sync progress", event.eventData)
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.apduCommandsProgress) { (event) -> Void in
            print("apdu progress", event.eventData)
        }
        
        _ = SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.syncCompleted) { (event) -> Void in
            print("sync finished", event.eventData)
            
            SyncManager.sharedInstance.removeAllSyncBindings()
            expectation.fulfill()
        }
        
        _ = SyncManager.sharedInstance.paymentDevice!.bindToEvent(eventType: PaymentDeviceEventTypes.onNotificationReceived) { (notificationData) -> Void in
            print("notification:", notificationData)
        }
        
        var clientId = "fp_webapp_pJkVp2Rl"
        let redirectUri = "https://webapp.fit-pay.com"
        let username = "testableuser2@something.com"
        let password = "1029"
        
        let config = FitpaySDKConfiguration(clientId: clientId, redirectUri: redirectUri, baseAuthURL: AUTHORIZE_BASE_URL, baseAPIURL: API_BASE_URL)
        if let error = config.loadEnvironmentVariables() {
            print("Can't load config from environment. Error: \(error)")
        } else {
            clientId = config.clientId
        }
        
        let restSession: RestSession = RestSession(configuration: config)
        let restClient: RestClient = RestClient(session: restSession)
        
        restSession.login(username: username, password: password) { (error) -> Void in
            XCTAssertNil(error)
            XCTAssertTrue(restSession.isAuthorized)
            
            if !restSession.isAuthorized { return }
            
            restClient.user(id: restSession.userId!, completion: { (user, error) -> Void in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(user)
                    
                    //                user?.createNewDevice("SMART_STRAP", manufacturerName: "Fitpay", deviceName: "TestDevice2", serialNumber: "1.0.1", modelNumber: "1.0.0.0.1", hardwareRevision: "1.0.0.0.0.0.0.0.0.0.1", firmwareRevision: "1.0.851", softwareRevision: "1.0.0.1", systemId: "0x123456FFFE9ABCDE", osName: "Mock OS", licenseKey: "Some key", bdAddress: "", secureElementId: "4215b2c7-9999-1111-b224-388820601642", pairing: "2016-02-29T21:42:21.469Z", completion: { (device, error) -> Void in
                    _ = SyncManager.sharedInstance.sync(user!)
                    //                })
                    
            })
        }
        
        super.waitForExpectations(timeout: 180, handler: nil)
    }
}
