open class FitpayEventDispatcher {
    var bindingsDictionary: [Int: [FitpayEventBinding]] = [:]
    
    public init() {
    }
    
    open func addListenerToEvent(_ listener: FitpayEventListener, eventId: FitpayEventTypeProtocol) -> FitpayEventBinding? {
        var bindingsArray = self.bindingsDictionary[eventId.eventId()]
        if bindingsArray == nil {
            bindingsArray = []
        }
        
        let binding = FitpayEventBinding(eventId: eventId, listener: listener)
        bindingsArray?.append(binding)
        
        self.bindingsDictionary[eventId.eventId()] = bindingsArray
        
        return binding
    }
    
    open func removeBinding(_ binding: FitpayEventBinding) {
        if var bindingsArray = self.bindingsDictionary[binding.eventId.eventId()] {
            if bindingsArray.contains(binding) {
                binding.invalidate()
                bindingsArray.removeObject(binding)
                self.bindingsDictionary[binding.eventId.eventId()] = bindingsArray
            }
        }
    }
    
    open func removeAllBindings() {
        for (_, bindingsArray) in self.bindingsDictionary {
            for binding in bindingsArray {
                binding.invalidate()
            }
        }
        
        self.bindingsDictionary.removeAll()
    }
    
    open func dispatchEvent(_ event: FitpayEvent) {
        if let bindingsArray = self.bindingsDictionary[event.eventId.eventId()] {
            for binding in bindingsArray {
                binding.dispatchEvent(event)
            }
        }
    }
}
