import Foundation

open class RootLinks: Serializable {
    
    /// returns the URL if privacyPolicyResourceKeyLink link is returned on the model
    open var privacyPolicyResourceKeyLink: Link? {
        return links?[RootLinks.privacyPolicyResourceKey]
    }
    
    /// returns the URL if termsResourceKeyLink link is returned on the model
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
