
@objc public enum SecurityNFCState : Int
{
    case Disabled         = 0x00
    case Enabled          = 0x01
    case DoNotChangeState = 0xFF
}

@objc public enum DeviceControlState : Int
{
    case ESEPowerOFF    = 0x00
    case ESEPowerON     = 0x02
    case ESEPowerReset  = 0x01
}

public enum ConnectionState : Int {
    case New = 0
    case Disconnected
    case Connecting
    case Connected
    case Disconnecting
    case Initialized
}

@objc public enum PaymentDeviceEventTypes : Int, FitpayEventTypeProtocol {
    case OnDeviceConnected = 0
    case OnDeviceDisconnected
    case OnNotificationReceived
    case OnSecurityStateChanged
    case OnApplicationControlReceived
    case OnConnectionStateChanged
    
    public func eventId() -> Int {
        return rawValue
    }
    
    public func eventDescription() -> String {
        switch self {
        case .OnDeviceConnected:
            return "On device connected or when error occurs, returns ['deviceInfo':DeviceInfo, 'error':ErrorType]."
        case .OnDeviceDisconnected:
            return "On device disconnected."
        case .OnNotificationReceived:
            return "On notification received, returns ['notificationData':NSData]."
        case .OnSecurityStateChanged:
            return "On security state changed, return ['securityState':Int]."
        case .OnApplicationControlReceived:
            return "On application control received"
        case .OnConnectionStateChanged:
            return "On connection state changed, returns ['state':Int]"
        }
    }
}

public class PaymentDevice : NSObject
{
    public enum ErrorCode : Int, ErrorType, RawIntValue, CustomStringConvertible
    {
        case UnknownError               = 0
        case BadBLEState                = 10001
        case DeviceDataNotCollected     = 10002
        case WaitingForAPDUResponse     = 10003
        case APDUPacketCorrupted        = 10004
        case APDUDataNotFull            = 10005
        case APDUErrorResponse          = 10006
        case APDUWrongSequenceId        = 10007
        case APDUSendingTimeout         = 10008
        case OperationTimeout           = 10009
        case DeviceShouldBeDisconnected = 10010
        case DeviceShouldBeConnected    = 10011
        
        public var description : String {
            switch self {
            case .UnknownError:
                return "Unknown error"
            case .BadBLEState:
                return "Can't connect to the device. BLE state: %d."
            case .DeviceDataNotCollected:
                return "Device data not collected."
            case .WaitingForAPDUResponse:
                return "Waiting for APDU response."
            case .APDUPacketCorrupted:
                return "APDU packet checksum is not equal."
            case .APDUDataNotFull:
                return "APDU data not fully filled in."
            case .OperationTimeout:
                return "Connection timeout. Can't find device."
            case .DeviceShouldBeDisconnected:
                return "Payment device should be disconnected."
            case .DeviceShouldBeConnected:
                return "Payment device should be connected."
            case .APDUSendingTimeout:
                return "APDU timeout error occurred."
            case .APDUWrongSequenceId:
                return "Received APDU with wrong sequenceId."
            case .APDUErrorResponse:
                return "Received APDU command with error response."
            }
        }
    }

    /**
     Completion handler
     
     - parameter event: Provides event with payload in eventData property
     */
    public typealias PaymentDeviceEventBlockHandler = (event:FitpayEvent) -> Void
    
