//
//  FitpayEventBinding.swift
//  FitpaySDK
//
//  Created by Anton on 15.04.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

open class FitpayEventBinding: NSObject {
    static fileprivate var bindingIdCounter: Int = 0
    fileprivate let bindingId: Int

    open var eventId: FitpayEventTypeProtocol
    open var listener: FitpayEventListener

    public init(eventId: FitpayEventTypeProtocol, listener: FitpayEventListener) {

        self.eventId = eventId
        self.listener = listener

        bindingId = FitpayEventBinding.bindingIdCounter
        FitpayEventBinding.bindingIdCounter += 1

        super.init()
    }
}

extension FitpayEventBinding: FitpayEventListener {
    public func dispatchEvent(_ event: FitpayEvent) {
        listener.dispatchEvent(event)
    }

    public func invalidate() {
        listener.invalidate()
    }
}

public func == (lhs: FitpayEventBinding, rhs: FitpayEventBinding) -> Bool {
    return lhs.bindingId == rhs.bindingId
}
