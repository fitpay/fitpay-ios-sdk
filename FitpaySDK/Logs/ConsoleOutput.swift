//
//  ConsoleOutput.swift
//  FitpaySDK
//
//  Created by Anton on 15.11.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

import Foundation

open class ConsoleOutput: BaseLogsOutput {
    
    override open func send(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let finalMessage = formMessage(level: level, message: message, file: file, function: function, line: line)
        print(finalMessage)
    }
}
