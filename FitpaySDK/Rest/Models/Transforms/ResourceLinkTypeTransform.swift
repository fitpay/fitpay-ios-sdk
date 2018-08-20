import Foundation

class ResourceLinkTypeTransform: CodingContainerTransformer {
    typealias Output = [ResourceLink]
    typealias Input = [String: [String: String]]
    
    func transform(_ decoded: Input?) -> Output? {
        guard let links = decoded else {
            return nil
        }
        
        var list = [ResourceLink]()
        
        for (target, map) in links {
            let link = ResourceLink()
            link.target = target
            link.href = map["href"]
            list.append(link)
        }
        
        return list
        
    }
    
    func transform(_ encoded: Output?) -> Input? {
        guard let links = encoded else {
            return nil
        }
        
        var map = [String: [String: String]]()
        
        for link in links {
            if let target = link.target, let href = link.href {
                map[target] = ["href": href]
            }
        }
        
        return map
        
    }
}

