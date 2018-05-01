extension Array {
    var JSONString: String? {
        return Foundation.JSONSerialization.JSONString(self)
    }
}

extension Array where Element: ResourceLink {
    func url(_ resource: String) -> String? {
        for link in self {
            if let target = link.target, target == resource {
                return link.href
            }
        }
        
        return nil
    }

    mutating func indexOf(_ target: String) -> Element? {
        guard let index = self.index(where: {$0.target == target}) else { return nil }
        let link = self[index]
        return link
    }
}

extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
}

//Stack - LIFO
extension Array {
    mutating func push(_ newElement: Element) {
        self.append(newElement)
    }
    
    mutating func pop() -> Element? {
        return self.removeLast()
    }
    
    func peekAtStack() -> Element? {
        return self.last
    }
}

//Queue - FIFO
extension Array {
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
