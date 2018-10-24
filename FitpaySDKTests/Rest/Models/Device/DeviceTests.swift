import XCTest
import Nimble

@testable import FitpaySDK

class DeviceTests: XCTestCase {
    
    private let mockModels = MockModels()
    private let mockRestRequest = MockRestRequest()
    private var session: RestSession?
    private var client: RestClient?
    
    override func setUp() {
        session = RestSession(sessionData: nil, restRequest: mockRestRequest)
        session!.accessToken = "authorized"
        
        client = RestClient(session: session!, restRequest: mockRestRequest)
    }
    
    func testDeviceParsing() {
        let device = mockModels.getDevice()
        
        expect(device?.deviceIdentifier).to(equal(mockModels.someId))
        expect(device?.deviceName).to(equal(mockModels.someName))
        expect(device?.deviceType).to(equal(mockModels.someType))
        expect(device?.manufacturerName).to(equal(mockModels.someName))
        expect(device?.state).to(equal("12345fsd"))
        expect(device?.serialNumber).to(equal("987654321"))
        expect(device?.modelNumber).to(equal("1258PO"))
        expect(device?.hardwareRevision).to(equal("12345fsd"))
        expect(device?.firmwareRevision).to(equal("12345fsd"))
        expect(device?.softwareRevision).to(equal("12345fsd"))
        expect(device?.notificationToken).to(equal("12345fsd"))
        expect(device?.createdEpoch).to(equal(NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch)))
        expect(device?.created).to(equal(mockModels.someDate))
        expect(device?.osName).to(equal(mockModels.someName))
        expect(device?.systemId).to(equal(mockModels.someId))
        expect(device?.licenseKey).to(equal("147PLO"))
        expect(device?.bdAddress).to(equal("someAddress"))
        expect(device?.pairing).to(equal("pairing"))
        expect(device?.secureElement?.secureElementId).to(equal(mockModels.someId))
        expect(device?.secureElement?.casdCert).to(equal("casd"))
        expect(device?.profileId).to(equal(mockModels.someId))
        expect(device?.defaultCreditCardId).to(equal(mockModels.someId))
        
