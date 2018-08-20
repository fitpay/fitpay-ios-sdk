import Foundation

extension Array {
    
    var JSONString: String? {
        return JSONSerialization.JSONString(self)
    }
    
    // MARK: FIFO
    mutating func enqueue(_ newElement: Element) {
        self.append(newElement)
    }
    
    mutating func dequeue() -> Element? {
        return self.count > 0 ? self.remove(at: 0) : nil
    }
    
    func peekAtQueue() -> Element? {
        return self.first
    }
    
}

extension Array where Element: ResourceLink {
    
    func url(_ target: String) -> String? {
        return first(where: { $0.target == target })?.href
    }

    func elementAt(_ target: String) -> ResourceLink? {
        return first(where: { $0.target == target })
    }
}

extension Array where Element: Equatable {
    
    mutating func removeObject(_ object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
    
}
