import XCTest
import Nimble

@testable import FitpaySDK

// swiftlint:disable line_length
class MockModels {
    let someId = "12345fsd"
    let someType = "someType"
    let timeEpoch: Int64 = 1446587257000
    let someDate = "2015-11-03T21:47:37.324Z"
    let someDate2 = "2015-11-03T21:47:37+00:00"
    let someName = "someName"
    let someEncryptionData = "some data"
    
    func getCommitStatistic() -> CommitStatistic? {
        let commitStatistic = try? CommitStatistic("{\"commitId\":\"\(someId)\",\"processingTimeMs\":\(timeEpoch),\"averageTimePerCommand\":3,\"errorReason\":\"bad access\"}")
        expect(commitStatistic).toNot(beNil())
        return commitStatistic
    }
    
    func getTransaction() -> Transaction? {
        let transaction = try? Transaction("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"transactionId\":\"\(someId)\",\"transactionType\":\"\(someType)\",\"amount\":3.22,\"currencyCode\":\"code\",\"authorizationStatus\":\"status\",\"authorizationStatus\":\"status\",\"transactionTime\":\"time\",\"transactionTimeEpoch\":\(timeEpoch),\"merchantName\":\"\(someName)\",\"merchantCode\":\"code\",\"merchantType\":\"\(someType)\"}")
        expect(transaction).toNot(beNil())
        return transaction
    }
    
    func getUser() -> User? {
        let user = try? User("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/\"}, \"creditCards\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/creditCards\"}, \"devices\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices\"}, \"eventStream\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/eventStream\"}, \"webapp.wallet\":{\"href\":\"https://fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2?config={config}\", \"templated\": true}},\"id\":\"\(someId)\",\"createdTs\":\"\(someDate)\",\"createdTsEpoch\":\(timeEpoch),\"lastModifiedTs\":\"\(someDate)\",\"lastModifiedTsEpoch\":\(timeEpoch),\"encryptedData\":\"\(someEncryptionData)\"}")
        expect(user).toNot(beNil())
        return user
    }
    
    func getDevice(deviceId: String? = nil) -> Device? {
        let metadata = getCreditCardMetadata()?.toJSONString() ?? ""
        let deviceInfo = try? Device("{ \"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}, \"defaultCreditCard\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/creditCards/677af018-01b1-47d9-9b08-0c18d89aa2e3\"}, \"user\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2\"}, \"commits\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/commits\"}, \"lastAckCommit\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/commits/1234\"}, \"deviceResetTasks\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/commits/1234\"}}, \"profileId\":\"\(someId)\", \"deviceIdentifier\":\"\(deviceId ?? someId)\", \"deviceName\":\"\(someName)\", \"deviceType\":\"\(someType)\", \"manufacturerName\":\"\(someName)\", \"state\":\"12345fsd\", \"serialNumber\":\"987654321\", \"modelNumber\":\"1258PO\", \"hardwareRevision\":\"12345fsd\", \"firmwareRevision\":\"12345fsd\", \"softwareRevision\":\"12345fsd\", \"notificationToken\":\"12345fsd\", \"createdTsEpoch\":\(timeEpoch), \"createdTs\":\"\(someDate)\", \"osName\":\"\(someName)\", \"systemId\": \"\(someId)\",\"licenseKey\":\"147PLO\", \"bdAddress\":\"someAddress\", \"pairing\":\"pairing\", \"secureElement\": { \"secureElementId\":\"\(someId)\", \"casdCert\":\"casd\" }, \"metadata\":\(metadata), \"defaultCreditCardId\": \"\(someId)\" }")
        expect(deviceInfo).toNot(beNil())
        return deviceInfo
    }

    func getFailedDevice(deviceId: String? = nil) -> Device? {
        let metadata = getCreditCardMetadata()?.toJSONString() ?? ""
        let deviceInfo = try? Device("{ \"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}, \"defaultCreditCard\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/creditCards/677af018-01b1-47d9-9b08-0c18d89aa2e3\"}, \"user\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2\"}, \"commits\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/commits\"}, \"lastAckCommit\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/commits/1234\"}, \"deviceResetTasks\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/commits/1234\"}}, \"profileId\":\"\(someId)\", \"deviceIdentifier\":\"\(deviceId ?? someId)\", \"deviceName\":\"\(someName)\", \"deviceType\":\"\(someType)\", \"manufacturerName\":\"\(someName)\", \"state\":\"FAILED_INITIALIZATION\", \"lastStateTransitionReasonCode\":321, \"lastStateTransitionReasonMessage\":\"SomeError\", \"serialNumber\":\"987654321\", \"modelNumber\":\"1258PO\", \"hardwareRevision\":\"12345fsd\", \"firmwareRevision\":\"12345fsd\", \"softwareRevision\":\"12345fsd\", \"notificationToken\":\"12345fsd\", \"createdTsEpoch\":\(timeEpoch), \"createdTs\":\"\(someDate)\", \"osName\":\"\(someName)\", \"systemId\": \"\(someId)\",\"licenseKey\":\"147PLO\", \"bdAddress\":\"someAddress\", \"pairing\":\"pairing\", \"secureElement\": { \"secureElementId\":\"\(someId)\", \"casdCert\":\"casd\" }, \"metadata\":\(metadata), \"defaultCreditCardId\": \"\(someId)\" }")
        expect(deviceInfo).toNot(beNil())
        return deviceInfo
    }
    
