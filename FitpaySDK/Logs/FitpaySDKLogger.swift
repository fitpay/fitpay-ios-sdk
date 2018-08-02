import Foundation

let log = FitpaySDKLogger.sharedInstance

@objc open class FitpaySDKLogger: NSObject {
    @objc public static let sharedInstance = FitpaySDKLogger()
    
    @objc public private(set) var outputs: [LogsOutputProtocol] = []
    
    @objc public func addOutput(output: LogsOutputProtocol) {
        outputs.append(output)
    }
    
    @objc public func removeOutput(output: LogsOutputProtocol) {
        //TODO: Clean up remove
        for (index, itr) in outputs.enumerated() {
            if itr === output {
                outputs.remove(at: index)
                return
            }
        }
    }
    
    @objc public func clearOutputs() {
        outputs = []
    }
    
    public func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .verbose, message: message() as! String, file: file, function: function, line: line)
    }
    
    public func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .debug, message: message() as! String, file: file, function: function, line: line)
    }
    
    public func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .info, message: message() as! String, file: file, function: function, line: line)
    }
    
    public func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .warning, message: message() as! String, file: file, function: function, line: line)
    }
    
    public func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .error, message: message() as! String, file: file, function: function, line: line)
    }
    
    public func send(level: LogLevel, message: String, file: String, function: String, line: Int) {
        if FitpayConfig.minLogLevel.rawValue > level.rawValue { return }
        
        for output in outputs {
            output.send(level: level, message: message, file: file, function: function, line: line)
        }
    }
}
