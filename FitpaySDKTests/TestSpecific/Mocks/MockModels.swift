import XCTest
import Nimble

@testable import FitpaySDK

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
        let user = try? User("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"id\":\"\(someId)\",\"createdTs\":\"\(someDate)\",\"createdTsEpoch\":\(timeEpoch),\"lastModifiedTs\":\"\(someDate)\",\"lastModifiedTsEpoch\":\(timeEpoch),\"encryptedData\":\"\(someEncryptionData)\"}")
        expect(user).toNot(beNil())
        return user
    }
    
    func getDeviceInfo() -> Device? {
        let metadata = getCreditCardMetadata()?.toJSONString() ?? ""
        let deviceInfo = try? Device("{ \"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"profileId\":\"\(someId)\", \"deviceIdentifier\":\"\(someId)\", \"deviceName\":\"\(someName)\", \"deviceType\":\"\(someType)\", \"manufacturerName\":\"\(someName)\", \"state\":\"12345fsd\", \"serialNumber\":\"987654321\", \"modelNumber\":\"1258PO\", \"hardwareRevision\":\"12345fsd\",  \"firmwareRevision\":\"12345fsd\", \"softwareRevision\":\"12345fsd\", \"notificationToken\":\"12345fsd\", \"createdTsEpoch\":\(timeEpoch), \"createdTs\":\"\(someDate)\", \"osName\":\"\(someName)\", \"systemId\":\"\(someId)\",\"licenseKey\":\"147PLO\", \"bdAddress\":\"someAddress\", \"pairing\":\"pairing\", \"secureElement\": { \"secureElementId\":\"\(someId)\", \"casdCert\":\"casd\" }, \"metadata\":\(metadata) }")
        expect(deviceInfo).toNot(beNil())
        return deviceInfo
    }
    
    func getCommit() -> Commit? {
        let commit = try? Commit("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}},\"commitType\":\"\(someType)\",\"createdTs\":\(timeEpoch),\"commitId\":\"\(someId)\",\"previousCommit\":\"2\",\"encryptedData\":\"\(someEncryptionData)\"}")
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
    
    func getEncryptionKey() -> EncryptionKey? {
        let encryptionKey = try? EncryptionKey("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"keyId\": \"\(someId)\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"expirationTs\": \"\(someDate)\", \"expirationTsEpoch\": \(timeEpoch), \"serverPublicKey\": \"someKey\", \"clientPublicKey\": \"someKey\", \"active\": true}")
        expect(encryptionKey).toNot(beNil())
        return encryptionKey
    }
    
    func getVerificationMethod() -> VerificationMethod? {
        let a2AContext = getA2AContext()?.toJSONString() ?? ""
        let verificationMethod = try? VerificationMethod("{\"_links\":{\"select\":{\"href\":\"https://api.fit-pay.com/select\"}, \"verify\":{\"href\":\"https://api.fit-pay.com/verify\"}, \"card\":{\"href\":\"https://api.fit-pay.com/card\"}},\"verificationId\": \"\(someId)\", \"state\": \"AVAILABLE_FOR_SELECTION\", \"methodType\": \"TEXT_TO_CARDHOLDER_NUMBER\", \"value\": \"someValue\", \"verificationResult\": \"SUCCESS\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"lastModifiedTs\": \"\(someDate)\", \"lastModifiedTsEpoch\": \(timeEpoch), \"verifiedTs\": \"\(someDate)\", \"verifiedTsEpoch\": \(timeEpoch), \"appToAppContext\":\(a2AContext)}")
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

        let creditCard = try? CreditCard("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}}, \"creditCardId\": \"\(someId)\",\"userId\": \"\(someId)\", \"createdTs\": \"\(someDate)\", \"createdTsEpoch\": \(timeEpoch), \"state\": \"NOT_ELIGIBLE\", \"cardType\": \"\(someType)\", \"termsAssetId\": \"\(someId)\", \"eligibilityExpiration\": \"\(someDate)\", \"eligibilityExpirationEpoch\": \(timeEpoch), \"encryptedData\":\"\(someEncryptionData)\", \"targetDeviceId\": \"\(someId)\", \"targetDeviceType\": \"\(someType)\", \"externalTokenReference\": \"someToken\", \"offlineSeActions.topOfWallet.apduCommands\": [\(apduCommand)], \"tokenLastFour\": \"4321\"}")
        
        creditCard?.cardMetaData = getCreditCardMetadata()
        creditCard?.termsAssetReferences = [getTermsAssetReferences()!]
        creditCard?.verificationMethods = [getVerificationMethod()!]
        creditCard?.info = getCreditCardInfo()
        expect(creditCard).toNot(beNil())
        return creditCard
    }
    
    func getCreditCardMetadata() -> CardMetadata? {
        let image = getImage()?.toJSONString() ?? ""
        let creditCardMetadata = try? CardMetadata("{\"labelColor\":\"00000\",\"issuerName\":\"\(someName)\",\"shortDescription\":\"Chase Freedom Visa\",\"longDescription\":\"Chase Freedom Visa with the super duper rewards\",\"contactUrl\":\"www.chase.com\",\"contactPhone\":\"18001234567\",\"contactEmail\":\"goldcustomer@chase.com\",\"termsAndConditionsUrl\":\"http://visa.com/terms\",\"privacyPolicyUrl\":\"http://visa.com/privacy\",\"brandLogo\":[\(image)],\"cardBackground\":[\(image)],\"cardBackgroundCombined\":[\(image)],\"icon\":[\(image),[\(image)]],\"issuerLogo\":[\(image)]}")
        expect(creditCardMetadata).toNot(beNil())
        return creditCardMetadata
    }
    
    func getTermsAssetReferences() -> TermsAssetReferences? {
        let termsAssetReferences = try? TermsAssetReferences("{\"_links\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"},\"mimeType\":\"text/html\"}")
        expect(termsAssetReferences).toNot(beNil())
        return termsAssetReferences
    }
    
    func getAddress() -> Address? {
        let address = try? Address("{\"street1\":\"1035 Pearl St\",\"street2\":\"5th Floor\",\"street3\":\"8th Floor\",\"city\":\"Boulder\",\"state\":\"CO\",\"postalCode\":\"80302\",\"countryCode\":\"US\"}")
        expect(address).toNot(beNil())
        return address
    }
    
    func getImage() -> Image? {
        let image = try? Image("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\", \"encryptedData\": \"\(someEncryptionData)\"}},\"mimeType\":\"image/gif\",\"height\":20,\"width\":60}")
        expect(image).toNot(beNil())
        return image
    }
    
    func getRtmConfig() -> RtmConfig? {
        let info = getDeviceInfo()?.toJSONString() ?? ""
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
        let issuers = try? Issuers("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"countries\": {\"cardNetworks\":{\"issuers\":[\"someNetwork\"]}}}")
        expect(issuers).toNot(beNil())
        return issuers
    }
    
    func getResultCollection() -> ResultCollection<Device>? {
        let info = getDeviceInfo()?.toJSONString() ?? ""
        let resultCollection = try? ResultCollection<Device>("{\"_links\":{\"self\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}, \"last\":{\"href\":\"https://api.fit-pay.com/users/9469bfe0-3fa1-4465-9abf-f78cacc740b2/devices/677af018-01b1-47d9-9b08-0c18d89aa2e3/commits/57717bdb6d213e810137ee21adb7e883fe0904e9\"}}, \"limit\":1, \"offset\":1, \"totalResults\":1, \"results\":[\(info)]}")
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
    
//    func getResetDeviceResult() -> ResetDeviceResult? {
//        let resetDeviceResult = try? ResetDeviceResult(loadDataFromJSONFile(filename: "resetDeviceTask"))
//        XCTAssertNotNil(resetDeviceResult)
//        return resetDeviceResult
//    }

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