    func getDeviceInfoNoLinks() -> Device? {
        let metadata = getCreditCardMetadata()?.toJSONString() ?? ""
        let deviceInfo = try? Device("{\"profileId\":\"\(someId)\", \"deviceIdentifier\":\"\(someId)\", \"deviceName\":\"\(someName)\", \"deviceType\":\"\(someType)\", \"manufacturerName\":\"\(someName)\", \"state\":\"12345fsd\", \"serialNumber\":\"987654321\", \"modelNumber\":\"1258PO\", \"hardwareRevision\":\"12345fsd\", \"firmwareRevision\":\"12345fsd\", \"softwareRevision\":\"12345fsd\", \"notificationToken\":\"12345fsd\", \"createdTsEpoch\":\(timeEpoch), \"createdTs\":\"\(someDate)\", \"osName\":\"\(someName)\", \"systemId\": \"\(someId)\",\"licenseKey\":\"147PLO\", \"bdAddress\":\"someAddress\", \"pairing\":\"pairing\", \"secureElement\": { \"secureElementId\":\"\(someId)\", \"casdCert\":\"casd\" }, \"metadata\":\(metadata), \"defaultCreditCardId\": \"\(someId)\" }")
        expect(deviceInfo).toNot(beNil())
        return deviceInfo
    }
    
    func getCommit() -> Commit? {
        let commit = try? Commit("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}, \"confirm\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9/confirm\"}},\"commitType\":\"UNKNOWN\",\"createdTs\":\(timeEpoch),\"commitId\":\"\(someId)\",\"previousCommit\":\"2\",\"encryptedData\":\"\(someEncryptionData)\"}")
        expect(commit).toNot(beNil())
        return commit
    }
    
    func getAPDUCommit() -> Commit? {
        let commit = try? Commit("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}, \"confirm\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9/confirm\"}, \"apduResponse\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9/apduResponse\"}},\"commitType\":\"APDU_PACKAGE\",\"createdTs\":\(timeEpoch),\"commitId\":\"\(someId)\",\"previousCommit\":\"2\",\"encryptedData\":\"\(someEncryptionData)\"}")
        expect(commit).toNot(beNil())
        return commit
    }
    
    func getCommitMetrics() -> CommitMetrics? {
        let commitStatistic = getCommitStatistic()?.toJSONString() ?? ""
        let commit = try? CommitMetrics("{\"syncId\":\"\(someId)\",\"deviceId\":\"\(someId)\",\"userId\":\"\(someId)\",\"sdkVersion\":\"1\",\"osVersion\":\"2\",\"totalProcessingTimeMs\":\(timeEpoch),\"initiator\":\"PLATFORM\",\"commits\":[\(commitStatistic)]}")
        expect(commit).toNot(beNil())
        return commit
    }
    
    func getApduPackage() -> ApduPackage? {
        let apduCommand = getApduCommand()?.toJSONString() ?? ""
        let apduPackage = try? ApduPackage("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"seIdType\": \"\(someType)\", \"targetDeviceType\": \"\(someType)\", \"targetDeviceId\": \"\(someId)\", \"packageId\": \"\(someId)\", \"seId\": \"\(someId)\", \"commandApdus\": [\(apduCommand)], \"state\": \"PROCESSED\", \"executedEpoch\": \(timeEpoch), \"executedDuration\": 5.0, \"validUntil\": \"\(someDate)\", \"validUntilEpoch\":\"\(someDate)\", \"apduPackageUrl\": \"www.example.com\"}")
        expect(apduPackage).toNot(beNil())
        return apduPackage
    }
    
