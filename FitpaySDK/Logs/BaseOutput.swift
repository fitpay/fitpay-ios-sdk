import Foundation

//TODO: Where does LogLevel live?
@objc public enum LogLevel: Int {
    case verbose = 0
    case debug
    case info
    case warning
    case error
    
    var string: String {
        
        switch self {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
        
    }
}

@objc public protocol LogsOutputProtocol {
    func send(level: LogLevel, message: String, file: String, function: String, line: Int)
}

open class BaseLogsOutput: NSObject, LogsOutputProtocol {
    let formatter = DateFormatter()
    
    var date: String {
        return formatter.string(from: Date())
    }
    
    public override init() {
        formatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    open func send(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let _ = formMessage(level: level, message: message, file: file, function: function, line: line)
        // send somewhere
    }
    
    func formMessage(level: LogLevel, message: String, file: String, function: String, line: Int) -> String {
        let fileName = fileNameWithoutSuffix(file)
        var messageResult = message
        switch level {
        case .verbose, .debug, .info:
            messageResult = "\(date) \(message)"
        case .warning:
            messageResult = "\(date) ⚠️ \(level.string) - \(message) - \(fileName).\(function):\(line)"
        case .error:
            messageResult = "\(date) ❌ \(level.string) - \(message) - \(fileName).\(function):\(line)"
        }
        
        return messageResult
    }
    
    private func fileNameOfFile(_ file: String) -> String {
        let fileParts = file.components(separatedBy: "/")
        return fileParts.last ?? ""
    }
    
    private func fileNameWithoutSuffix(_ file: String) -> String {
        let fileName = fileNameOfFile(file)
        
        if !fileName.isEmpty {
            let fileNameParts = fileName.components(separatedBy: ".")
            return fileNameParts.first ?? ""
        }
        return ""
    }
}
