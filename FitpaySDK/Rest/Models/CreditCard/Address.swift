/// Address
@objc open class Address: NSObject, Serializable {
    
    /// The billing address street name and number
    @objc open var street1: String?
    
    /// The billing address unit or suite number, if available
    @objc open var street2: String?
    
    /// Additional billing address unit or suite number, if available
    @objc open var street3: String?
    
    /// The billing address city
    @objc open var city: String?
    
    /// The billing address state 2 letter code
    @objc open var state: String?
    
    /// The billing address five-digit zip code
    @objc open var postalCode: String?
    
    /// The billing address country code in ISO 3166-1 alpha-2 format
    @objc open var countryCode: String?
    
    /// Initialize class with all optional variables
    @objc public init(street1: String?, street2: String?, street3: String?, city: String?, state: String?, postalCode: String?, countryCode: String?) {
        super.init()
        
        self.street1 = street1
        self.street2 = street2
        self.street3 = street3
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.countryCode = countryCode
    }
    
}
