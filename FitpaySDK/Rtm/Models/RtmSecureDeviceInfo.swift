//
//  RtmSecureDeviceInfo.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 14.07.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

public class RtmSecureDeviceInfo: RtmDeviceInfo {
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func copyFieldsFrom(deviceInfo: DeviceInfo) {
        super.copyFieldsFrom(deviceInfo: deviceInfo)
        self.casd = deviceInfo.casd
        self.secureElementId = deviceInfo.secureElementId
    }
}

