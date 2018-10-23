import Foundation

open class Issuers: Serializable, ClientModel {
    
    public var countries: [String: Country]?
    
    weak var client: RestClient?

    private enum CodingKeys: String, CodingKey {
        case countries
    }

    public struct Country: Serializable {
        public var cardNetworks: [String: CardNetwork]?
    }
    
    public struct CardNetwork: Serializable {
        public var issuers: [String]?
    }
}
