
@objc public enum SecurityNFCState : Int
{
    case disabled         = 0x00
    case enabled          = 0x01
    case doNotChangeState = 0xFF
}

@objc public enum DeviceControlState : Int
{
    case esePowerOFF    = 0x00
    case esePowerON     = 0x02
    case esePowerReset  = 0x01
}

@objc public enum ConnectionState : Int {
    case new = 0
    case disconnected
    case connecting
    case connected
    case disconnecting
    case initialized
}

@objc public enum PaymentDeviceEventTypes : Int, FitpayEventTypeProtocol {
    case onDeviceConnected = 0
    case onDeviceDisconnected
    case onNotificationReceived
    case onSecurityStateChanged
    case onApplicationControlReceived
    case onConnectionStateChanged
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .onDeviceConnected:
            return "On device connected or when error occurs, returns ['deviceInfo':DeviceInfo, 'error':ErrorType]."
        case .onDeviceDisconnected:
            return "On device disconnected."
        case .onNotificationReceived:
            return "On notification received, returns ['notificationData':NSData]."
        case .onSecurityStateChanged:
            return "On security state changed, return ['securityState':Int]."
        case .onApplicationControlReceived:
            return "On application control received"
        case .onConnectionStateChanged:
            return "On connection state changed, returns ['state':Int]"
        }
    }
}

@objc open class PaymentDevice : NSObject
{
    public enum ErrorCode : Int, Error, RawIntValue, CustomStringConvertible, CustomNSError
    {
        case unknownError               = 0
        case badBLEState                = 10001
        case deviceDataNotCollected     = 10002
        case waitingForAPDUResponse     = 10003
        case apduPacketCorrupted        = 10004
        case apduDataNotFull            = 10005
        case apduErrorResponse          = 10006
        case apduWrongSequenceId        = 10007
        case apduSendingTimeout         = 10008
        case operationTimeout           = 10009
        case deviceShouldBeDisconnected = 10010
        case deviceShouldBeConnected    = 10011
        case tryLater                   = 10012
        case nonApduProcessingTimeout   = 10013
        
        public var description : String {
            switch self {
            case .unknownError:
                return "Unknown error"
            case .badBLEState:
                return "Can't connect to the device. BLE state: %d."
            case .deviceDataNotCollected:
                return "Device data not collected."
            case .waitingForAPDUResponse:
                return "Waiting for APDU response."
            case .apduPacketCorrupted:
                return "APDU packet checksum is not equal."
            case .apduDataNotFull:
                return "APDU data not fully filled in."
            case .operationTimeout:
                return "Connection timeout. Can't find device."
            case .deviceShouldBeDisconnected:
                return "Payment device should be disconnected."
            case .deviceShouldBeConnected:
                return "Payment device should be connected."
            case .apduSendingTimeout:
                return "APDU timeout error occurred."
            case .apduWrongSequenceId:
                return "Received APDU with wrong sequenceId."
            case .apduErrorResponse:
                return "Received APDU command with error response."
            case .tryLater:
                return "Device not ready for sync, try later."
            case .nonApduProcessingTimeout:
                return "Non APDU processing timeout error occurred."
            }
        }
        
        public var errorCode: Int {
            return self.rawValue
        }
        
        public var errorUserInfo: [String : Any] {
            return [NSLocalizedDescriptionKey : self.description]
        }
        
        public static var errorDomain: String {
            return "\(PaymentDevice.self)"
        }
    }

    /**
     Completion handler
     
     - parameter event: Provides event with payload in eventData property
     */
    public typealias PaymentDeviceEventBlockHandler = (_ event:FitpayEvent) -> Void
    
