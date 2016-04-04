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
        self.paymentDevice = nil
        super.tearDown()
    }
    
    func testConnectToDeviceCheck()
    {
        let expectation = super.expectationWithDescription("connection to device check")
        self.paymentDevice.onDeviceConnected =
        {
            (deviceInfo , error) -> Void in
            
            XCTAssertNil(error)
            XCTAssertNotNil(deviceInfo)
            XCTAssertNotNil(deviceInfo?.secureElementId)
            
            self.paymentDevice.disconnect()
            
            expectation.fulfill()
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testDisconnectFromDeviceCheck()
    {
        let expectation = super.expectationWithDescription("disconnect from device check")
        self.paymentDevice.onDeviceConnected =
        {
            (deviceInfo, error) -> Void in
            
            XCTAssertNil(error)
            
            self.paymentDevice.disconnect()
        }
        
        self.paymentDevice.onDeviceDisconnected =
        {
            expectation.fulfill()
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testSecurityNotification()
    {
        let expectation = super.expectationWithDescription("disconnection from device check")
        
        var newState = PaymentDevice.SecurityState.SecurityNFCStateDisabled
        self.paymentDevice.onDeviceConnected =
        {
            (deviceInfo, error) -> Void in
            
            XCTAssertNil(error)
            
            self.paymentDevice.writeSecurityState(newState)
        }
        
        self.paymentDevice.onSecurityStateChanged =
        {
            (state) -> Void in
            
            XCTAssert(newState == state)
            
            if newState == PaymentDevice.SecurityState.SecurityNFCStateDisabled {
                newState = PaymentDevice.SecurityState.SecurityNFCStateEnabled
                self.paymentDevice.writeSecurityState(newState)
            } else {
                expectation.fulfill()
            }
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testAPDUPacket()
    {
        let expectation = super.expectationWithDescription("disconnection from device check")
        
        let successResponse = NSData(bytes: [0x90, 0x00] as [UInt8], length: 2)
        
        self.paymentDevice.onDeviceConnected =
        {
            (deviceInfo, error) -> Void in
            
            XCTAssertNil(error)
            
            self.paymentDevice.sendAPDUData("00A4040008A00000000410101100".hexToData()!, sequenceNumber: 1, completion:
            {
                (apduResponse, error) -> Void in
            
                XCTAssertNil(error)
                XCTAssertNotNil(apduResponse)
                XCTAssert(apduResponse!.responseCode == successResponse)
            self.paymentDevice.sendAPDUData("84E20001B0B12C352E835CBC2CA5CA22A223C6D54F3EDF254EF5E468F34CFD507C889366C307C7C02554BDACCDB9E1250B40962193AD594915018CE9C55FB92D25B0672E9F404A142446C4A18447FEAD7377E67BAF31C47D6B68D1FBE6166CF39094848D6B46D7693166BAEF9225E207F9322E34388E62213EE44184ED892AAF3AD1ECB9C2AE8A1F0DC9A9F19C222CE9F19F2EFE1459BDC2132791E851A090440C67201175E2B91373800920FB61B6E256AC834B9D".hexToData()!, sequenceNumber: 2, completion:
                {
                    (apduResponse, error) -> Void in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(apduResponse)
                    XCTAssert(apduResponse!.responseCode == successResponse)
                    
                    expectation.fulfill()
                })
            })
        }
        
        self.paymentDevice.connect()
        
        super.waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func testSync()
    {
        let expectation = super.expectationWithDescription("test sync with commit")
        
        SyncManager.sharedInstance.syncStorage.lastCommitId = nil
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CONNECTING_TO_DEVICE)
        {
            (eventPayload) -> Void in
            print("connecting to device started")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CONNECTING_TO_DEVICE_COMPLETED)
        {
            (eventPayload) -> Void in
            print("connecting to device finished")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_STARTED)
        {
            (eventPayload) -> Void in
            print("sync started")
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_FAILED)
        {
            (eventPayload) -> Void in
            print("sync failed", eventPayload)
            
            XCTAssertNil(eventPayload)
            expectation.fulfill()
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.CREDITCARD_CREATED)
        {
            (eventPayload) -> Void in
            print("creditcard created", eventPayload)
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_PROGRESS)
        {
            (eventPayload) -> Void in
            print("sync progress", eventPayload)
        }
        
        SyncManager.sharedInstance.bindToSyncEvent(eventType: SyncEventType.SYNC_FINISHED)
        {
            (eventPayload) -> Void in
            print("sync finished", eventPayload)
//            expectation.fulfill()
        }
        
        SyncManager.sharedInstance.paymentDevice.onReceivingTransactionNotification = {
            (transactionData)->Void in
            print("notification:", transactionData)
        }
        
        let clientId = "pagare"
        let redirectUri = "http://demo.pagare.me"
        let username = "testableuser2@something.com"
        let password = "1029"
        
        let restSession:RestSession = RestSession(clientId:clientId, redirectUri:redirectUri)
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
                
                SyncManager.sharedInstance.sync(user!)
            })
        }
        
        super.waitForExpectationsWithTimeout(180, handler: nil)
    }
}