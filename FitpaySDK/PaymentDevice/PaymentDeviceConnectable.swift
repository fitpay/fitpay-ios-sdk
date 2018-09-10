

// TODO: where should this go?
@objc public enum NonAPDUCommitState: Int, CustomStringConvertible {
    
    /// will continue commits execution
    case success = 0
    
    /// will continue commits execution
    case skipped
   
    /// will stop sync
    case failed
    
    /// description
    public var description: String {
        switch self {
        case .failed:
            return "FAILED"
        case .skipped:
            return "SKIPPED"
        case .success:
            return "SUCCESS"
        }
    }
}

/// Implement for your payment device Connnector
@objc public protocol PaymentDeviceConnectable {
    
    // MARK: - Required
    
    /// Connects to the payment device
    /// As result event PaymentDeviceEventTypes.onDeviceConnected should be called
    func connect()

    /// Connection check
    ///
    /// - Returns: true if phone connected to payment device and device info was collected
    func isConnected() -> Bool
    
    /// Async validation for connection between payment device and phone
    ///
    /// - Parameter completion: completion for async task.
    /// isValid should be true if connection is valid
    /// and device is ready for communications
    func validateConnection(completion: @escaping (_ isValid: Bool, _ error: NSError?) -> Void)
    
    /// Should execute APDU command on payment device.
    /// Should call PaymentDevice.apduResponseHandler when preocessed
    ///
    /// - Parameter apduCommand: apduCommand object
    func executeAPDUCommand(_ apduCommand: APDUCommand)

    /// - Returns: DeviceInfo if phone already connected to payment device
    func deviceInfo() -> Device?
    
    /// Reset to default state
    func resetToDefaultState()
    
    // MARK: - Optional
    
    /// Do what you need before executing apdu package
    ///
    /// - Parameters:
    ///   - apduPackage: apduPackage object
    ///   - completion: call completion when your task is done
    @objc optional func onPreApduPackageExecute(_ apduPackage: ApduPackage, completion: @escaping (_ error: NSError?) -> Void)
    
    /// Should execute APDU package on payment device.
    ///
    /// - Parameters:
    /// - Parameter apduPackage: apduPackage object
    ///   - completion: call completion when your task is done
    @objc optional func executeAPDUPackage(_ apduPackage: ApduPackage, completion: @escaping  (_ error: Error?) -> Void)
    
    /// Do what you need after executing apdu package
    ///
    /// - Parameters:
    ///   - apduPackage: apduPackage object
    ///   - completion: call completion when your task is done
    @objc optional func onPostApduPackageExecute(_ apduPackage: ApduPackage, completion: @escaping (_ error: NSError?) -> Void)

    /// If you need to process non apdu commit somehow then you need to implement this method.
    /// Don't forget to call completion, system is waiting for that completion.
    ///
    /// - Parameters:
    ///   - commit: current Commit object
    ///   - completion: state is process result. If state == failed, then it would be great if error object will be also provided.
    @objc optional func processNonAPDUCommit(_ commit: Commit, completion: @escaping (_ state: NonAPDUCommitState, _ error: NSError?) -> Void)
    
    /// If you can handle id verification request, then you can handle it here
    ///
    /// - Parameter completion: when completion will be called, then the response will be sent to RTM
    @objc optional func handleIdVerificationRequest(completion: @escaping (IdVerification) -> Void)
    
    /// If you need to store lastCommitId on OEM device, then implement this method
    @objc optional func getDeviceLastCommitId() -> String
    
    /// If you need to get lastCommitId from your OEM device, then implement this method
    @objc optional func setDeviceLastCommitId(_ commitId: String)
    
}