    func getApduCommand() -> APDUCommand? {
        let apduCommand = try? APDUCommand("{\"commandId\": \"\(someId)\", \"groupId\": 1, \"sequence\": 1, \"command\": \"command\", \"type\": \"\(someType)\", \"continueOnFailure\": true}")
        expect(apduCommand).toNot(beNil())
        return apduCommand
    }
    
    func getApduCommandWithMissingItems() -> APDUCommand? {
        let apduCommand = try? APDUCommand("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"commandId\": \"\(someId)\", \"command\": \"command\", \"type\": \"\(someType)\"}")
        expect(apduCommand).toNot(beNil())
        return apduCommand
    }
    
    func getEncryptionKey() -> EncryptionKey? {
        let encryptionKey = try? EncryptionKey("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"keyId\": \"\(someId)\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"expirationTs\": \"\(someDate)\", \"expirationTsEpoch\": \(timeEpoch), \"serverPublicKey\": \"someKey\", \"clientPublicKey\": \"someKey\", \"active\": true}")
        expect(encryptionKey).toNot(beNil())
        return encryptionKey
    }
    
    func getVerificationMethod() -> VerificationMethod? {
        let a2AContext = getA2AContext()?.toJSONString() ?? ""
        let verificationMethod = try? VerificationMethod("{\"_links\":{\"select\":{\"href\":\"https://api.fit-pay.com/select\"}, \"verify\":{\"href\":\"https://api.fit-pay.com/verify\"}, \"card\":{\"href\":\"https://api.fit-pay.com/creditCards\"}},\"verificationId\": \"\(someId)\", \"state\": \"AVAILABLE_FOR_SELECTION\", \"methodType\": \"TEXT_TO_CARDHOLDER_NUMBER\", \"value\": \"someValue\", \"verificationResult\": \"SUCCESS\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"lastModifiedTs\": \"\(someDate)\", \"lastModifiedTsEpoch\": \(timeEpoch), \"verifiedTs\": \"\(someDate)\", \"verifiedTsEpoch\": \(timeEpoch), \"appToAppContext\":\(a2AContext)}")
        expect(verificationMethod).toNot(beNil())
        return verificationMethod
    }
    
    func getVerificationMethodWithoutLinks() -> VerificationMethod? {
        let a2AContext = getA2AContext()?.toJSONString() ?? ""
        let verificationMethod = try? VerificationMethod("{\"verificationId\": \"\(someId)\", \"state\": \"AVAILABLE_FOR_SELECTION\", \"methodType\": \"TEXT_TO_CARDHOLDER_NUMBER\", \"value\": \"someValue\", \"verificationResult\": \"SUCCESS\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"lastModifiedTs\": \"\(someDate)\", \"lastModifiedTsEpoch\": \(timeEpoch), \"verifiedTs\": \"\(someDate)\", \"verifiedTsEpoch\": \(timeEpoch), \"appToAppContext\":\(a2AContext)}")
        expect(verificationMethod).toNot(beNil())
        return verificationMethod
    }
    
    func getA2AContext() -> A2AContext? {
        let a2AContext = try? A2AContext("{\"applicationId\": \"\(someId)\", \"action\": \"someAction\", \"payload\": \"somePayload\"}")
        expect(a2AContext).toNot(beNil())
        return a2AContext
    }
    
    func getCreditCardInfo() -> CardInfo? {
        let address = getAddress()?.toJSONString() ?? ""
        let riskData = getIdVerification()?.toJSONString() ?? ""
        let cardInfo = try? CardInfo("{\"pan\":\"pan\", \"expMonth\": 2, \"expYear\": 2018, \"cvv\":\"cvv\", \"creditCardId\": \"\(someId)\", \"name\": \"\(someName)\", \"address\": \(address), \"riskData\": \(riskData)}")
        return cardInfo
    }
    
    func getCreditCardInfoWithNilValues() -> CardInfo? {
        let cardInfo = try? CardInfo("{\"pan\":\"pan\", \"creditCardId\": \"\(someId)\", \"name\": \"\(someName)\"}")
        return cardInfo
    }
    
