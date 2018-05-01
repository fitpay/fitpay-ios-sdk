//
//  FitpayEvent.swift
//  FitpaySDK
//
//  Created by Anton on 15.04.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

public enum EventStatus: Int {
    case success = 0
    case failed
    
    public func toString() -> String {
        switch self {
        case .success:
            return "OK"
        case .failed:
            return "FAILED"
        }
    }
}

open class FitpayEvent: NSObject {

    open private(set) var eventId : FitpayEventTypeProtocol
    open private(set) var status: EventStatus
    open private(set) var reason: Error?
    open private(set) var date: Date
    
    open private(set) var eventData : Any
    
    public init(eventId: FitpayEventTypeProtocol, eventData: Any, status: EventStatus = .success, reason: Error? = nil) {
        
        self.eventData = eventData
        self.eventId = eventId
        self.status = status
        self.date = Date()
        self.reason = reason
        
        super.init()
    }
}
