//
//  RtmDeviceInfo.swift
//  FitpaySDK
//
//  Created by Anton Popovichenko on 14.07.17.
//  Copyright © 2017 Fitpay. All rights reserved.
//

import ObjectMapper

public class RtmDeviceInfo: DeviceInfo {
    public init(deviceInfo: DeviceInfo) {
        super.init()
        copyFieldsFrom(deviceInfo: deviceInfo)
    }
    
    public required init?(map: Map) {
        super.init(map: map)
    }
    
    open override func mapping(map: Map) {
        links <- (map["_links"], ResourceLinkTransformType())
        created <- map["createdTs"]
        createdEpoch <- (map["createdTsEpoch"], NSTimeIntervalTransform())
        deviceIdentifier <- map["deviceIdentifier"]
        deviceName <- map["deviceName"]
        deviceType <- map["deviceType"]
        manufacturerName <- map["manufacturerName"]
        serialNumber <- map["serialNumber"]
        modelNumber <- map["modelNumber"]
        hardwareRevision <- map["hardwareRevision"]
        firmwareRevision <- map["firmwareRevision"]
        softwareRevision <- map["softwareRevision"]
        notificationToken <- map["notificationToken"]
        osName <- map["osName"]
        systemId <- map["systemId"]
        licenseKey <- map["licenseKey"]
        bdAddress <- map["bdAddress"]
        pairing <- map["pairing"]
        
        if let cardRelationships = map["cardRelationships"].currentValue as? [Any] {
            if cardRelationships.count > 0 {
                self.cardRelationships = [CardRelationship]()
                
                for itrObj in cardRelationships {
                    if let parsedObj = Mapper<CardRelationship>().map(JSON: itrObj as! [String: Any]) {
                        self.cardRelationships!.append(parsedObj)
                    }
                }
            }
        }
        
        metadata = map.JSON
    }
    
    func copyFieldsFrom(deviceInfo: DeviceInfo) {
        self.deviceIdentifier  = deviceInfo.deviceIdentifier
        self.deviceName        = deviceInfo.deviceName
        self.deviceType        = deviceInfo.deviceType
        self.manufacturerName  = deviceInfo.manufacturerName
        self.serialNumber      = deviceInfo.serialNumber
        self.modelNumber       = deviceInfo.modelNumber
        self.hardwareRevision  = deviceInfo.hardwareRevision
        self.firmwareRevision  = deviceInfo.firmwareRevision
        self.notificationToken = deviceInfo.notificationToken
        self.osName            = deviceInfo.osName
        self.systemId          = deviceInfo.systemId
        self.licenseKey        = deviceInfo.licenseKey
        self.bdAddress         = deviceInfo.bdAddress
        self.pairing           = deviceInfo.pairing
        self.cardRelationships = deviceInfo.cardRelationships
        self.metadata          = deviceInfo.metadata
    }

}
