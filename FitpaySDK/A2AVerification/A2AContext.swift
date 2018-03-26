//
//  A2AVerificationError.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 3/5/18.
//

import UIKit
import ObjectMapper

open class A2AContext: NSObject, Mappable {
    open var applicationId: String?
    open var action: String?
    open var payload: String?
    
    public required init?(map: Map) {
        super.init()
    }
    
    internal override init() {
        super.init()
    }
    
    open func mapping(map: Map) {
        applicationId <- map["applicationId"]
        action <- map["action"]
        payload <- map["payload"]
    }
}