    func getCreditCard() -> CreditCard? {
        let apduCommand = getApduCommand()?.toJSONString() ?? ""

        let creditCard = try? CreditCard("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9\"}, \"acceptTerms\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/acceptTerms\"}, \"declineTerms\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/declineTerms\"}, \"deactivate\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/deactivate\"}, \"reactivate\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/reactivate\"}, \"makeDefault\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/makeDefault\"}, \"transactions\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/transactions\"}, \"verificationMethods\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/verificationMethods\"}, \"selectedVerification\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/selectedVerification\"}, \"webapp.card\":{\"href\":\"https://fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/creditcards/57717bdb6d213e810137ee21adb7e883fe0904e9/config={config}\", \"templated\": true}}, \"creditCardId\": \"\(someId)\",\"userId\": \"\(someId)\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"state\": \"NOT_ELIGIBLE\", \"cardType\": \"\(someType)\", \"termsAssetId\": \"\(someId)\", \"eligibilityExpiration\": \"\(someDate)\", \"eligibilityExpirationEpoch\": \(timeEpoch), \"encryptedData\":\"\(someEncryptionData)\", \"targetDeviceId\": \"\(someId)\", \"targetDeviceType\": \"\(someType)\", \"externalTokenReference\": \"someToken\", \"offlineSeActions\": {\"topOfWallet\": {\"apduCommands\": [\(apduCommand)]}}, \"tokenLastFour\": \"4321\"}")
        
        creditCard?.cardMetaData = getCreditCardMetadata()
        creditCard?.termsAssetReferences = [getTermsAssetReferences()!]
        creditCard?.verificationMethods = [getVerificationMethod()!]
        creditCard?.info = getCreditCardInfo()
        expect(creditCard).toNot(beNil())
        return creditCard
    }
    
    func getCreditCardMetadata() -> CardMetadata? {
        let image = getImage()?.toJSONString() ?? ""
        let creditCardMetadata = try? CardMetadata("{\"foregroundColor\":\"00000\",\"issuerName\":\"\(someName)\",\"shortDescription\":\"Chase Freedom Visa\",\"longDescription\":\"Chase Freedom Visa with the super duper rewards\",\"contactUrl\":\"www.chase.com\",\"contactPhone\":\"18001234567\",\"contactEmail\":\"goldcustomer@chase.com\",\"termsAndConditionsUrl\":\"http://visa.com/terms\",\"privacyPolicyUrl\":\"http://visa.com/privacy\",\"brandLogo\":[\(image)],\"coBrandLogo\":[\(image)],\"cardBackground\":[\(image)],\"cardBackgroundCombined\":[\(image)],\"cardBackgroundCombinedEmbossed\":[\(image)],\"icon\":[\(image),\(image)],\"issuerLogo\":[\(image)]}")
        expect(creditCardMetadata).toNot(beNil())
        return creditCardMetadata
    }
    
    func getTermsAssetReferences() -> TermsAssetReferences? {
        let termsAssetReferences = try? TermsAssetReferences("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/termsAssetReference\"}},\"mimeType\":\"text/html\"}")
        expect(termsAssetReferences).toNot(beNil())
        return termsAssetReferences
    }
    
    func getAddress() -> Address? {
        let address = try? Address("{\"street1\":\"1035 Pearl St\",\"street2\":\"5th Floor\",\"street3\":\"8th Floor\",\"city\":\"Boulder\",\"state\":\"CO\",\"postalCode\":\"80302\",\"countryCode\":\"US\"}")
        expect(address).toNot(beNil())
        return address
    }
    
    func getImage() -> Image? {
        let image = try? Image("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/assets?assetId=-498647650&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=40\", \"encryptedData\": \"\(someEncryptionData)\"}},\"mimeType\":\"image/gif\",\"height\":20,\"width\":60}")
        expect(image).toNot(beNil())
        return image
    }
    
    func getImageWithOptions() -> ImageWithOptions? {
        let image = try? ImageWithOptions("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/assets?assetId=-498647650&adapterId=1131178c-aab5-438b-ab9d-a6572cb64c8c&adapterData=40\", \"encryptedData\": \"\(someEncryptionData)\"}},\"mimeType\":\"image/gif\",\"height\":20,\"width\":60}")
        expect(image).toNot(beNil())
        return image
    }
    
    func getRtmConfig() -> RtmConfig? {
        let info = getDevice()?.toJSONString() ?? ""
        let rtmConfig = try? RtmConfig("{\"clientId\":\"\(someId)\",\"redirectUri\":\"https://api.fit-pay.com\",\"userEmail\":\"someEmail\",\"paymentDevice\":\(info),\"account\":false,\"version\":\"2\",\"demoMode\":false,\"themeOverrideCssUrl\":\"https://api.fit-pay.com\",\"demoCardGroup\":\"someGroup\",\"accessToken\":\"someToken\",\"language\":\"en\",\"baseLangUrl\":\"https://api.fit-pay.com\",\"useWebCardScanner\":false}")
        expect(rtmConfig).toNot(beNil())
        return rtmConfig
    }
    
