import Foundation

open class FitpayEventDispatcher {
    private var bindingsDictionary: [Int: [FitpayEventBinding]] = [:]
    
    public init() {
    }
    
    open func addListenerToEvent(_ listener: FitpayEventListener, eventId: FitpayEventTypeProtocol) -> FitpayEventBinding? {
        var bindingsArray = bindingsDictionary[eventId.eventId()] ?? []
        
        let binding = FitpayEventBinding(eventId: eventId, listener: listener)
        bindingsArray.append(binding)
        
        bindingsDictionary[eventId.eventId()] = bindingsArray
        
        return binding
    }
    
    open func removeBinding(_ binding: FitpayEventBinding) {
        guard var bindingsArray = bindingsDictionary[binding.eventId.eventId()] else { return }
        
        if bindingsArray.contains(binding) {
            binding.invalidate()
            bindingsArray.removeObject(binding)
            bindingsDictionary[binding.eventId.eventId()] = bindingsArray
        }
    }
    
    open func removeAllBindings() {
        for (_, bindingsArray) in bindingsDictionary {
            for binding in bindingsArray {
                binding.invalidate()
            }
        }
        
        bindingsDictionary.removeAll()
    }
    
    open func dispatchEvent(_ event: FitpayEvent) {
        guard let bindingsArray = bindingsDictionary[event.eventId.eventId()] else { return }
        
        for binding in bindingsArray {
            binding.dispatchEvent(event)
        }
    }
}
