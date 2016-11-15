//
//  FitpaySDKLogger.swift
//  FitpaySDK
//
//  Created by Anton on 14.11.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

import Foundation

open class FitpaySDKLogger {
    public static let sharedInstance = FitpaySDKLogger()
    
    public private(set) var outputs: [LogsOutputProtocol] = []

    open var minLogLevel: LogLevel = LogLevel.info
    
    open func addOutput(output: LogsOutputProtocol) {
        outputs.append(output)
    }
    
    open func removeOutput(output: LogsOutputProtocol) {
        for (index, itr) in outputs.enumerated() {
            if itr as AnyObject === output as AnyObject {
                outputs.remove(at: index)
                return
            }
        }
    }
    
    open func clearOutputs() {
        outputs = []
    }
    
    open func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .verbose, message: message() as! String, file: file, function: function, line: line)
    }
    
    open func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .debug, message: message() as! String, file: file, function: function, line: line)
    }
    
    open func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .info, message: message() as! String, file: file, function: function, line: line)
    }
    
    open func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .warning, message: message() as! String, file: file, function: function, line: line)
    }
    
    open func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line) {
        send(level: .error, message: message() as! String, file: file, function: function, line: line)
    }
    
    open func send(level: LogLevel, message: String, file: String, function: String, line: Int) {
        if minLogLevel.rawValue > level.rawValue {
            return
        }
        
        for output in outputs {
            output.send(level: level, message: message, file: file, function: function, line: line)
        }
    }
}