    /**
     Binds to the event using SyncEventType and a block as callback. 
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when event occurs
     */
    @objc open func bindToEvent(eventType: PaymentDeviceEventTypes, completion: @escaping PaymentDeviceEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    /**
     Binds to the event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when event occurs
     - parameter queue: queue in which completion will be called
     */
    @objc open func bindToEvent(eventType: PaymentDeviceEventTypes, completion: @escaping PaymentDeviceEventBlockHandler, queue: DispatchQueue) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion, queue: queue), eventId: eventType)
    }
    
    /**
     Removes bind with eventType.
     */
    @objc open func removeBinding(binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    /**
     Removes all bindings.
     */
    @objc open func removeAllBindings() {
        eventsDispatcher.removeAllBindings()
    }
    
    /**
     Establishes BLE connection with payment device and collects DeviceInfo from it.
     Calls OnDeviceConnected event.
     
     - parameter secsTimeout: timeout for connection process in seconds. If nil then there is no timeout.
     */
    @objc open func connectWithTimeout(_ secsTimeout: Int) {
        connect(secsTimeout)
    }
    open func connect(_ secsTimeout: Int? = nil) {
        if isConnected {
            self.deviceInterface.resetToDefaultState()
        }
        
        self.connectionState = ConnectionState.connecting

        if let secsTimeout = secsTimeout {
            let delayTime = DispatchTime.now() + Double(Int64(UInt64(secsTimeout) * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                if (!strongSelf.isConnected || strongSelf.deviceInfo == nil) {
                    strongSelf.deviceInterface.resetToDefaultState()
                    strongSelf.callCompletionForEvent(PaymentDeviceEventTypes.onDeviceConnected, params: ["error":NSError.error(code: PaymentDevice.ErrorCode.operationTimeout, domain: PaymentDevice.self)])
                    strongSelf.connectionState = .disconnected
                }
            }
        }
        
        self.deviceInterface.connect()
    }
    
    /**
     Returns state of connection.
     */
    @objc open var connectionState : ConnectionState = ConnectionState.new {
        didSet {
            callCompletionForEvent(PaymentDeviceEventTypes.onConnectionStateChanged, params: ["state" : NSNumber(value: connectionState.rawValue as Int)])
        }
    }
    
    /**
     Returns true if phone connected to payment device and device info was collected.
     */
    @objc open var isConnected : Bool {
        return self.deviceInterface.isConnected()
    }
    
    /**
     Tries to validate connection.
     */
    @objc open func validateConnection(completion : @escaping (_ isValid:Bool, _ error: NSError?) -> Void) {
        self.deviceInterface.validateConnection(completion: completion)
    }
    
    /**
     Returns DeviceInfo if phone already connected to payment device.
     */
    @objc open var deviceInfo : DeviceInfo? {
        return self.deviceInterface.deviceInfo()
    }
    
    /**
     Changes interface with payment device. Default is BLE (BluetoothPaymentDeviceConnector).
     If you want to implement your own interface than it should confirm IPaymentDeviceConnector protocol.
     Also implementation should call PaymentDevice.callCompletionForEvent() for events.
     */
    @objc open func changeDeviceInterface(_ interface: IPaymentDeviceConnector) -> NSError? {
        self.deviceInterface = interface
        return nil
    }
    
    internal var deviceInterface : IPaymentDeviceConnector!
    fileprivate let eventsDispatcher = FitpayEventDispatcher()
    
    /**
     Handler for APDU execution, should be called when apdu execution completed.
     
     - parameter apduResponse: APDU response message
     - parameter responseState: state which will be sent to confirm endpoint. If nil then system will choose right value automatically.
     - parameter error: error which occurred during APDU command execution. If nil then there was no any error.
     */
    public typealias APDUResponseHandler = (_ apduResponse:ApduResultMessage?, _ responseState: APDUPackageResponseState?, _ error:Error?)->Void
    @objc open var apduResponseHandler : ((_ apduResponse:ApduResultMessage?, _ responseState: String?, _ error:Error?)->Void)?
    
    /// Handles id verification request
    ///
    /// - Parameter completion: when completion will be called, then the response will be sent to RTM
    public func handleIdVerificationRequest(completion: @escaping (IdVerificationResponse)->Void) {
        self.deviceInterface.handleIdVerificationRequest?(completion: completion)
    }
    
    override public init() {
        super.init()
        self.paymentDeviceApduExecuter = PaymentDeviceApduExecuter(paymentDevice: self)
        self.deviceInterface = BluetoothPaymentDeviceConnector(paymentDevice: self)
    }
    
    fileprivate var paymentDeviceApduExecuter: PaymentDeviceApduExecuter!
    
    internal func apduPackageProcessingStarted(_ package: ApduPackage, completion: @escaping (_ error: NSError?) -> Void) {
        if let onPreApduPackageExecute = self.deviceInterface.onPreApduPackageExecute {
        	onPreApduPackageExecute(package, completion)
        } else {
            completion(nil)
        }
    }
    
    internal func apduPackageProcessingFinished(_ package: ApduPackage, completion: @escaping (_ error: NSError?) -> Void) {
        if let onPostApduPackageExecute = self.deviceInterface.onPostApduPackageExecute {
            onPostApduPackageExecute(package, completion)
        } else {
            completion(nil)
        }
    }
    
    internal typealias APDUExecutionHandler = (_ apduCommand:APDUCommand?, _ state: APDUPackageResponseState?, _ error:Error?)->Void
    internal func executeAPDUCommand(_ apduCommand: APDUCommand, completion: @escaping APDUExecutionHandler) {
        do {
            try self.paymentDeviceApduExecuter.execute(command: apduCommand, executionBlock: { [weak self] (apduCommand, completion) in
                
                self?.apduResponseHandler = completion
                log.verbose("APDU_DATA: Calling device interface to execute APDU's.")
                
                var isCompleteExecute = false
                DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(FitpaySDKConfiguration.defaultConfiguration.commitErrorTimeout), execute: {
                    if !isCompleteExecute {
                        self?.apduResponseHandler = nil
                        log.error("APDU_DATA: Received timeout during execute APDU's.")
                        completion(nil, nil, NSError.error(code: PaymentDevice.ErrorCode.apduSendingTimeout, domain: PaymentDevice.self))
                    }
                })

                self?.deviceInterface.executeAPDUCommand(apduCommand)
                isCompleteExecute = true

            }, completion: completion)

        } catch {
            log.error("Can't execute message, error: \(error)")
            completion(nil, nil, NSError.unhandledError(PaymentDevice.self))
        }
    }
    
    internal func processNonAPDUCommit(commit: Commit, completion: @escaping (_ state: NonAPDUCommitState?, _ error: NSError?) -> Void) {
        if let processNonAPDUCommit = self.deviceInterface.processNonAPDUCommit {

            var isCompleteProcessing = false
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(FitpaySDKConfiguration.defaultConfiguration.commitErrorTimeout), execute: {
                if !isCompleteProcessing {
                    log.error("APDU_DATA: Received timeout during process non-APDU commit.")
                    completion(.failed, NSError.error(code: PaymentDevice.ErrorCode.nonApduProcessingTimeout, domain: PaymentDevice.self))
                }
            })
            
            processNonAPDUCommit(commit) { (state, error) in
                isCompleteProcessing = true
                completion(state, error)
            }
        } else {
            completion(.skipped, nil)
        }
    }
    
    @objc open func callCompletionForEvent(_ eventType: PaymentDeviceEventTypes, params: [String:Any] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: eventType, eventData: params))
    }
}
