import XCTest
import Nimble

@testable import FitpaySDK

class MockPaymentDeviceTests: XCTestCase {
    var paymentDevice: PaymentDevice!
    
    let command1 = try! APDUCommand("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d515\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"00A4040008A00000000410101100\",\n         \"type\":\"PUT_DATA\"}")
    let command2 = try! APDUCommand("{ \"commandId\":\"e69e3bc6-bf36-4432-9db0-1f9e19b9d517\",\n         \"groupId\":0,\n         \"sequence\":0,\n         \"command\":\"84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D\",\n         \"type\":\"PUT_DATA\"}")
    
    override func setUp() {
        super.setUp()
        
        Nimble.AsyncDefaults.Timeout = 4
        
        paymentDevice = PaymentDevice()
        let connector = MockPaymentDeviceConnector(paymentDevice: paymentDevice)
        connector.connectDelayTime = 0.2
        connector.disconnectDelayTime = 0.2
        connector.apduExecuteDelayTime = 0.1
        _ = self.paymentDevice.changeDeviceInterface(connector)
    }
    
    override func tearDown() {
        paymentDevice.removeAllBindings()
        paymentDevice = nil
        SyncManager.sharedInstance.removeAllSyncBindings()
        
        super.tearDown()
    }
    
    // MARK: Tests
    
    func testConnectToDeviceCheck() {
        waitUntil { done in
            _ = self.paymentDevice.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected) { (event) in
                let deviceInfo = self.paymentDevice.deviceInfo
                let error = (event.eventData as? [String: Any])?["error"]
                
                expect(error).to(beNil())
                expect(deviceInfo).toNot(beNil())
                expect(deviceInfo!.deviceType).to(equal("WATCH"))
                expect(deviceInfo!.manufacturerName).to(equal("Fitpay"))
                expect(deviceInfo!.deviceName).to(equal("Mock Pay Device"))
                expect(deviceInfo!.serialNumber).to(equal("074DCC022E14"))
                expect(deviceInfo!.modelNumber).to(equal("FB404"))
                expect(deviceInfo!.hardwareRevision).to(equal("1.0.0.0"))
                expect(deviceInfo!.firmwareRevision).to(equal("1030.6408.1309.0001"))
                expect(deviceInfo!.systemId).to(equal("0x123456FFFE9ABCDE"))
                expect(deviceInfo!.osName).to(equal("Mock OS"))
                expect(deviceInfo!.licenseKey).to(equal("6b413f37-90a9-47ed-962d-80e6a3528036"))
                expect(deviceInfo!.bdAddress).to(equal("977214bf-d038-4077-bdf8-226b17d5958d"))
                
                done()
            }
            
            self.paymentDevice.connect()
        }
    }
    
    func testAPDUPacket() {
        let successResponse = Data(bytes: UnsafePointer<UInt8>([0x90, 0x00] as [UInt8]), count: 2)
        
        waitUntil { done in
            _ = self.paymentDevice.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected) { (event) in
                let error = (event.eventData as? [String: Any])?["error"]
                
                expect(error).to(beNil())
                
                self.paymentDevice.executeAPDUCommand(self.command1) { (command, _, error) in
                    expect(error).to(beNil())
                    expect(command).toNot(beNil())
                    expect(command!.responseCode).to(equal(successResponse))
                    
                    self.paymentDevice.executeAPDUCommand(self.command2) { (command, _, error) -> Void in
                        expect(error).to(beNil())
                        expect(command).toNot(beNil())
                        expect(command!.responseCode).to(equal(successResponse))
                        
                        done()
                    }
                }
            }
            
            self.paymentDevice.connect()
        }
    }
    
    func testAPDUPackage() {
        let successResponse = Data(bytes: UnsafePointer<UInt8>([0x90, 0x00] as [UInt8]), count: 2)
        
        waitUntil { done in
            _ = self.paymentDevice.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected) { (event) in
                let error = (event.eventData as? [String: Any])?["error"]
                let package = ApduPackage()
                package.apduCommands = [self.command1, self.command2]
                
                self.paymentDevice.executeAPDUPackage(package) { (error) in
                    var commandCounter = 0
                    let commands = package.apduCommands!
                    
                    func execute(command: APDUCommand) {
                        self.paymentDevice.executeAPDUCommand(command) { (command, _, error) -> Void in
                            expect(error).to(beNil())
                            expect(command).toNot(beNil())
                            expect(command!.responseCode).to(equal(successResponse))
                            
                            commandCounter += 1
                            
                            if commandCounter < commands.count {
                                execute(command: commands[commandCounter])
                            } else {
                               done()
                            }
                        }
                    }
                    
                    execute(command: commands[commandCounter])
                }
                
            }
            
            self.paymentDevice.connect()
        }
    }
}
