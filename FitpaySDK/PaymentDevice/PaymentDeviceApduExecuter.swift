import Foundation

class PaymentDeviceApduExecuter {
    private weak var paymentDevice: PaymentDevice?
    private weak var deviceDisconnectedBinding: FitpayEventBinding?

    private var isExecuting: Bool = false
    private var completion: PaymentDevice.APDUExecutionHandler!
    private var currentApduCommand: APDUCommand!
    private var prevResponsesData: Data?
    
    private var executionBlock: ExecutionBlock!
    
    typealias OnResponseReadyToHandle = (_ apduResultMessage: ApduResultMessage?, _ state: String?, _ error: Error?) -> Void
    typealias ExecutionBlock = (_ command: APDUCommand, _ completion: @escaping OnResponseReadyToHandle) -> Void
    
    // MARK: - Lifeycle
    
    init(paymentDevice: PaymentDevice) {
        self.paymentDevice = paymentDevice
    }
    
    // MARK: - Internal Functions
    
    func execute(command: APDUCommand, executionBlock: @escaping ExecutionBlock, completion: @escaping PaymentDevice.APDUExecutionHandler) throws {
        guard !self.isExecuting else {
            throw PaymentDeviceAPDUExecuterError.alreadyExecuting
        }
        
        guard self.paymentDevice?.isConnected() == true else {
            throw PaymentDeviceAPDUExecuterError.deviceShouldBeConnected
        }
        
        self.isExecuting = true
        self.completion = { [weak self] (apduCommand, state, error) in
            self?.removeDisconnectedBinding()
            completion(apduCommand, state, error)
        }
        self.currentApduCommand = command
        self.executionBlock = executionBlock
        
        self.deviceDisconnectedBinding = self.paymentDevice?.bindToEvent(eventType: PaymentDevice.PaymentDeviceEventTypes.onDeviceDisconnected) { [weak self] (event) in
            log.error("APDU_DATA: Device was disconnected during APDU execution.")
            self?.isExecuting = false
            self?.completion(nil, nil, NSError.error(code: PaymentDevice.ErrorCode.deviceWasDisconnected, domain: PaymentDevice.self))
        }
        
        
        self.executionBlock(command, self.handleApduResponse)
    }
    
    // MARK: - Private Functions
    
    private func executeConcatenationFor(command: APDUCommand, withPrevResult prevResult: ApduResultMessage) throws {
        guard let responseData = prevResult.responseData else {
            throw PaymentDeviceAPDUExecuterError.responseDataIsEmpty
        }
        
        command.command = prevResult.concatenationAPDUPayload?.hex
        
        self.prevResponsesData = responseData.subdata(in: 0..<responseData.count - 2)
        
        self.executionBlock(command, self.handleApduResponse)
    }

    private func removeDisconnectedBinding() {
        if let binding = self.deviceDisconnectedBinding {
            self.paymentDevice?.removeBinding(binding: binding)
            self.deviceDisconnectedBinding = nil
        }
    }
    
    private func handleApduResponse(_ apduResultMessage: ApduResultMessage?, _ state: String?, _ error: Error?) {
        if let error = error {
            self.isExecuting = false
            completion(self.currentApduCommand, nil, error)
            return
        }
        
        guard let apduCommand = self.currentApduCommand else { return }
        
        var realResponse = apduResultMessage
        if var concatenateAPDUResponseTo = self.prevResponsesData {
            concatenateAPDUResponseTo.append(apduResultMessage?.responseData ?? Data())
            realResponse = ApduResultMessage(hexResult: concatenateAPDUResponseTo.hex)
            self.prevResponsesData = nil
        }
        
        apduCommand.responseData = realResponse?.responseData
        
        log.debug("APDU_DATA: ExecuteAPDUCommand: response \(realResponse?.responseData?.hex ?? "nil"). Response type - \(String(describing: apduCommand.responseType)). Commands continueOnFailure - \(apduCommand.continueOnFailure).")
        
        switch apduCommand.responseType ?? .error {
        case .concatenation:
            do {
                try executeConcatenationFor(command: apduCommand, withPrevResult: realResponse!)
            } catch {
                self.isExecuting = false
                completion(nil, nil, NSError.unhandledError(PaymentDeviceApduExecuter.self))
            }
            return
        case .error, .warning:
            if apduCommand.continueOnFailure == false {
                self.isExecuting = false
                completion(apduCommand, nil, NSError.error(code: PaymentDevice.ErrorCode.apduErrorResponse, domain: PaymentDeviceApduExecuter.self))
                return
            }
            break
        default: break
        }
        
        self.isExecuting = false
        completion(apduCommand, nil, nil)
    }
    
}

extension PaymentDeviceApduExecuter {
    
    private enum PaymentDeviceAPDUExecuterError: Error {
        case alreadyExecuting
        case deviceShouldBeConnected
        case wrong
        case responseDataIsEmpty
    }
    
}
