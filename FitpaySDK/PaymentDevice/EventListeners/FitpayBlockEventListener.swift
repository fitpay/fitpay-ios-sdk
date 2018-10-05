import Foundation

open class FitpayBlockEventListener {
    
    public typealias BlockCompletion = (_ event: FitpayEvent) -> Void
    
    var blockCompletion: BlockCompletion
    var completionQueue: DispatchQueue

    private var isValid = true
    
    public init(completion: @escaping BlockCompletion, queue: DispatchQueue = DispatchQueue.main) {
        self.blockCompletion = completion
        self.completionQueue = queue
    }
}

extension FitpayBlockEventListener: FitpayEventListener {
    
    public func dispatchEvent(_ event: FitpayEvent) {
        guard isValid else { return }
        
        completionQueue.async {
            self.blockCompletion(event)
        }
    }
    
    public func invalidate() {
        isValid = false
    }
}
