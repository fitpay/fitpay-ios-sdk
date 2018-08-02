import Foundation

class ResourceLink: CustomStringConvertible {
    var target: String?
    var href: String?
    
    var description: String {
        return "\(ResourceLink.self)(\(target ?? "target nil"):\(href ?? "href nil"))"
    }
}

extension ResourceLink: Equatable {
    static func == (lhs: ResourceLink, rhs: ResourceLink) -> Bool {
        return lhs.target == rhs.target && lhs.href == rhs.href
    }
    
}