        let json = device?.toJSON()
        expect(json?["_links"]).toNot(beNil())
        expect(json?["deviceIdentifier"] as? String).to(equal(mockModels.someId))
        expect(json?["deviceName"] as? String).to(equal(mockModels.someName))
        expect(json?["deviceType"] as? String).to(equal(mockModels.someType))
        expect(json?["manufacturerName"] as? String).to(equal(mockModels.someName))
        expect(json?["state"] as? String).to(equal("12345fsd"))
        expect(json?["serialNumber"] as? String).to(equal("987654321"))
        expect(json?["modelNumber"] as? String).to(equal("1258PO"))
        expect(json?["hardwareRevision"] as? String).to(equal("12345fsd"))
        expect(json?["firmwareRevision"] as? String).to(equal("12345fsd"))
        expect(json?["softwareRevision"] as? String).to(equal("12345fsd"))
        expect(json?["notificationToken"] as? String).to(equal("12345fsd"))
        expect(json?["createdTsEpoch"] as? Int64).to(equal(mockModels.timeEpoch))
        expect(json?["createdTs"] as? String).to(equal(mockModels.someDate))
        expect(json?["osName"] as? String).to(equal(mockModels.someName))
        expect(json?["systemId"] as? String).to(equal(mockModels.someId))
        expect(json?["licenseKey"] as? String).to(equal("147PLO"))
        expect(json?["bdAddress"] as? String).to(equal("someAddress"))
        expect(json?["pairing"] as? String).to(equal("pairing"))
        expect(json?["profileId"] as? String).to(equal(mockModels.someId))
        expect(json?["defaultCreditCardId"] as? String).to(equal(mockModels.someId))
        expect((json?["secureElement"] as? [String: Any])?["secureElementId"] as? String).to(equal(mockModels.someId))
        expect((json?["secureElement"] as? [String: Any])?["casdCert"] as? String).to(equal("casd"))
    }
    
    func testDeviceInit() {
        let se = SecureElement(secureElementId: "secureElementId", casdCert: "casdCert")
        let device = Device(deviceType: "deviceType", manufacturerName: "manufacturerName", deviceName: "deviceName", serialNumber: "serialNumber", modelNumber: "modelNumber", hardwareRevision: "hardwareRevision", firmwareRevision: "firmwareRevision", softwareRevision: "softwareRevision", notificationToken: "notificationToken", systemId: "systemId", osName: "osName", secureElement: se)
        
        expect(device.deviceIdentifier).to(beNil())
        
        expect(device.deviceType).to(equal("deviceType"))
        expect(device.manufacturerName).to(equal("manufacturerName"))
        expect(device.deviceName).to(equal("deviceName"))
        expect(device.serialNumber).to(equal("serialNumber"))
        expect(device.modelNumber).to(equal("modelNumber"))
        expect(device.hardwareRevision).to(equal("hardwareRevision"))
        expect(device.firmwareRevision).to(equal("firmwareRevision"))
        expect(device.softwareRevision).to(equal("softwareRevision"))
        expect(device.notificationToken).to(equal("notificationToken"))
        expect(device.systemId).to(equal("systemId"))
        expect(device.osName).to(equal("osName"))
        expect(device.secureElement).to(equal(se))
        
    }
    
    func testUserAvailable() {
        let device = mockModels.getDevice()
        let deviceNoLinks = mockModels.getDeviceInfoNoLinks()
        
        let userAvailable = device?.userAvailable
        expect(userAvailable).to(beTrue())
        
        let userNotAvailable = deviceNoLinks?.userAvailable
        expect(userNotAvailable).to(beFalse())
    }
    
    func testListCommitsAvailable() {
        let device = mockModels.getDevice()
        let deviceNoLinks = mockModels.getDeviceInfoNoLinks()
        
        let listCommitsAvailable = device?.listCommitsAvailable
        expect(listCommitsAvailable).to(beTrue())
        
        let listCommitsNotAvailable = deviceNoLinks?.listCommitsAvailable
        expect(listCommitsNotAvailable).to(beFalse())
    }
    
    func testLastAckCommitAvailable() {
        let device = mockModels.getDevice()
        let deviceNoLinks = mockModels.getDeviceInfoNoLinks()
        
        let lastAckCommitAvailable = device?.lastAckCommitAvailable
        expect(lastAckCommitAvailable).to(beTrue())
        
        let lastAckCommitNotAvailable = deviceNoLinks?.lastAckCommitAvailable
        expect(lastAckCommitNotAvailable).to(beFalse())
    }

    func testDefaultCreditCardAvailable() {
        let device = mockModels.getDevice()
        let deviceNoLinks = mockModels.getDeviceInfoNoLinks()
        
        let defaultCreditCardAvailable = device?.defaultCreditCardAvailable
        expect(defaultCreditCardAvailable).to(beTrue())
        
        let defaultCreditCardNotAvailable = deviceNoLinks?.defaultCreditCardAvailable
        expect(defaultCreditCardNotAvailable).to(beFalse())
    }
    
    func testDeviceResetAvailable() {
        let device = mockModels.getDevice()
        let deviceNoLinks = mockModels.getDeviceInfoNoLinks()
        
        let deviceResetAvailable = device?.deviceResetAvailable
        expect(deviceResetAvailable).to(beTrue())
        
        let deviceResetNotAvailable = deviceNoLinks?.deviceResetAvailable
        expect(deviceResetNotAvailable).to(beFalse())
    }
    
    func testDeleteDeviceInfoNoClient() {
        let device = mockModels.getDevice()
        
        device?.deleteDeviceInfo { (error) in
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testDeleteDeviceInfo() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.deleteDeviceInfo { (error) in
            expect(error).to(beNil())
        }
    }
    
    func testUpdateDeviceNoClient() {
        let device = mockModels.getDevice()
        device?.notificationToken = "notificationToken"
        
        device?.updateDevice(device!) { (device, error) in
            expect(device).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testUpdateDevice() {
        let device = mockModels.getDevice()
        device?.client = client
        device?.notificationToken = "notificationToken"
        
        device?.updateDevice(device!) { (device, error) in
            expect(error).to(beNil())
            expect(device).toNot(beNil())
        }
    }
    
    func testListCommitsNoClient() {
        let device = mockModels.getDevice()
        
        device?.listCommits(commitsAfter: nil, limit: 10, offset: 0) { (commitResults, error) in
            expect(commitResults).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testListCommits() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.listCommits(commitsAfter: nil, limit: 10, offset: 0) { (commitResults, error) in
            expect(error).to(beNil())
            expect(commitResults).toNot(beNil())
            expect(commitResults?.results?.count).to(equal(1))
        }
    }
    
    func testDefaultCreditCardNoClient() {
        let device = mockModels.getDevice()
        
        device?.getDefaultCreditCard { (card, error) in
            expect(card).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testDefaultCreditCard() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.getDefaultCreditCard { (card, error) in
            expect(error).to(beNil())
            expect(card).toNot(beNil())
        }
    }
    
    func testLastAckCommitdNoClient() {
        let device = mockModels.getDevice()
        
        device?.lastAckCommit { (commit, error) in
            expect(commit).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testLastAckCommit() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.lastAckCommit { (commit, error) in
            expect(error).to(beNil())
            expect(commit).toNot(beNil())
        }
    }

    func testUserNoClient() {
        let device = mockModels.getDevice()
        
        device?.user { (user, error) in
            expect(user).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testUser() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.user { (user, error) in
            expect(error).to(beNil())
            expect(user).toNot(beNil())
        }
    }
    
    func testResetDeviceNoClient() {
        let device = mockModels.getDevice()
        
        device?.resetDevice { (resetDeviceResult, error) in
            expect(resetDeviceResult).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testResetDevice() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.resetDevice { (resetDeviceResult, error) in
            expect(error).to(beNil())
            expect(resetDeviceResult).toNot(beNil())
        }
    }
    
    func testAddNotificationTokenNoClient() {
        let device = mockModels.getDevice()
        
        device?.addNotificationToken("123") { (device, error) in
            expect(device).to(beNil())
            expect(error).toNot(beNil())
            expect(error?.localizedDescription).to(equal("RestClient is not set."))
        }
    }
    
    func testAddNotificationToken() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.addNotificationToken("123") { (device, error) in
            expect(error).to(beNil())
            expect(device).toNot(beNil())
        }
    }
    
    func testUpdateNotificationTokenIfNeededNoClient() {
        let device = mockModels.getDevice()
        
        FitpayNotificationsManager.sharedInstance.notificationToken = "123"
        
        device?.updateNotificationTokenIfNeeded { (changed, error) in
            expect(changed).to(beFalse())
            expect(error).toNot(beNil())
        }
    }
    
    func testUpdateNotificationTokenIfNeededEmpty() {
        let device = mockModels.getDevice()
        device?.client = client
        
        FitpayNotificationsManager.sharedInstance.notificationToken = ""

        device?.updateNotificationTokenIfNeeded { (changed, error) in
            expect(changed).to(beFalse())
            expect(error).to(beNil())
        }
    }
    
    func testUpdateNotificationTokenIfNeededSame() {
        let device = mockModels.getDevice()
        device?.client = client
        
        device?.notificationToken = "123"
        FitpayNotificationsManager.sharedInstance.notificationToken = "123"
        
        device?.updateNotificationTokenIfNeeded { (changed, error) in
            expect(changed).to(beFalse())
            expect(error).to(beNil())
        }
    }
    
    func testUpdateNotificationTokenIfNeeded() {
        let device = mockModels.getDevice()
        device?.client = client
        
        FitpayNotificationsManager.sharedInstance.notificationToken = "123"
        
        device?.updateNotificationTokenIfNeeded { (changed, error) in
            expect(changed).to(beTrue())
            expect(error).to(beNil())
        }
    }
    
}
