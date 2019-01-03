import Foundation

open class RootLinks: Serializable {
    
    open var privacyPolicyResourceKeyLink: Link? {
        return links?[RootLinks.privacyPolicyResourceKey]
    }
    
    open var termsResourceKeyLink: Link? {
        return links?[RootLinks.termsResourceKey]
    }
    
    var links: [String: Link]?
    
    //    Resource Keys
    private static let privacyPolicyResourceKey = "webapp.privacyPolicy"
    private static let termsResourceKey         = "webapp.terms"
    
    private enum CodingKeys: String, CodingKey {
        case links = "_links"
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        links =  try? container.decode(.links)
    }
    
}
