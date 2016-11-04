
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

public enum ConnectionState : Int {
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

open class PaymentDevice : NSObject
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
    open func bindToEvent(eventType: PaymentDeviceEventTypes, completion: @escaping PaymentDeviceEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    /**
     Binds to the event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when event occurs
     - parameter queue: queue in which completion will be called
     */
    open func bindToEvent(eventType: PaymentDeviceEventTypes, completion: @escaping PaymentDeviceEventBlockHandler, queue: DispatchQueue) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion, queue: queue), eventId: eventType)
    }
    
    /**
     Removes bind with eventType.
     */
    open func removeBinding(binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    /**
     Removes all bindings.
     */
    open func removeAllBindings() {
        eventsDispatcher.removeAllBindings()
    }
    
    /**
     Establishes BLE connection with payment device and collects DeviceInfo from it.
     Calls OnDeviceConnected event.
     
     - parameter secsTimeout: timeout for connection process in seconds. If nil then there is no timeout.
     */
    open func connect(_ secsTimeout: Int? = nil) {
        if isConnected {
            self.deviceInterface.resetToDefaultState()
        }
        
        self.connectionState = ConnectionState.connecting

        if let secsTimeout = secsTimeout {
            let delayTime = DispatchTime.now() + Double(Int64(UInt64(secsTimeout) * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                [unowned self] () -> Void in
                if (!self.isConnected || self.deviceInfo == nil) {
                    self.deviceInterface.resetToDefaultState()
                    self.callCompletionForEvent(PaymentDeviceEventTypes.onDeviceConnected, params: ["error":NSError.error(code: PaymentDevice.ErrorCode.operationTimeout, domain: PaymentDevice.self)])
                    self.connectionState = .disconnected
                }
            }
        }
        
        self.deviceInterface.connect()
    }
    
    /**
     Close connection with payment device.
     */
    open func disconnect() {
        self.connectionState = ConnectionState.disconnecting
        self.deviceInterface.disconnect()
    }
    
    /**
     Returns state of connection.
     */
    open var connectionState : ConnectionState = ConnectionState.new {
        didSet {
            callCompletionForEvent(PaymentDeviceEventTypes.onConnectionStateChanged, params: ["state" : NSNumber(value: connectionState.rawValue as Int)])
        }
    }
    
    /**
     Returns true if phone connected to payment device and device info was collected.
     */
    open var isConnected : Bool {
        return self.deviceInterface.isConnected()
    }
    
    /**
     Tries to validate connection.
     */
    open func validateConnection(completion : @escaping (_ isValid:Bool, _ error: NSError?) -> Void) {
        self.deviceInterface.validateConnection(completion: completion)
    }
    
    /**
     Returns DeviceInfo if phone already connected to payment device.
     */
    open var deviceInfo : DeviceInfo? {
        return self.deviceInterface.deviceInfo()
    }
    
    /**
     Returns NFC state on payment device.
     */
    open var nfcState : SecurityNFCState {
        return self.deviceInterface.nfcState()
    }
    
    /**
     Allows to power on / off the secure element or to reset it in preparation for sending it APDU and other commandsю
     Calls OnApplicationControlReceived event on device reset?
     
     - parameter state: desired security state
     */
    open func sendDeviceControl(_ state: DeviceControlState) -> NSError? {
        return self.deviceInterface.sendDeviceControl(state)
    }
    
    /**
     Sends a notification to the payment device. 
     Payment devices can then provide visual or tactile feedback depending on their capabilities.
     
     - parameter notificationData: //TODO:????
     */
    open func sendNotification(_ notificationData: Data) -> NSError? {
        return self.deviceInterface.sendNotification(notificationData)
    }
    
    /**
     Allows to change state of NFC at payment device.
     Calls OnSecurityStateChanged event when state changed.
     
     - parameter state: desired security state
     */
    // TODO: shoud it be public?
    internal func writeSecurityState(_ state:SecurityNFCState) -> NSError? {
        return self.deviceInterface.writeSecurityState(state)
    }
    
    /**
     Changes interface with payment device. Default is BLE (BluetoothPaymentDeviceConnector).
     If you want to implement your own interface than it should confirm IPaymentDeviceConnector protocol.
     Also implementation should call PaymentDevice.callCompletionForEvent() for events.
     Can be changed if device disconnected.
     */
    @objc open func changeDeviceInterface(_ interface: IPaymentDeviceConnector) -> NSError? {
        if interface !== self.deviceInterface {
            guard !isConnected else {
                return NSError.error(code: PaymentDevice.ErrorCode.deviceShouldBeDisconnected, domain: IPaymentDeviceConnector.self)
            }
        }
        
        self.deviceInterface = interface
        return nil
    }
    
    internal var deviceInterface : IPaymentDeviceConnector!
    fileprivate let eventsDispatcher = FitpayEventDispatcher()
    
    public typealias APDUResponseHandler = (_ apduResponse:ApduResultMessage?, _ error:Error?)->Void
    open var apduResponseHandler : APDUResponseHandler?
    
    override public init() {
        super.init()
        
        self.deviceInterface = BluetoothPaymentDeviceConnector(paymentDevice: self)
    }
    
    internal func sendAPDUCommand(_ apduCommand:APDUCommand, completion: @escaping APDUResponseHandler) {
        guard isConnected else {
            completion(nil, NSError.error(code: PaymentDevice.ErrorCode.deviceShouldBeConnected, domain: IPaymentDeviceConnector.self))
            return
        }
        
        self.apduResponseHandler = completion
        log.verbose("--- calling device interface to execute APDU's ---")
        self.deviceInterface.executeAPDUCommand(apduCommand)
    }
    
    internal typealias APDUExecutionHandler = (_ apduCommand:APDUCommand?, _ error:Error?)->Void
    internal func executeAPDUCommand(_ apduCommand: APDUCommand, completion: @escaping APDUExecutionHandler) {
        self.sendAPDUCommand(apduCommand)
        {
            (apduResponse, error) -> Void in
            
            if let error = error {
                completion(apduCommand, error)
                return
            }

            log.debug("ExecuteAPDUCommand: response \(apduResponse)")
            
            apduCommand.responseData = apduResponse?.msg.hex
            apduCommand.responseCode = apduResponse?.responseCode.hex
            
            if apduCommand.responseType == APDUResponseType.error {
                completion(apduCommand, NSError.error(code: PaymentDevice.ErrorCode.apduErrorResponse, domain: IPaymentDeviceConnector.self))
                return
            }
            
            completion(apduCommand, nil)
        }
    }
    
    open func callCompletionForEvent(_ eventType: FitpayEventTypeProtocol, params: [String:Any] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: eventType, eventData: params))
    }
}
