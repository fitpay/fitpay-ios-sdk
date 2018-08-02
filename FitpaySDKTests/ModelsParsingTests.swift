import XCTest
@testable import FitpaySDK

class ModelsParsingTests: XCTestCase {
    let mockModels = MockModels()

    func testCommitStatistic() {
        let commitStatistic = mockModels.getCommitStatistic()

        XCTAssertEqual(commitStatistic?.commitId, mockModels.someId)
        XCTAssertEqual(commitStatistic?.processingTimeMs, Int(mockModels.timeEpoch))
        XCTAssertEqual(commitStatistic?.averageTimePerCommand, 3)
        XCTAssertEqual(commitStatistic?.errorReason, "bad access")

        let json = commitStatistic?.toJSON()
        XCTAssertEqual(json?["commitId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["processingTimeMs"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["averageTimePerCommand"] as? Int, 3)
        XCTAssertEqual(json?["errorReason"] as? String, "bad access")
    }

    func testTransaction() {
        let transaction = mockModels.getTransaction()

        XCTAssertNotNil(transaction?.links)
        XCTAssertEqual(transaction?.transactionId, mockModels.someId)
        XCTAssertEqual(transaction?.transactionType, mockModels.someType)
        XCTAssertEqual(transaction?.amount, 3.22)
        XCTAssertEqual(transaction?.currencyCode, "code")
        XCTAssertEqual(transaction?.authorizationStatus, "status")
        XCTAssertEqual(transaction?.transactionTime, "time")
        XCTAssertEqual(transaction?.transactionTimeEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(transaction?.merchantName, mockModels.someName)
        XCTAssertEqual(transaction?.merchantCode, "code")
        XCTAssertEqual(transaction?.merchantType, mockModels.someType)

        let json = transaction?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["transactionId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["transactionType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["amount"] as? String, "3.22")
        XCTAssertEqual(json?["currencyCode"] as? String, "code")
        XCTAssertEqual(json?["authorizationStatus"] as? String, "status")
        XCTAssertEqual(json?["transactionTime"] as? String, "time")
        XCTAssertEqual(json?["transactionTimeEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["merchantName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["merchantCode"] as? String, "code")
        XCTAssertEqual(json?["merchantType"] as? String, mockModels.someType)
    }

    func testUser() {
        let user = mockModels.getUser()

        XCTAssertNotNil(user?.links)
        XCTAssertEqual(user?.id, mockModels.someId)
        XCTAssertEqual(user?.created, mockModels.someDate)
        XCTAssertEqual(user?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.lastModified, mockModels.someDate)
        XCTAssertEqual(user?.lastModifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(user?.encryptedData, "some data")

        let json = user?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["id"] as? String, mockModels.someId)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["lastModifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["lastModifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["encryptedData"] as? String, "some data")
    }

    func testDeviceInfo() {
        let deviceInfo = mockModels.getDeviceInfo()
      
        XCTAssertNotNil(deviceInfo?.links)
        XCTAssertEqual(deviceInfo?.deviceIdentifier, mockModels.someId)
        XCTAssertEqual(deviceInfo?.deviceName, mockModels.someName)
        XCTAssertEqual(deviceInfo?.deviceType, mockModels.someType)
        XCTAssertEqual(deviceInfo?.manufacturerName, mockModels.someName)
        XCTAssertEqual(deviceInfo?.state, "12345fsd")
        XCTAssertEqual(deviceInfo?.serialNumber, "987654321")
        XCTAssertEqual(deviceInfo?.modelNumber, "1258PO")
        XCTAssertEqual(deviceInfo?.hardwareRevision, "12345fsd")
        XCTAssertEqual(deviceInfo?.firmwareRevision, "12345fsd")
        XCTAssertEqual(deviceInfo?.softwareRevision, "12345fsd")
        XCTAssertEqual(deviceInfo?.notificationToken, "12345fsd")
        XCTAssertEqual(deviceInfo?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(deviceInfo?.created, mockModels.someDate)
        XCTAssertEqual(deviceInfo?.osName, mockModels.someName)
        XCTAssertEqual(deviceInfo?.systemId, mockModels.someId)
        XCTAssertNotNil(deviceInfo?.cardRelationships)
        XCTAssertEqual(deviceInfo?.licenseKey, "147PLO")
        XCTAssertEqual(deviceInfo?.bdAddress, "someAddress")
        XCTAssertEqual(deviceInfo?.pairing, "pairing")
        XCTAssertEqual(deviceInfo?.secureElement?.secureElementId, mockModels.someId)
        XCTAssertEqual(deviceInfo?.secureElement?.casd, "casd")
        XCTAssertNotNil(deviceInfo?.shortRTMRepersentation)

        let json = deviceInfo?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["deviceIdentifier"] as? String, mockModels.someId)
        XCTAssertEqual(json?["deviceName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["deviceType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["manufacturerName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["state"] as? String, "12345fsd")
        XCTAssertEqual(json?["serialNumber"] as? String, "987654321")
        XCTAssertEqual(json?["modelNumber"] as? String, "1258PO")
        XCTAssertEqual(json?["hardwareRevision"] as? String, "12345fsd")
        XCTAssertEqual(json?["firmwareRevision"] as? String, "12345fsd")
        XCTAssertEqual(json?["softwareRevision"] as? String, "12345fsd")
        XCTAssertEqual(json?["notificationToken"] as? String, "12345fsd")
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["osName"] as? String, mockModels.someName)
        XCTAssertEqual(json?["systemId"] as? String, mockModels.someId)
        XCTAssertNotNil(json?["cardRelationships"])
        XCTAssertEqual(json?["licenseKey"] as? String, "147PLO")
        XCTAssertEqual(json?["bdAddress"] as? String, "someAddress")
        XCTAssertEqual(json?["pairing"] as? String, "pairing")
        XCTAssertEqual((json?["secureElement"] as? [String: Any])?["secureElementId"] as? String, mockModels.someId)
        XCTAssertEqual((json?["secureElement"] as? [String: Any])?["casd"] as? String, "casd")
    }

    func testCardRelationship() {
        let cardRelationship = mockModels.getCardRelationship()

        XCTAssertNotNil(cardRelationship?.links)
        XCTAssertEqual(cardRelationship?.creditCardId, mockModels.someId)
        XCTAssertEqual(cardRelationship?.pan, "1234")
        XCTAssertEqual(cardRelationship?.expMonth, 2)
        XCTAssertEqual(cardRelationship?.expYear, 2018)

        let cardRelationshipJson = cardRelationship?.toJSON()
        XCTAssertNotNil(cardRelationshipJson?["_links"])
        XCTAssertEqual(cardRelationshipJson?["creditCardId"] as? String, mockModels.someId)
        XCTAssertEqual(cardRelationshipJson?["pan"] as? String, "1234")
        XCTAssertEqual(cardRelationshipJson?["expMonth"] as? Int, 2)
        XCTAssertEqual(cardRelationshipJson?["expYear"] as? Int, 2018)
    }

    func testCommit() {
        let commit = mockModels.getCommit()

        XCTAssertNotNil(commit?.links)
        XCTAssertEqual(commit?.commitTypeString, mockModels.someType)
        XCTAssertEqual(commit?.created, CLong(mockModels.timeEpoch))
        XCTAssertEqual(commit?.previousCommit, "2")
        XCTAssertEqual(commit?.commit, mockModels.someId)
        XCTAssertEqual(commit?.encryptedData, mockModels.someEncryptionData)

        let json = commit?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["commitType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["createdTs"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["previousCommit"] as? String, "2")
        XCTAssertEqual(json?["commitId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["encryptedData"] as? String, mockModels.someEncryptionData)
    }

    func testCommitMetrics() {
        let commitMetrics = mockModels.getCommitMetrics()

        XCTAssertEqual(commitMetrics?.syncId, mockModels.someId)
        XCTAssertEqual(commitMetrics?.deviceId, mockModels.someId)
        XCTAssertEqual(commitMetrics?.userId, mockModels.someId)

        XCTAssertEqual(commitMetrics?.sdkVersion, "1")
        XCTAssertEqual(commitMetrics?.osVersion, "2")
        XCTAssertEqual(commitMetrics?.initiator, SyncInitiator(rawValue: "PLATFORM"))
        XCTAssertEqual(commitMetrics?.totalProcessingTimeMs, Int(mockModels.timeEpoch))
        XCTAssertNotNil(commitMetrics?.commitStatistics)

        let json = commitMetrics?.toJSON()
        XCTAssertEqual(json?["syncId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["deviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["userId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["sdkVersion"] as? String, "1")
        XCTAssertEqual(json?["osVersion"] as? String, "2")
        XCTAssertEqual(json?["initiator"] as? String, "PLATFORM")
        XCTAssertEqual(json?["totalProcessingTimeMs"] as? Int64, mockModels.timeEpoch)
        XCTAssertNotNil(json?["commits"])
    }

    func testApduPackage() {
        let dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"

        let apduPackage = mockModels.getApduPackage()

        XCTAssertNotNil(apduPackage?.links)
        XCTAssertEqual(apduPackage?.seIdType, mockModels.someType)
        XCTAssertEqual(apduPackage?.targetDeviceType, mockModels.someType)
        XCTAssertEqual(apduPackage?.targetDeviceId, mockModels.someId)
        XCTAssertEqual(apduPackage?.packageId, mockModels.someId)
        XCTAssertEqual(apduPackage?.seId, mockModels.someId)
        XCTAssertNotNil(apduPackage?.apduCommands)
        XCTAssertEqual(apduPackage?.validUntil, mockModels.someDate)
        XCTAssertEqual(apduPackage?.validUntilEpoch, CustomDateFormatTransform(formatString: dateFormat).transform(mockModels.someDate))
        XCTAssertEqual(apduPackage?.apduPackageUrl, "www.example.com")
        XCTAssertNotNil(apduPackage?.responseDictionary)
        XCTAssertTrue(apduPackage?.isExpired ?? false)

        let json = apduPackage?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["seIdType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["targetDeviceType"] as? String, mockModels.someType)
        XCTAssertEqual(json?["targetDeviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["packageId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["seId"] as? String, mockModels.someId)
        XCTAssertNotNil(json?["commandApdus"])
        XCTAssertEqual(json?["validUntil"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["apduPackageUrl"] as? String, "www.example.com")
    }

    func testAPDUCommand() {
        let apduCommand = mockModels.getApduCommand()

        XCTAssertNotNil(apduCommand?.links)
        XCTAssertEqual(apduCommand?.commandId, mockModels.someId)
        XCTAssertEqual(apduCommand?.groupId, 1)
        XCTAssertEqual(apduCommand?.sequence, 1)
        XCTAssertEqual(apduCommand?.command, "command")
        XCTAssertEqual(apduCommand?.type, mockModels.someType)
        XCTAssertEqual(apduCommand?.continueOnFailure, true)
        XCTAssertNotNil(apduCommand?.responseDictionary)

        let json = apduCommand?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["commandId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["groupId"] as? Int, 1)
        XCTAssertEqual(json?["sequence"] as? Int, 1)
        XCTAssertEqual(json?["command"] as? String, "command")
        XCTAssertEqual(json?["type"] as? String, mockModels.someType)
        XCTAssertEqual(json?["continueOnFailure"] as? Bool, true)
    }

    func testEncryptionKey() {
        let encryptionKey = mockModels.getEncryptionKey()

        XCTAssertNotNil(encryptionKey?.links)
        XCTAssertEqual(encryptionKey?.keyId, mockModels.someId)
        XCTAssertEqual(encryptionKey?.created, mockModels.someDate)
        XCTAssertEqual(encryptionKey?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(encryptionKey?.expiration, mockModels.someDate)
        XCTAssertEqual(encryptionKey?.expirationEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(encryptionKey?.serverPublicKey, "someKey")
        XCTAssertEqual(encryptionKey?.clientPublicKey, "someKey")
        XCTAssertEqual(encryptionKey?.active, true)

        let json = encryptionKey?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["keyId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["expirationTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["expirationTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["serverPublicKey"] as? String, "someKey")
        XCTAssertEqual(json?["clientPublicKey"] as? String, "someKey")
        XCTAssertEqual(json?["active"] as? Bool, true)
    }

    func testVerificationMethod() {
        let verificationMethod = mockModels.getVerificationMethod()

        XCTAssertNotNil(verificationMethod?.links)
        XCTAssertEqual(verificationMethod?.verificationId, mockModels.someId)
        XCTAssertEqual(verificationMethod?.state, VerificationState(rawValue: "AVAILABLE_FOR_SELECTION"))
        XCTAssertEqual(verificationMethod?.methodType, VerificationMethodType(rawValue: "TEXT_TO_CARDHOLDER_NUMBER"))
        XCTAssertEqual(verificationMethod?.value, "someValue")
        XCTAssertEqual(verificationMethod?.verificationResult, VerificationResult(rawValue: "SUCCESS"))
        XCTAssertEqual(verificationMethod?.created, mockModels.someDate)
        XCTAssertEqual(verificationMethod?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(verificationMethod?.lastModified, mockModels.someDate)
        XCTAssertEqual(verificationMethod?.lastModifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(verificationMethod?.verified, mockModels.someDate)
        XCTAssertEqual(verificationMethod?.verifiedEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertNotNil(verificationMethod?.appToAppContext)

        let json = verificationMethod?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["verificationId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["state"] as? String, "AVAILABLE_FOR_SELECTION")
        XCTAssertEqual(json?["methodType"] as? String, "TEXT_TO_CARDHOLDER_NUMBER")
        XCTAssertEqual(json?["value"] as? String, "someValue")
        XCTAssertEqual(json?["verificationResult"] as? String, "SUCCESS")
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["lastModifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["lastModifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["verifiedTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["verifiedTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertNotNil(json?["appToAppContext"])
    }

    func testCreditCard() {
        let creditCard = mockModels.getCreditCard()

        XCTAssertNotNil(creditCard?.links)
        XCTAssertEqual(creditCard?.creditCardId, mockModels.someId)
        XCTAssertEqual(creditCard?.userId, mockModels.someId)
        XCTAssertEqual(creditCard?.isDefault, true)
        XCTAssertEqual(creditCard?.created, mockModels.someDate)
        XCTAssertEqual(creditCard?.createdEpoch, NSTimeIntervalTypeTransform().transform(mockModels.timeEpoch))
        XCTAssertEqual(creditCard?.state, CreditCard.TokenizationState.notEligible)
        XCTAssertEqual(creditCard?.cardType, mockModels.someType)
        XCTAssertNotNil(creditCard?.cardMetaData)
        XCTAssertEqual(creditCard?.termsAssetId, mockModels.someId)
        XCTAssertNotNil(creditCard?.termsAssetReferences)
        XCTAssertEqual(creditCard?.eligibilityExpiration, mockModels.someDate)
        XCTAssertNotNil(creditCard?.deviceRelationships)
        XCTAssertEqual(creditCard?.encryptedData, mockModels.someEncryptionData)
        XCTAssertEqual(creditCard?.targetDeviceId, mockModels.someId)
        XCTAssertEqual(creditCard?.targetDeviceType, mockModels.someType)
        XCTAssertNotNil(creditCard?.verificationMethods)
        XCTAssertEqual(creditCard?.externalTokenReference, "someToken")
        XCTAssertNotNil(creditCard?.topOfWalletAPDUCommands)
        XCTAssertEqual(creditCard?.tokenLastFour, "4321")
        
        XCTAssertEqual(creditCard?.info?.name, mockModels.someName)
        XCTAssertEqual(creditCard?.info?.pan, "pan")
        XCTAssertEqual(creditCard?.info?.expMonth, 2)
        XCTAssertEqual(creditCard?.info?.expYear, 2018)
        XCTAssertEqual(creditCard?.info?.cvv, "cvv")
        XCTAssertNotNil(creditCard?.info?.address)

        let json = creditCard?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["creditCardId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["default"] as? Bool, true)
        XCTAssertEqual(json?["createdTs"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["createdTsEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertEqual(json?["state"] as? String, "NOT_ELIGIBLE")
        XCTAssertEqual(json?["cardType"] as? String, mockModels.someType)
        XCTAssertNotNil(json?["cardMetaData"])
        XCTAssertEqual(json?["termsAssetId"] as? String, mockModels.someId)
        XCTAssertNotNil(json?["termsAssetReferences"])
        XCTAssertEqual(json?["eligibilityExpiration"] as? String, mockModels.someDate)
        XCTAssertEqual(json?["eligibilityExpirationEpoch"] as? Int64, mockModels.timeEpoch)
        XCTAssertNotNil(json?["deviceRelationships"])
        XCTAssertEqual(json?["encryptedData"] as? String, mockModels.someEncryptionData)
        XCTAssertEqual(json?["targetDeviceId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["targetDeviceType"] as? String, mockModels.someType)
        XCTAssertNotNil(json?["verificationMethods"])
        XCTAssertEqual(json?["externalTokenReference"] as? String, "someToken")
        XCTAssertEqual(json?["tokenLastFour"] as? String, "4321")
        XCTAssertNotNil(json?["offlineSeActions.topOfWallet.apduCommands"])
        
        // TODO: Fix toJSON to return nested objects
        //XCTAssertEqual((json?["info"] as? [String: Any])?["pan"] as? String, "1234")
        //XCTAssertEqual((json?["info"] as? [String: Any])?["expMonth"] as? Int64, 12)
        //XCTAssertEqual((json?["info"] as? [String: Any])?["expYear"] as? Int64, 2018)
        //XCTAssertEqual((json?["info"] as? [String: Any])?["cvv"] as? String, "123")
        //XCTAssertEqual((json?["info"] as? [String: Any])?["name"] as? String, mockModels.someName)
        
    }

    func testAddress() {
        let address = mockModels.getAddress()

        XCTAssertEqual(address?.street1, "1035 Pearl St")
        XCTAssertEqual(address?.street2, "5th Floor")
        XCTAssertEqual(address?.street3, "8th Floor")
        XCTAssertEqual(address?.city, "Boulder")
        XCTAssertEqual(address?.state, "CO")
        XCTAssertEqual(address?.postalCode, "80302")
        XCTAssertEqual(address?.countryCode, "US")

        let json = address?.toJSON()
        XCTAssertEqual(json?["street1"] as? String, "1035 Pearl St")
        XCTAssertEqual(json?["street2"] as? String, "5th Floor")
        XCTAssertEqual(json?["street3"] as? String, "8th Floor")
        XCTAssertEqual(json?["city"] as? String, "Boulder")
        XCTAssertEqual(json?["state"] as? String, "CO")
        XCTAssertEqual(json?["postalCode"] as? String, "80302")
        XCTAssertEqual(json?["countryCode"] as? String, "US")
    }

    func testImage() {
        let image = mockModels.getImage()

        XCTAssertNotNil(image?.links)
        XCTAssertEqual(image?.mimeType, "image/gif")
        XCTAssertEqual(image?.height, 20)
        XCTAssertEqual(image?.width, 60)

        let json = image?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["mimeType"] as? String, "image/gif")
        XCTAssertEqual(json?["height"] as? Int64, 20)
        XCTAssertEqual(json?["width"] as? Int64, 60)
    }

    func testRtmConfig() {
        let rtmConfig = mockModels.getRtmConfig()

        XCTAssertEqual(rtmConfig?.redirectUri, "https://api.fit-pay.com")
        XCTAssertNotNil(rtmConfig?.deviceInfo)
        XCTAssertEqual(rtmConfig?.hasAccount, false)
        XCTAssertEqual(rtmConfig?.accessToken, "someToken")

        let dict = rtmConfig?.jsonDict()
        XCTAssertNotNil(dict)

        let json = rtmConfig?.toJSON()
        XCTAssertEqual(json?["clientId"] as? String, mockModels.someId)
        XCTAssertEqual(json?["redirectUri"] as? String, "https://api.fit-pay.com")
        XCTAssertEqual(json?["userEmail"] as? String, "someEmail")
        XCTAssertNotNil(json?["paymentDevice"])
        XCTAssertEqual(json?["account"] as? Bool, false)
        XCTAssertEqual(json?["version"] as? String, "2")
        XCTAssertEqual(json?["demoMode"] as? Bool, false)
        XCTAssertEqual(json?["themeOverrideCssUrl"] as? String, "https://api.fit-pay.com")
        XCTAssertEqual(json?["demoCardGroup"] as? String, "someGroup")
        XCTAssertEqual(json?["accessToken"] as? String, "someToken")
        XCTAssertEqual(json?["language"] as? String, "en")
        XCTAssertEqual(json?["baseLangUrl"] as? String, "https://api.fit-pay.com")
        XCTAssertEqual(json?["useWebCardScanner"] as? Bool, false)

        rtmConfig?.update(value: "someProperty", forKey: "clientId")
        rtmConfig?.update(value: "someProperty", forKey: "redirectUri")
        XCTAssertEqual(rtmConfig?.redirectUri, "someProperty")
        rtmConfig?.update(value: "someProperty", forKey: "userEmail")
        rtmConfig?.update(value: "DeviceInfo", forKey: "paymentDevice")
        XCTAssertEqual(rtmConfig?.deviceInfo, nil)
        rtmConfig?.update(value: false, forKey: "account")
        XCTAssertEqual(rtmConfig?.hasAccount, false)
        rtmConfig?.update(value: "someProperty", forKey: "version")
        rtmConfig?.update(value: false, forKey: "demoMode")
        rtmConfig?.update(value: "someProperty", forKey: "themeOverrideCssUrl")
        rtmConfig?.update(value: "someProperty", forKey: "demoCardGroup")
        rtmConfig?.update(value: "someProperty", forKey: "accessToken")
        XCTAssertEqual(rtmConfig?.accessToken, "someProperty")
        rtmConfig?.update(value: "someProperty", forKey: "language")
        rtmConfig?.update(value: "someProperty", forKey: "baseLangUrl")
        rtmConfig?.update(value: false, forKey: "useWebCardScanner")
    }

    func testRtmMessage() {
        let rtmMessage = mockModels.getRtmMessageResponse()

        XCTAssertEqual(rtmMessage?.callBackId, 1)
        XCTAssertNotNil(rtmMessage?.data)
        XCTAssertEqual(rtmMessage?.type, mockModels.someType)
        XCTAssertEqual(rtmMessage?.success, true)

        let json = rtmMessage?.toJSON()
        XCTAssertEqual(json?["callBackId"] as? Int, 1)
        XCTAssertEqual(json?["type"] as? String, mockModels.someType)
        XCTAssertEqual(json?["isSuccess"] as? Bool, true)
    }

    func testRelationship() {
        let relationship = mockModels.getRelationship()

        XCTAssertNotNil(relationship?.links)
        XCTAssertNotNil(relationship?.card)
        XCTAssertNotNil(relationship?.device)

        let json = relationship?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertNotNil(json?["card"])
        XCTAssertNotNil(json?["device"])
    }

    func testIssuers() {
        let issuers = mockModels.getIssuers()

        XCTAssertNotNil(issuers?.links)
        XCTAssertNotNil(issuers?.countries)

        let json = issuers?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertNotNil(json?["countries"])
    }

    func testA2AIssuerRequestEncodingString() {
        let a2AIssuerRequest = A2AIssuerRequest(response: A2AIssuerRequest.A2AStepupResult.approved, authCode: "someCode")
        XCTAssertNotNil(a2AIssuerRequest.getEncodedString())
    }

    func testResultCollection() {
        let resultCollection = mockModels.getResultCollection()
        
        XCTAssertNotNil(resultCollection?.links)
        XCTAssertEqual(resultCollection?.limit, 1)
        XCTAssertEqual(resultCollection?.offset, 1)
        XCTAssertEqual(resultCollection?.totalResults, 1)
        XCTAssertNotNil(resultCollection?.results)

        let json = resultCollection?.toJSON()
        XCTAssertNotNil(json?["_links"])
        XCTAssertEqual(json?["limit"] as? Int, 1)
        XCTAssertEqual(json?["offset"] as? Int, 1)
        XCTAssertEqual(json?["totalResults"] as? Int, 1)
    }
}