    func getRtmMessageResponse() -> RtmMessageResponse? {
        let rtmMessage = try? RtmMessageResponse("{\"callBackId\":1,\"data\":{\"data\":\"someData\"},\"type\":\"\(someType)\", \"isSuccess\":true}")
        expect(rtmMessage).toNot(beNil())
        return rtmMessage
    }
    
    func getIssuers() -> Issuers? {
        let issuers = try? Issuers("{\"countries\": {\"US\":{\"cardNetworks\":{\"VISA\":{\"issuers\":[\"Local Government Federal Credit Union\",\"Bank of America\",\"Commerce Bank\",\"U.S. Bank\",\"Capital One\"]}}}}}")
        expect(issuers).toNot(beNil())
        return issuers
    }
    
    func getResultCollection() -> ResultCollection<Device>? {
        let device = getDevice()?.toJSONString() ?? ""
        let resultCollection = try? ResultCollection<Device>("{\"_links\":{\"next\":{\"href\":\"https://api.fit-pay.com/next\"}, \"last\":{\"href\":\"https://api.fit-pay.com/last\"}, \"previous\":{\"href\":\"https://api.fit-pay.com/previous\"}}, \"limit\":1, \"offset\":1, \"totalResults\":1, \"results\":[\(device)]}")
        expect(resultCollection).toNot(beNil())
        return resultCollection
    }
    
    func getResultVerificationMethodCollection() -> ResultCollection<Device>? {
        let verificationMethod = getVerificationMethod()?.toJSONString() ?? ""
        let resultCollection = try? ResultCollection<Device>("{\"totalResults\":1, \"verificationMethods\":[\(verificationMethod)]}")
        expect(resultCollection).toNot(beNil())
        return resultCollection
    }

    func getIdVerification() -> IdVerification? {
        let idVerification = try? IdVerification("{\"oemAccountInfoUpdatedDate\": \"\(someDate2)\", \"oemAccountCreatedDate\": \"\(someDate2)\", \"suspendedCardsInAccount\": 1, \"daysSinceLastAccountActivity\": 6, \"deviceLostMode\": 7, \"deviceWithActiveTokens\": 2, \"activeTokenOnAllDevicesForAccount\": 3, \"accountScore\": 4, \"deviceScore\": 5, \"nfcCapable\": false, \"oemAccountCountryCode\": \"US\", \"deviceCountry\": \"US\", \"oemAccountUserName\": \"\(someName)\", \"devicePairedToOemAccountDate\": \"\(someDate2)\", \"deviceTimeZone\": \"CST\", \"deviceTimeZoneSetBy\": 0, \"deviceIMEI\": \"123456\"}")
        expect(idVerification).toNot(beNil())
        return idVerification
    }
    
    func getNotificationDetailOld() -> NotificationDetail? {
        let notificationDetail = try? NotificationDetail("{\"_links\":{\"ackSync\":{\"href\":\"https://api.fit-pay.com/ackSync\"}}, \"id\":\"\(someId)\"}")
        expect(notificationDetail).toNot(beNil())
        return notificationDetail
    }
    
    func getNotificationDetail() -> NotificationDetail? {
        let notificationDetail = try? NotificationDetail("{\"_links\":{\"ackSync\":{\"href\":\"https://api.fit-pay.com/ackSync\"}, \"creditCard\":{\"href\":\"https://api.fit-pay.com/creditCards/\(someId)\"}, \"device\":{\"href\":\"https://api.fit-pay.com/devices/\(someId)\"}},\"type\": \"\(someType)\", \"syncId\":\"\(someId)\", \"deviceId\": \"\(someId)\", \"userId\": \"\(someId)\", \"clientId\": \"\(someId)\", \"creditCardId\": \"\(someId)\"}")
        expect(notificationDetail).toNot(beNil())
        return notificationDetail
    }
    
    func getResetDeviceResult() -> ResetDeviceResult? {
        let resetDeviceResult = try? ResetDeviceResult("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/resetDeviceTasks/464c0897-dd8a-45d5-bc5b-5592cddb363e\"}},\"resetId\":\"464c0897-dd8a-45d5-bc5b-5592cddb363e\",\"status\":\"IN_PROGRESS\",\"seStatus\":\"IN_PROGRESS\"}")
        XCTAssertNotNil(resetDeviceResult)
        return resetDeviceResult
    }

    func getPayload() -> Payload? {
        let creditCard = getCreditCard()?.toJSONString()
        let payload = try? Payload(creditCard)
        expect(payload).toNot(beNil())
        return payload
    }
    
    func getPlatformConfig() -> PlatformConfig? {
        let config = try? PlatformConfig("{\"userEventStreamsEnabled\": true}")
        expect(config).toNot(beNil())
        return config
    }
    
}
