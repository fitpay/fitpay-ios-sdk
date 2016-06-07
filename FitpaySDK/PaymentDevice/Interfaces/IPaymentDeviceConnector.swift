@objc public protocol IPaymentDeviceConnector
{
    init(paymentDevice device:PaymentDevice)
    
    func connect()

    func disconnect()
    
    func isConnected() -> Bool
    
    func writeSecurityState(state: SecurityNFCState) -> NSError?
    
    func sendDeviceControl(state: DeviceControlState) -> NSError?
    
    func sendNotification(notificationData: NSData) -> NSError?
    
    func sendAPDUData(data: NSData, sequenceNumber: UInt16)
    
    func deviceInfo() -> DeviceInfo?

    func nfcState() -> SecurityNFCState
    
    func resetToDefaultState()
}
