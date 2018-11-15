import Foundation

open class FitpayEventBinding: NSObject {
    
    open var eventId: FitpayEventTypeProtocol
    open var listener: FitpayEventListener
    
    private static var bindingIdCounter = 0
    
    private let bindingId: Int
    
    public init(eventId: FitpayEventTypeProtocol, listener: FitpayEventListener) {
        self.eventId = eventId
        self.listener = listener
        
        bindingId = FitpayEventBinding.bindingIdCounter
        FitpayEventBinding.bindingIdCounter += 1
        
        super.init()
    }
    
    override open func isEqual(_ object: Any?) -> Bool {
        return bindingId == (object as? FitpayEventBinding)?.bindingId
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
