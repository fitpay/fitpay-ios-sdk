import XCTest
@testable import FitpaySDK

class MockModels {
    let someId = "12345fsd"
    let someType = "someType"
    let timeEpoch: Int64 = 1446587257000
    let someDate = "2015-11-03T21:47:37.324Z"
    let someName = "someName"
    let someEncryptionData = "some data"

    func getCommitStatistic() -> CommitStatistic? {
        let commitStatistic = try? CommitStatistic("{\"commitId\":\"\(someId)\",\"processingTimeMs\":\(timeEpoch),\"averageTimePerCommand\":3,\"errorReason\":\"bad access\"}")
        XCTAssertNotNil(commitStatistic)
        return commitStatistic
    }

    func getTransaction() -> Transaction? {
        let transaction = try? Transaction("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"transactionId\":\"\(someId)\",\"transactionType\":\"\(someType)\",\"amount\":3.22,\"currencyCode\":\"code\",\"authorizationStatus\":\"status\",\"authorizationStatus\":\"status\",\"transactionTime\":\"time\",\"transactionTimeEpoch\":\(timeEpoch),\"merchantName\":\"\(someName)\",\"merchantCode\":\"code\",\"merchantType\":\"\(someType)\"}")
        XCTAssertNotNil(transaction)
        return transaction
    }

    func getUser() -> User? {
        let user = try? User("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"id\":\"\(someId)\",\"createdTs\":\"\(someDate)\",\"createdTsEpoch\":\(timeEpoch),\"lastModifiedTs\":\"\(someDate)\",\"lastModifiedTsEpoch\":\(timeEpoch),\"encryptedData\":\"\(someEncryptionData)\"}")
        XCTAssertNotNil(user)
        return user
    }

    func getDeviceInfo() -> DeviceInfo? {
        let cardRelationship = getCardRelationship()?.toJSONString() ?? ""
        let deviceInfo = try? DeviceInfo ("{ \"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"deviceIdentifier\":\"\(someId)\", \"deviceName\":\"\(someName)\", \"deviceType\":\"\(someType)\", \"manufacturerName\":\"\(someName)\", \"state\":\"12345fsd\", \"serialNumber\":\"987654321\", \"modelNumber\":\"1258PO\", \"hardwareRevision\":\"12345fsd\",  \"firmwareRevision\":\"12345fsd\", \"softwareRevision\":\"12345fsd\", \"notificationToken\":\"12345fsd\", \"createdTsEpoch\":\(timeEpoch), \"createdTs\":\"\(someDate)\", \"osName\":\"\(someName)\", \"systemId\":\"\(someId)\", \"cardRelationships\": [\(cardRelationship)],\"licenseKey\":\"147PLO\", \"bdAddress\":\"someAddress\", \"pairing\":\"pairing\", \"secureElementId\":\"\(someId)\", \"casd\":\"casd\"}")
        XCTAssertNotNil(deviceInfo)
        return deviceInfo
    }

    func getCardRelationship() -> CardRelationship? {
        let cardRelationship = try? CardRelationship ("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"creditCardId\": \"\(someId)\", \"pan\":\"1234\", \"expMonth\": 2, \"expYear\": 2018}")
        XCTAssertNotNil(cardRelationship)
        return cardRelationship
    }

    func getCommit() -> Commit? {
        let commit = try? Commit("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"commitType\":\"\(someType)\",\"createdTs\":\(timeEpoch),\"commitId\":\"\(someId)\",\"previousCommit\":\"2\",\"encryptedData\":\"\(someEncryptionData)\"}")
        XCTAssertNotNil(commit)
        return commit
    }

    func getCommitMetrics() -> CommitMetrics? {
        let commitStatistic = getCommitStatistic()?.toJSONString() ?? ""
        let commit = try? CommitMetrics("{\"syncId\":\"\(someId)\",\"deviceId\":\"\(someId)\",\"userId\":\"\(someId)\",\"sdkVersion\":\"1\",\"osVersion\":\"2\",\"totalProcessingTimeMs\":\(timeEpoch),\"initiator\":\"PLATFORM\",\"commits\":[\(commitStatistic)]}")
        XCTAssertNotNil(commit)
        return commit
    }

    func getApduPackage() -> ApduPackage? {
        let apduCommand = getApduCommand()?.toJSONString() ?? ""
        let apduPackage = try? ApduPackage("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"seIdType\": \"\(someType)\", \"targetDeviceType\": \"\(someType)\", \"targetDeviceId\": \"\(someId)\", \"packageId\": \"\(someId)\", \"seId\": \"\(someId)\", \"commandApdus\": [\(apduCommand)], \"state\": \"PROCESSED\", \"executedEpoch\": \(timeEpoch), \"executedDuration\": 5.0, \"validUntil\": \"\(someDate)\", \"validUntilEpoch\":\"\(someDate)\", \"apduPackageUrl\": \"www.example.com\"}")
        XCTAssertNotNil(apduPackage)
        return apduPackage
    }

