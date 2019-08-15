import XCTest
import Nimble

@testable import FitpaySDK

class SyncRequestsQueueTests: XCTestCase {
    var requestsQueue: SyncRequestQueue!
    var mockSyncManager: MockSyncManager!
    
    let mockModels = MockModels()
    
    override func setUp() {
        super.setUp()
        
        MockSyncManager.syncCompleteDelay = 0.02
        
        self.mockSyncManager = MockSyncManager()
        self.requestsQueue = SyncRequestQueue(syncManager: self.mockSyncManager)
    }
    
    func testMake1SuccessSync() {
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                done()
            }
        }
    }
    
    func testMake1FailedSync() {
        self.requestsQueue = SyncRequestQueue(syncManager: MockFailedSyncManger())
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                
                done()
            }
        }
        
    }
    
    func testSuccessQueueOrder() {
        var counter = 0
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
                
                done()
            }
        }
        
    }
    
    func testFailedQueueOrder() {
        self.requestsQueue = SyncRequestQueue(syncManager: MockFailedSyncManger())
        var counter = 0

        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                counter += 1
                
                done()
            }
        }
    }
    
    func testQueueOrderWithAsyncInsert() {
        var counter = 0
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
                
                self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                    expect(counter).to(equal(3))
                    expect(status).to(equal(.success))
                    expect(error).to(beNil())
                    counter += 1
                    
                    done()
                }
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
        }
    }
    
    func testParallelSync() {
        mockSyncManager.synchronousModeOn = false
        var counter = 0
        
        waitUntil { done in
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(0))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest1()) { (status, error) in
                expect(counter).to(equal(2))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest2()) { (status, error) in
                expect(counter).to(equal(1))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
            }
            
            self.requestsQueue.add(request: self.getSyncRequest2()) { (status, error) in
                expect(counter).to(equal(3))
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                counter += 1
                done()
            }
        }
        
    }
    
    func testMakeSyncWithoutDeviceInfo() {
        mockSyncManager.synchronousModeOn = true
        SyncRequest.syncManager = self.mockSyncManager
        
        let request = SyncRequest()
        
        waitUntil { done in
            self.requestsQueue.add(request: request) { (status, error) in
                expect(status).to(equal(.failed))
                expect(error).toNot(beNil())
                done()
            }
        }
    }
    
    func testAddAndRemovePaymentDevice() {
        expect(self.requestsQueue.paymentDevices.count).to(equal(0))
        
        let user = mockModels.getUser()
        let deviceInfo = mockModels.getDevice(deviceId: "111-111-111")
        let deviceInfo2 = mockModels.getDevice(deviceId: "222-222-222")
        let paymentDevice = PaymentDevice()

        requestsQueue.addPaymentDevice(user: user, deviceInfo: deviceInfo, paymentDevice: paymentDevice)
        expect(self.requestsQueue.paymentDevices.count).to(equal(1))
        
        requestsQueue.addPaymentDevice(user: user, deviceInfo: deviceInfo2, paymentDevice: paymentDevice)
        expect(self.requestsQueue.paymentDevices.count).to(equal(2))
        
        requestsQueue.removePaymentDevice(deviceId: "111-111-111")
        expect(self.requestsQueue.paymentDevices.count).to(equal(1))
        expect(self.requestsQueue.paymentDevices.contains(where: { $0.device?.deviceIdentifier == "222-222-222"})).to(beTrue())
    }
    
    func testSyncRequestFromNotificationDoesNotSyncAfterRemovePaymentDevice() {
        let user = mockModels.getUser()
        let deviceInfo = mockModels.getDevice()
        let paymentDevice = PaymentDevice()
        
        requestsQueue.addPaymentDevice(user: user, deviceInfo: deviceInfo, paymentDevice: paymentDevice)

        waitUntil { done in
            let request = self.getSyncRequestNotification()
            request.user = user
            self.requestsQueue.add(request: request) { (status, error) in
                expect(status).to(equal(.success))
                expect(error).to(beNil())
                
                self.requestsQueue.removePaymentDevice(deviceId: self.mockModels.someId)
                
                let anotherRequest = self.getSyncRequestNotification()
                anotherRequest.user = user
                self.requestsQueue.add(request: anotherRequest) { (status, error) in
                    expect(status).to(equal(.failed))
                    done()
                    
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getSyncRequest1() -> SyncRequest {
        let deviceInfo = mockModels.getDevice(deviceId: "111-111-111")!
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: PaymentDevice())
        SyncRequest.syncManager = self.mockSyncManager
        return request
    }
    
    private func getSyncRequest2() -> SyncRequest {
        let deviceInfo = mockModels.getDevice(deviceId: "123-123-123")!
        let request = SyncRequest(user: try! User("{\"id\":\"1\"}"), deviceInfo: deviceInfo, paymentDevice: PaymentDevice())
        SyncRequest.syncManager = self.mockSyncManager
        return request
    }

    private func getSyncRequestNotification() -> SyncRequest {
        let notificationDetail = MockModels().getNotificationDetail()
        return SyncRequest(notification: notificationDetail)
    }
}