    /**
     Binds to the event using SyncEventType and a block as callback. 
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when event occurs
     */
    public func bindToEvent(eventType eventType: PaymentDeviceEventTypes, completion: PaymentDeviceEventBlockHandler) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion), eventId: eventType)
    }
    
    /**
     Binds to the event using SyncEventType and a block as callback.
     
     - parameter eventType: type of event which you want to bind to
     - parameter completion: completion handler which will be called when event occurs
     - parameter queue: queue in which completion will be called
     */
    public func bindToEvent(eventType eventType: PaymentDeviceEventTypes, completion: PaymentDeviceEventBlockHandler, queue: dispatch_queue_t) -> FitpayEventBinding? {
        return eventsDispatcher.addListenerToEvent(FitpayBlockEventListener(completion: completion, queue: queue), eventId: eventType)
    }
    
    /**
     Removes bind with eventType.
     */
    public func removeBinding(binding binding: FitpayEventBinding) {
        eventsDispatcher.removeBinding(binding)
    }
    
    /**
     Removes all bindings.
     */
    public func removeAllBindings() {
        eventsDispatcher.removeAllBindings()
    }
    
    /**
     Establishes BLE connection with payment device and collects DeviceInfo from it.
     Calls OnDeviceConnected event.
     
     - parameter secsTimeout: timeout for connection process in seconds. If nil then there is no timeout.
     */
    public func connect(secsTimeout: Int? = nil) {
        if isConnected {
            self.deviceInterface.resetToDefaultState()
        }
        
        self.connectionState = ConnectionState.Connecting

        if let secsTimeout = secsTimeout {
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(secsTimeout) * NSEC_PER_SEC))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                [unowned self] () -> Void in
                if (!self.isConnected || self.deviceInfo == nil) {
                    self.deviceInterface.resetToDefaultState()
                    self.callCompletionForEvent(PaymentDeviceEventTypes.OnDeviceConnected, params: ["error":NSError.error(code: PaymentDevice.ErrorCode.OperationTimeout, domain: PaymentDevice.self)])
                }
            }
        }
        
        self.deviceInterface.connect()
    }
    
    /**
     Close connection with payment device.
     */
    public func disconnect() {
        self.connectionState = ConnectionState.Disconnecting
        self.deviceInterface.disconnect()
    }
    
    /**
     Returns state of connection.
     */
    public internal(set) var connectionState : ConnectionState = ConnectionState.New {
        didSet {
            callCompletionForEvent(PaymentDeviceEventTypes.OnConnectionStateChanged, params: ["state" : NSNumber(integer: connectionState.rawValue)])
        }
    }
    
    /**
     Returns true if phone connected to payment device and device info was collected.
     */
    public var isConnected : Bool {
        return self.deviceInterface.isConnected()
    }
    
    /**
     Returns DeviceInfo if phone already connected to payment device.
     */
    public var deviceInfo : DeviceInfo? {
        return self.deviceInterface.deviceInfo()
    }
    
    /**
     Returns NFC state on payment device.
     */
    public var nfcState : SecurityNFCState {
        return self.deviceInterface.nfcState()
    }
    
    /**
     Allows to power on / off the secure element or to reset it in preparation for sending it APDU and other commandsю
     Calls OnApplicationControlReceived event on device reset?
     
     - parameter state: desired security state
     */
    public func sendDeviceControl(state: DeviceControlState) -> NSError? {
        return self.deviceInterface.sendDeviceControl(state)
    }
    
    /**
     Sends a notification to the payment device. 
     Payment devices can then provide visual or tactile feedback depending on their capabilities.
     
     - parameter notificationData: //TODO:????
     */
    public func sendNotification(notificationData: NSData) -> NSError? {
        return self.deviceInterface.sendNotification(notificationData)
    }
    
    /**
     Allows to change state of NFC at payment device.
     Calls OnSecurityStateChanged event when state changed.
     
     - parameter state: desired security state
     */
    // TODO: shoud it be public?
    internal func writeSecurityState(state:SecurityNFCState) -> NSError? {
        return self.deviceInterface.writeSecurityState(state)
    }
    
    /**
     Changes interface with payment device. Default is BLE (BluetoothPaymentDeviceConnector).
     If you want to implement your own interface than it should confirm IPaymentDeviceConnector protocol.
     Also implementation should call PaymentDevice.callCompletionForEvent() for events.
     Can be changed if device disconnected.
     */
    @objc public func changeDeviceInterface(interface: IPaymentDeviceConnector) -> NSError? {
        if isConnected {
            return NSError.error(code: PaymentDevice.ErrorCode.DeviceShouldBeDisconnected, domain: IPaymentDeviceConnector.self)
        }
        
        self.deviceInterface = interface
        return nil
    }
    
    internal var deviceInterface : IPaymentDeviceConnector!
    private let eventsDispatcher = FitpayEventDispatcher()
    
    public typealias APDUResponseHandler = (apduResponse:ApduResultMessage?, error:ErrorType?)->Void
    public var apduResponseHandler : APDUResponseHandler?
    
    override public init() {
        super.init()
        
        self.deviceInterface = BluetoothPaymentDeviceConnector(paymentDevice: self)
    }
    
    internal func sendAPDUCommand(apduCommand:APDUCommand, completion: APDUResponseHandler) {
        guard isConnected else {
            completion(apduResponse: nil, error: NSError.error(code: PaymentDevice.ErrorCode.DeviceShouldBeConnected, domain: IPaymentDeviceConnector.self))
            return
        }
        
        self.apduResponseHandler = completion
        self.deviceInterface.executeAPDUCommand(apduCommand)
    }
    
    internal typealias APDUExecutionHandler = (apduCommand:APDUCommand?, error:ErrorType?)->Void
    internal func executeAPDUCommand(inout apduCommand: APDUCommand, completion: APDUExecutionHandler) {
        self.sendAPDUCommand(apduCommand)
        {
            (apduResponse, error) -> Void in
            
            if let error = error {
                completion(apduCommand: apduCommand, error: error)
                return
            }
            print("apduResponse \(apduResponse)")
            
            apduCommand.responseData = apduResponse?.msg.hex
            apduCommand.responseCode = apduResponse?.responseCode.hex
            
            if apduCommand.responseType == APDUResponseType.Error {
                completion(apduCommand: apduCommand, error: NSError.error(code: PaymentDevice.ErrorCode.APDUErrorResponse, domain: IPaymentDeviceConnector.self))
                return
            }
            
            completion(apduCommand: apduCommand, error: nil)
        }
    }
    
    public func callCompletionForEvent(eventType: FitpayEventTypeProtocol, params: [String:AnyObject] = [:]) {
        eventsDispatcher.dispatchEvent(FitpayEvent(eventId: eventType, eventData: params))
    }
}
