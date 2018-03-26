//
//  IntExtensions.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 13.04.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import Foundation

public func hex<T:BinaryInteger>( v:T) -> String {
    var v = v
    var s = ""
    for _ in 0..<MemoryLayout<T>.size * 2 {
        s = String(format: "%X", Int64((v & 0xf))) + s
         v /= 16
    }
    
    var firstZeroCounter = 0
    for char in s {
        if char != "0" {
            break
        }
        firstZeroCounter += 1
    }
    
    if firstZeroCounter > 0 {
        let range = s.startIndex..<s.index(s.startIndex, offsetBy: firstZeroCounter)
        s.removeSubrange(range)
    }
    
    return s
}

extension BinaryInteger {
    public func hex(preferableLength: Int) -> String {
        var s = FitpaySDK.hex(v: self)
        let lenght = s.count
        if lenght < preferableLength {
            for _ in 0..<preferableLength - lenght {
                s = "0" + s
            }
        }
        
        return s
    }
}
