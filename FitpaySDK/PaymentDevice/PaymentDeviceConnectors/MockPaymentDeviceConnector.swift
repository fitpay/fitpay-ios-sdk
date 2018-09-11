import Foundation

public class MockPaymentDeviceConnector: NSObject {
    weak var paymentDevice: PaymentDevice!
    
    var responseData: ApduResultMessage!
    var connected = false
    var sendingAPDU: Bool = false
    
    var sequenceId: UInt16 = 0
    var testingType: TestingType
    var connectDelayTime: Double = 4 
    var disconnectDelayTime: Double = 4
    var apduExecuteDelayTime: Double = 0.5
    var timeoutTimer: Timer?
    
    let maxPacketSize: Int = 20
    let apduSecsTimeout: Double = 5
    
    private let casd = "7F218202A47F218201B393102016072916110000000000001122334442038949325F200C434552542E434153442E43549501825F2504201607015F240420210701450CA000000151535043415344005314F8E1CB407F2233139DC304E40B81C21C52BFB3B35F37820100D27D99221AB06EAD71B6BC3D6008661953EBC3BD5A32C49212EFE95BDE0846632D211100AD9C67C0C8904D65823DF4AF76E73360B83943DC16A45471FBFC44E4FB254433BFE678A2E364712C3FFFF86EEB718F927DB12E8E78B3C33F980BF2CE5E333F4CFA9E9A5A3AF09CD779BEB6173D2142013B45357E6B785399C80D2C283A82EDFE8E06A72DEF4E28617700EA7CBAC02197798DA3E7E2F5C84D0F23857846DEC069553E0BCF4DB86E68B3F80C8B95053F588E47910C2BEA34D95136BA4BB4F5C41D7461062EDCD9BAF43249AA2DD005888820F5174AFC626A17C0AB326F39A095E97D99509F6DACAA61C5A31E6D1027504CC31091060111E03A8F4297E15F3850B4D8B6F9282431E1009282C23133D8025A44CC2F8CCE402B79E2A51B4EFA38E9C8A378596181B6410C5A8F7E0BB354332A93DEB40B1CACBFF1FC23B5804B52EBA1811B30E40F77CAC891F42CDCB902BF7F2181E89310201608081605268F370493B60000000142038949325F200C434552542E434153442E4354950200805F2504201607015F240420210701450CA000000151535043415344005314C0AC3B49223485BE2FCFECBC19CFE14CE01CD9797F4946B04104101E87906ADD42D19DD1BBE2E31C77C46DFA573B1765AA016B27730517AECB471372BE5855EC68FA0F4EDDA449731806630B0C55B36A03DD80613B8946006367F001005F3740301848CF8A6A80888150AFC7B3FB079671D1850B67D8A3DA5A9747E45BF51A1B49D7850853175133314A2A1DCC8D5D43B92B14E75FD5DE329A236CBEEBF1F9A5"

    enum apduCommandTypes: String {
        case SELECT_ISD
        case GET_CPLC
        case GET_SEID
        case GET_ISD_CASD
        case SELECT_CASD
        case GET_CASD_P2
        case GET_CASD_P1
        case GET_CASD_P3
        case SELECT_ALA
        case SELECT_CRS
    }
    
    required public init(paymentDevice device: PaymentDevice, testingType: TestingType = .fullSimulationMode) {
        self.paymentDevice = device
        self.testingType = testingType
    }
    
    public func disconnect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + disconnectDelayTime) {
            self.connected = false
            self.paymentDevice?.callCompletionForEvent(PaymentDevice.PaymentDeviceEventTypes.onDeviceDisconnected)
            self.paymentDevice?.connectionState = PaymentDevice.ConnectionState.disconnected
        }
    }
    
    private func sendAPDUData(apduCommand: APDUCommand, sequenceNumber: UInt16) {
        var response = ""
        
        switch apduCommand.type ?? "" {
        case apduCommandTypes.GET_CPLC.rawValue:
            response = "9F7F2A" + generateRandomSeId() + "9000"
        case apduCommandTypes.GET_CASD_P1.rawValue:
            response = casd + "9000"
        case apduCommandTypes.GET_CASD_P3.rawValue:
            response = "6D00"
        case apduCommandTypes.SELECT_ALA.rawValue:
            response = "6A82"
        default:
            response = "9000"
        }

        let packet = ApduResultMessage(hexResult: response)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + apduExecuteDelayTime) {
            if let apduResponseHandler = self.paymentDevice.apduResponseHandler {
                self.paymentDevice.apduResponseHandler = nil
                apduResponseHandler(packet, nil, nil)
            }
        }
    }
    
    private func generateRandomSeId() -> String {
        var dateString = String(format: "%2X", UInt64(Date().timeIntervalSince1970))
        while dateString.count < 12 {
            dateString = "0" + dateString
        }

        return String(testingType.rawValue, radix: 16, uppercase: true) +
            "528704504258" +
            dateString +
        "FFFF427208236250082462502041FFFF082562502041FFFF"
    }
    
}

extension MockPaymentDeviceConnector: PaymentDeviceConnectable {

    public func connect() {
        log.verbose("MOCK_DEVICE: connecting")
        DispatchQueue.main.asyncAfter(deadline: .now() + connectDelayTime) {
            self.connected = true
            let deviceInfo = self.deviceInfo()
            log.verbose("MOCK_DEVICE: triggering device data")
            self.paymentDevice?.callCompletionForEvent(PaymentDevice.PaymentDeviceEventTypes.onDeviceConnected, params: ["deviceInfo": deviceInfo!])
            self.paymentDevice?.connectionState = PaymentDevice.ConnectionState.connected
        }
    }
    
    public func isConnected() -> Bool {
        log.verbose("MOCK_DEVICE: checking is connected")
        return connected
    }
    
    public func validateConnection(completion: @escaping (Bool, NSError?) -> Void) {
        completion(isConnected(), nil)
    }
    
    public func executeAPDUCommand(_ apduCommand: APDUCommand) {
        guard apduCommand.command != nil else {
            if let completion = self.paymentDevice.apduResponseHandler {
                completion(nil, nil, NSError(domain: "\(PaymentDeviceConnectable.self)", code: PaymentDevice.ErrorCode.apduDataNotFull.rawValue, userInfo: nil))
            }
            return
        }

        sendAPDUData(apduCommand: apduCommand, sequenceNumber: UInt16(apduCommand.sequence))
    }
    
    public func deviceInfo() -> Device? {
        let deviceInfo = Device()
        
        deviceInfo.deviceType = "WATCH"
        deviceInfo.manufacturerName = "Fitpay"
        deviceInfo.deviceName = "Mock Pay Device"
        deviceInfo.serialNumber = "074DCC022E14"
        deviceInfo.modelNumber = "FB404"
        deviceInfo.hardwareRevision = "1.0.0.0"
        deviceInfo.firmwareRevision = "1030.6408.1309.0001"
        deviceInfo.softwareRevision = "2.0.242009.6"
        deviceInfo.systemId = "0x123456FFFE9ABCDE"
        deviceInfo.osName = "Mock OS"
        deviceInfo.licenseKey = "6b413f37-90a9-47ed-962d-80e6a3528036"
        deviceInfo.bdAddress = "977214bf-d038-4077-bdf8-226b17d5958d"

        return deviceInfo
    }
    
    public func resetToDefaultState() {
        
    }
    
}

//MARK: - Nested Objects

extension MockPaymentDeviceConnector {
    
    public enum TestingType: UInt64 {
        case partialSimulationMode = 0xBADC0FFEE000
        case fullSimulationMode    = 0xDEADBEEF0000
    }
    
}


