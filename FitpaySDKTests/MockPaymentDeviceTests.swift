import XCTest
import ObjectMapper
@testable import FitpaySDK

class MockPaymentDeviceTests: XCTestCase {
    var paymentDevice: PaymentDevice!
    
    override func setUp() {
        super.setUp()
        let myPaymentDevice = PaymentDevice()
        self.paymentDevice = myPaymentDevice
        let _ = self.paymentDevice.changeDeviceInterface(MockPaymentDeviceConnector(paymentDevice: myPaymentDevice))
    }
    
    override func tearDown() {
        self.paymentDevice.removeAllBindings()
        self.paymentDevice = nil
        SyncManager.sharedInstance.removeAllSyncBindings()
        super.tearDown()
    }
    
    func testConnectToDeviceCheck() {
        let expectation = super.expectation(description: "connection to device check")
        let _ = self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected) { (event) in
                debugPrint("event: \(event), eventData: \(event.eventData)")
                let deviceInfo = self.paymentDevice.deviceInfo
                let error = (event.eventData as? [String:Any])?["error"]
                
                XCTAssertNil(error)
                XCTAssertNotNil(deviceInfo)
                XCTAssertNotNil(deviceInfo?.secureElementId)
                XCTAssertEqual(deviceInfo!.deviceType, "WATCH")
                XCTAssertEqual(deviceInfo!.manufacturerName, "Fitpay")
                XCTAssertEqual(deviceInfo!.deviceName, "PSPS")
                XCTAssertEqual(deviceInfo!.serialNumber, "074DCC022E14")
                XCTAssertEqual(deviceInfo!.modelNumber, "FB404")
                XCTAssertEqual(deviceInfo!.hardwareRevision, "1.0.0.0")
                XCTAssertEqual(deviceInfo!.firmwareRevision, "1030.6408.1309.0001")
                XCTAssertEqual(deviceInfo!.systemId, "0x123456FFFE9ABCDE")
                XCTAssertEqual(deviceInfo!.osName, "IOS")
                XCTAssertEqual(deviceInfo!.licenseKey, "6b413f37-90a9-47ed-962d-80e6a3528036")
                XCTAssertEqual(deviceInfo!.bdAddress, "977214bf-d038-4077-bdf8-226b17d5958d")
                
                expectation.fulfill()
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testAPDUPacket() {
        let expectation = super.expectation(description: "sending apdu commands")
        let successResponse = Data(bytes: UnsafePointer<UInt8>([0x90, 0x00] as [UInt8]), count: 2)
        
        let _ = self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected) { (event) in
                let error = (event.eventData as? [String: Any])?["error"]
                
                XCTAssertNil(error)

                let command1 = Mapper<APDUCommand>().map(JSONString: "{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d515\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"00A4040008A00000000410101100\",\n         \"type\":\"PUT_DATA\"}")
                self.paymentDevice.executeAPDUCommand(command1!) { (command, state, error) in
                        XCTAssertNil(error)
                        XCTAssertNotNil(command)
                        XCTAssert(command!.responseCode == successResponse)
                        let command2 = Mapper<APDUCommand>().map(JSONString: "{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d517\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D\",\n         \"type\":\"PUT_DATA\"}")
                        self.paymentDevice.executeAPDUCommand(command2!) { (command, state, error) -> Void in
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
        
        let _ = self.paymentDevice.bindToEvent(eventType: PaymentDeviceEventTypes.onDeviceConnected) { (event) in
            let error = (event.eventData as? [String: Any])?["error"]

            let command1 = Mapper<APDUCommand>().map(JSONString: "{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d515\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"00A4040008A00000000410101100\",\n         \"type\":\"PUT_DATA\"}")!
            let command2 = Mapper<APDUCommand>().map(JSONString: "{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d517\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D\",\n         \"type\":\"PUT_DATA\"}")!
            let package = ApduPackage()
            package.apduCommands = [command1, command2]

            self.paymentDevice.executeAPDUPackage(package) { (error) in
                var commandCounter = 0
                let commands = package.apduCommands!

                func execute(command: APDUCommand) {
                    self.paymentDevice.executeAPDUCommand(command, completion: { (command, state, error) -> Void in
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
            
        }
        
        self.paymentDevice.connect()
        super.waitForExpectations(timeout: 20, handler: nil)
    }
}
