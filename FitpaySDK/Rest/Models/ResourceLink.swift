import Foundation

open class ResourceLink: CustomStringConvertible {
    open var target: String?
    open var href: String?
    
    open var description: String {
        return "\(ResourceLink.self)(\(target ?? "target nil"):\(href ?? "href nil"))"
    }
}

extension ResourceLink: Equatable {
    public static func == (lhs: ResourceLink, rhs: ResourceLink) -> Bool {
        return lhs.target == rhs.target && lhs.href == rhs.href
    }
    
}
