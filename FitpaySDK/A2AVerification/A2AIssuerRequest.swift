//
//  A2AIssuerResponse.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 3/6/18.
//

import Foundation
import ObjectMapper

public enum A2AStepupResult: String {
    case Approved  = "approved"
    case Declined  = "declined"
    case Failure   = "failure"
}

public class A2AIssuerRequest: NSObject, Mappable  {
    private var response: A2AStepupResult?
    private var authCode: String?

    public init(response: A2AStepupResult, authCode: String?) {
        self.response = response
        self.authCode = authCode
        super.init()
    }

    public required init?(map: Map) {
        super.init()
    }

    open func mapping(map: Map) {
        self.response <- map["response"]
        self.authCode <- map["authCode"]
    }

    public func toString() -> String? {
        return self.toJSONString()
    }

    public func getEncodedString() -> String? {
        guard let string = toString() else { return nil }
        return Data(string.utf8).base64URLencoded()
    }
}
