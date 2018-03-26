//
//  FitpayBlockEventListener.swift
//  FitpaySDK
//
//  Created by Anton on 15.04.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//


open class FitpayBlockEventListener {
    
    public typealias BlockCompletion = (_ event:FitpayEvent) -> Void
    
    var blockCompletion : BlockCompletion
    var completionQueue : DispatchQueue

    fileprivate var isValid : Bool = true
    
    public init(completion: @escaping BlockCompletion, queue: DispatchQueue = DispatchQueue.main) {
        self.blockCompletion = completion
        self.completionQueue = queue
    }
}

extension FitpayBlockEventListener : FitpayEventListener {
    public func dispatchEvent(_ event: FitpayEvent) {
        guard isValid else {
            return
        }
        
        completionQueue.async {
            
            self.blockCompletion(event)
        }
    }
    
    public func invalidate() {
        isValid = false
    }
}