    func getApduCommand() -> APDUCommand? {
        let apduCommand = try? APDUCommand("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"commandId\": \"\(someId)\", \"groupId\": 1, \"sequence\": 1, \"command\": \"command\", \"type\": \"\(someType)\", \"continueOnFailure\": true}")
        XCTAssertNotNil(apduCommand)
        return apduCommand
    }

    func getEncryptionKey() -> EncryptionKey? {
        let encryptionKey = try? EncryptionKey("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"keyId\": \"\(someId)\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"expirationTs\": \"\(someDate)\", \"expirationTsEpoch\": \(timeEpoch), \"serverPublicKey\": \"someKey\", \"clientPublicKey\": \"someKey\", \"active\": true}")
        XCTAssertNotNil(encryptionKey)
        return encryptionKey
    }

    func getVerificationMethod() -> VerificationMethod? {
        let a2AContext = getA2AContext()?.toJSONString() ?? ""
        let encryptionKey = try? VerificationMethod("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"verificationId\": \"\(someId)\", \"state\": \"AVAILABLE_FOR_SELECTION\", \"methodType\": \"TEXT_TO_CARDHOLDER_NUMBER\", \"value\": \"someValue\", \"verificationResult\": \"SUCCESS\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"lastModifiedTs\": \"\(someDate)\", \"lastModifiedTsEpoch\": \(timeEpoch), \"verifiedTs\": \"\(someDate)\", \"verifiedTsEpoch\": \(timeEpoch), \"appToAppContext\":\(a2AContext)}")
        XCTAssertNotNil(encryptionKey)
        return encryptionKey
    }

    func getA2AContext() -> A2AContext? {
        let a2AContext = try? A2AContext("{\"applicationId\": \"\(someId)\", \"action\": \"someAction\", \"payload\": \"somePayload\"}")
        XCTAssertNotNil(a2AContext)
        return a2AContext
    }

    func getCreditCardInfo() -> CardInfo? {
        let address = getAddress()?.toJSONString() ?? ""
        let cardInfo = try? CardInfo("{\"pan\":\"pan\", \"expMonth\": 2, \"expYear\": 2018, \"cvv\":\"cvv\", \"creditCardId\": \"\(someId)\", \"name\": \"\(someName)\",\"address\": \(address)}")
        return cardInfo
    }

    func getCreditCard() -> CreditCard? {
        let cardMetadata = getCreditCardMetadata()?.toJSONString() ?? ""
        let termsAssetReferences = getTermsAssetReferences()?.toJSONString() ?? ""
        let deviceRelationship = getDeviceRelationship()?.toJSONString() ?? ""
        let verificationMethod = getVerificationMethod()?.toJSONString() ?? ""
        let address = getAddress()?.toJSONString() ?? ""
        let apduCommand = getApduCommand()?.toJSONString() ?? ""
        let creditCardInfo = getCreditCardInfo()

        let creditCard = try? CreditCard("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"creditCardId\": \"\(someId)\",\"userId\": \"\(someId)\", \"default\": true,  \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"state\": \"NOT_ELIGIBLE\", \"cardType\": \"\(someType)\", \"cardMetaData\": \(cardMetadata), \"termsAssetId\": \"\(someId)\", \"termsAssetReferences\": [\(termsAssetReferences)], \"eligibilityExpiration\": \"\(someDate)\", \"eligibilityExpirationEpoch\": \(timeEpoch), \"deviceRelationships\": [\(deviceRelationship)], \"encryptedData\":\"\(someEncryptionData)\", \"targetDeviceId\": \"\(someId)\", \"targetDeviceType\": \"\(someType)\", \"verificationMethods\": [\(verificationMethod)], \"externalTokenReference\": \"someToken\", \"pan\": \"1234\", \"expMonth\": 12, \"expYear\": 2018, \"cvv\": \"123\", \"name\": \"\(someName)\", \"address\": \(address), \"offlineSeActions.topOfWallet.apduCommands\": [\(apduCommand)]}")
        creditCard?.info = creditCardInfo
        XCTAssertNotNil(creditCard)
        return creditCard
    }

