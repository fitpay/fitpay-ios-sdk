//
//  BaseOutput.swift
//  FitpaySDK
//
//  Created by Anton on 14.11.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

import Foundation

public enum LogLevel: Int {
    case verbose = 0
    case debug
    case info
    case warning
    case error
    
    var string : String {
        var stringRepresentation = ""
        switch self {
        case .verbose:
            stringRepresentation = "VERBOSE"
        case .debug:
            stringRepresentation = "DEBUG"
        case .info:
            stringRepresentation = "INFO"
        case .warning:
            stringRepresentation = "WARNING"
        case .error:
            stringRepresentation = "ERROR"
        }
        return stringRepresentation
    }
}

public protocol LogsOutputProtocol {
    func send(level: LogLevel, message: String, file: String, function: String, line: Int)
}

open class BaseLogsOutput : LogsOutputProtocol {
    let formatter = DateFormatter()
    var date: String {
        return formatter.string(from: Date())
    }
    
    public init() {
        formatter.dateFormat = "HH:mm:ss.SSS"
    }
    
    open func send(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let _ = formMessage(level: level, message: message, file: file, function: function, line: line)
        // send somewhere
    }
    
    open func formMessage(level: LogLevel, message: String, file: String, function: String, line: Int) -> String {
        let fileName = fileNameWithoutSuffix(file)
        var messageResult = message
        switch level {
        case .verbose, .debug, .info:
            messageResult = "\(date) \(message)"
        case .warning, .error:
            messageResult = "\(date) \(level.string) - \(message)\t\(fileName).\(function):\(line)"
        }
        
        return messageResult
    }
    
    public func fileNameOfFile(_ file: String) -> String {
        let fileParts = file.components(separatedBy: "/")
        if let lastPart = fileParts.last {
            return lastPart
        }
        return ""
    }
    
    public func fileNameWithoutSuffix(_ file: String) -> String {
        let fileName = fileNameOfFile(file)
        
        if !fileName.isEmpty {
            let fileNameParts = fileName.components(separatedBy: ".")
            if let firstPart = fileNameParts.first {
                return firstPart
            }
        }
        return ""
    }
}
