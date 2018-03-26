//
//  A2AVerificationError.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 3/5/18.
//

import UIKit
import ObjectMapper

public class A2AVerificationRequest : NSObject, Mappable {
    open var cardType: String?
    open var returnLocation: String?
    open var context: A2AContext?
    
    public required init?(map: Map) {
        super.init()
    }
    
    internal override init() {
        super.init()
    }
    
    open func mapping(map: Map) {
        cardType <- map["cardType"]
        returnLocation <- map["returnLocation"]
        context <- map["context"]
    }
}