     func getCreditCardMetadata() -> CardMetadata? {
        let image = getImage()?.toJSONString() ?? ""
        let creditCardMetadata = try? CardMetadata("{\"labelColor\":\"00000\",\"issuerName\":\"\(someName)\",\"shortDescription\":\"Chase Freedom Visa\",\"longDescription\":\"Chase Freedom Visa with the super duper rewards\",\"contactUrl\":\"www.chase.com\",\"contactPhone\":\"18001234567\",\"contactEmail\":\"goldcustomer@chase.com\",\"termsAndConditionsUrl\":\"http://visa.com/terms\",\"privacyPolicyUrl\":\"http://visa.com/privacy\",\"brandLogo\":[\(image)],\"cardBackground\":[\(image)],\"cardBackgroundCombined\":[\(image)],\"icon\":[\(image),[\(image)]],\"issuerLogo\":[\(image)]}")
        XCTAssertNotNil(creditCardMetadata)
        return creditCardMetadata
    }

    func getTermsAssetReferences() -> TermsAssetReferences? {
        let termsAssetReferences = try? TermsAssetReferences("{\"_links\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"},\"mimeType\":\"text/html\"}")
        XCTAssertNotNil(termsAssetReferences)
        return termsAssetReferences
    }

    func getDeviceRelationship() -> DeviceRelationships? {
        let deviceRelationship = try? DeviceRelationships("{\"deviceType\":\"\(someType)\",\"deviceIdentifier\":\"677af018-01b1-47d9-9b08-0c18d89aa2e3\",\"manufacturerName\":\"Pebble\",\"deviceName\":\"Pebble Time\",\"serialNumber\":\"074DCC022E14\",\"modelNumber\":\"FB404\",\"hardwareRevision\":\"1.0.0.0\",\"firmwareRevision\":\"1030.6408.1309.0001\",\"softwareRevision\":\"2.0.242009.6\",\"createdTs\":\"\(someDate)\",\"createdTsEpoch\":\(timeEpoch),\"osName\":\"ANDROID\",\"systemId\":\"\(someId)\"}")
        XCTAssertNotNil(deviceRelationship)
        return deviceRelationship

    }

    func getAddress() -> Address? {
        let address = try? Address("{\"street1\":\"1035 Pearl St\",\"street2\":\"5th Floor\",\"street3\":\"8th Floor\",\"city\":\"Boulder\",\"state\":\"CO\",\"postalCode\":\"80302\",\"countryCode\":\"US\"}")
        XCTAssertNotNil(address)
        return address
    }

    func getImage() -> Image? {
        let image = try? Image("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}},\"mimeType\":\"image/gif\",\"height\":20,\"width\":60}")
        XCTAssertNotNil(image)
        return image
    }

    func getRtmConfig() -> RtmConfig? {
        let info = getDeviceInfo()?.toJSONString() ?? ""
        let rtmConfig = try? RtmConfig("{\"clientId\":\"\(someId)\",\"redirectUri\":\"https://api.fit-pay.com\",\"userEmail\":\"someEmail\",\"paymentDevice\":\(info),\"account\":false,\"version\":\"2\",\"demoMode\":false,\"themeOverrideCssUrl\":\"https://api.fit-pay.com\",\"demoCardGroup\":\"someGroup\",\"accessToken\":\"someToken\",\"language\":\"en\",\"baseLangUrl\":\"https://api.fit-pay.com\",\"useWebCardScanner\":false}")
        XCTAssertNotNil(rtmConfig)
        return rtmConfig
    }

    func getRtmMessageResponse() -> RtmMessageResponse? {
        let rtmMessage = try? RtmMessageResponse("{\"callBackId\":1,\"data\":{\"data\":\"someData\"},\"type\":\"\(someType)\", \"isSuccess\":true}")
        XCTAssertNotNil(rtmMessage)
        return rtmMessage
    }

    func getRelationship() -> Relationship? {
        let deviceInfo = getDeviceInfo()?.toJSONString() ?? ""
        let cardInfo = getCreditCard()?.info?.toJSONString() ?? ""
        let relationship = try? Relationship("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"card\":\(cardInfo), \"device\":\(deviceInfo)}")
        XCTAssertNotNil(relationship)
        return relationship
    }

    func getIssuers() -> Issuers? {
        let issuers = try? Issuers("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"countries\": {\"cardNetworks\":{\"issuers\":[\"someNetwork\"]}}}")
    XCTAssertNotNil(issuers)
    return issuers
    }

    func getResultCollection() -> ResultCollection<DeviceInfo>? {
    let info = getDeviceInfo()?.toJSONString() ?? ""
    let resultCollection = try? ResultCollection<DeviceInfo>("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"limit\":1, \"offset\":1, \"totalResults\":1, \"results\":[\(info)]}")
    XCTAssertNotNil(resultCollection)
    return resultCollection
    }

}
