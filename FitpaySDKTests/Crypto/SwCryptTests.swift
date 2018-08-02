import XCTest
@testable import FitpaySDK

class SwCryptTests: XCTestCase {
    let privateKeyBytes: [UInt8] = [0x30 ,0x61, 0x02, 0x80, 0x80, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x04, 0x80, 0x30]
    let publicKeyBytes: [UInt8] = [0x30 ,0x61, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x03, 0x00, 0x00]
}

//#MARK: - SwKeyStore tests
extension SwCryptTests {
    func testSecError() {
        var storeKey = SwKeyStore.SecError(SwKeyStore.SecError.unimplemented.rawValue)
        XCTAssertEqual(storeKey, SwKeyStore.SecError.unimplemented)

        storeKey = SwKeyStore.SecError(storeKey)
        XCTAssertEqual(storeKey, SwKeyStore.SecError.unimplemented)
    }
}

//#MARK: - SwKeyConvert tests
extension SwCryptTests {
    //#MARK: - PrivateKey tests
    func testPemToPKCS1DERЗPrivateKey() {
        let base64String = Data(bytes: privateKeyBytes).base64EncodedString()
        let key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        let pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        XCTAssertNotNil(pkcs1DERKey)
    }

    func testPemToPKCS1DERBadHeaderPrivateKey() {
        let base64String = Data(bytes: privateKeyBytes).base64EncodedString()
        let key = base64String
        do {
            let _ = try SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, SwKeyConvert.SwError.invalidKey.localizedDescription)
        }
    }

    func testPemToPKCS1DERBadEncodingPrivateKey() {
        let utf8String = String("some string".utf8)
        let key = "-----BEGIN PRIVATE KEY-----\n"+utf8String+"\n-----END PRIVATE KEY-----"
        do {
            let _ = try SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, SwKeyConvert.SwError.invalidKey.localizedDescription)
        }
    }

    func testPemToPKCS1DERWrongKeyPrivateKey() {
        var wrongBytes = privateKeyBytes
        wrongBytes[0] = 0x40
        var base64String = Data(bytes: wrongBytes).base64EncodedString()
        var key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        var pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)

        wrongBytes = privateKeyBytes
        wrongBytes[2] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)

        wrongBytes = privateKeyBytes
        wrongBytes[20] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)

        wrongBytes = privateKeyBytes
        wrongBytes[22] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)
    }

    func testDerToPKCS1PEMPrivateKey() {
        let data = Data(bytes: privateKeyBytes)
        let derToPKCS1PEM = SwKeyConvert.PrivateKey.derToPKCS1PEM(data)
        let base64String = Data(bytes:  privateKeyBytes).base64EncodedString()
        let key = "-----BEGIN RSA PRIVATE KEY-----\n"+base64String+"\n-----END RSA PRIVATE KEY-----"
        XCTAssertEqual(derToPKCS1PEM, key)
    }

    func testDecryptPEM() {
        let base64String = Data(bytes: privateKeyBytes).base64EncodedString()
        let key = "-----BEGIN RSA PRIVATE KEY-----\n"+base64String+"\n-----END RSA PRIVATE KEY-----"
        let keyAes128CBC = try? SwKeyConvert.PrivateKey.encryptPEM(key, passphrase: "", mode: SwKeyConvert.PrivateKey.EncMode.aes128CBC)
        XCTAssertNotNil(keyAes128CBC)
        let decryptedAes128CBC  = try? SwKeyConvert.PrivateKey.decryptPEM(keyAes128CBC ?? "", passphrase: "")
        XCTAssertEqual(decryptedAes128CBC, key)

        let keyAes256CBC = try? SwKeyConvert.PrivateKey.encryptPEM(key, passphrase: "", mode: SwKeyConvert.PrivateKey.EncMode.aes256CBC)
        XCTAssertNotNil(keyAes256CBC)
        let decryptedAes256CBC = try? SwKeyConvert.PrivateKey.decryptPEM(keyAes256CBC ?? "", passphrase: "")
        XCTAssertEqual(decryptedAes256CBC, key)
    }

    func testDecryptPEMBadPassphrase() {
        let base64String = Data(bytes: publicKeyBytes).base64EncodedString()
        let key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        let encrptedPem = try? SwKeyConvert.PrivateKey.encryptPEM(key, passphrase: "some", mode: SwKeyConvert.PrivateKey.EncMode.aes128CBC)
        XCTAssertNotNil(encrptedPem)

        do {
            let decryptedPem = try SwKeyConvert.PrivateKey.decryptPEM(encrptedPem ?? "", passphrase: "none")
            XCTAssertNil(decryptedPem)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, SwKeyConvert.SwError.badPassphrase.localizedDescription)
        }
    }

    func testDecryptPEMKeyNotEncrypted() {
        do {
            let decryptedPem = try SwKeyConvert.PrivateKey.decryptPEM("-----BEGIN RSA PRIVATE KEY-----\nProc-Type: 4,ENCRYPTED,8316430F0483BD0187DAAEB83D0A84B8\n\nM5ehyBKpeqAUXa9KU2ZVIVVzFvAe2ymh8WSjBNtCxo4=\n-----END RSA PRIVATE KEY-----", passphrase: "some")
            XCTAssertNil(decryptedPem)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, SwKeyConvert.SwError.keyNotEncrypted.localizedDescription)
        }
    }

    //#MARK: - PublicKey tests
    func testPemToPKCS1DERЗPublicKey() {
        let bytes: [UInt8] = publicKeyBytes
        let base64String = Data(bytes: bytes).base64EncodedString()
        let key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        let pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        XCTAssertNotNil(pkcs1DERKey)
    }

    func testPemToPKCS1DERBadHeaderPublicKey() {
        let base64String = Data(bytes: publicKeyBytes).base64EncodedString()
        let key = base64String
        do {
            let _ = try SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, SwKeyConvert.SwError.invalidKey.localizedDescription)
        }
    }

    func testPemToPKCS1DERBadEncodingPublicKey() {
        let utf8String = String("some string".utf8)
        let key = "-----BEGIN KEY-----\n"+utf8String+"\n-----END KEY-----"
        do {
            let _ = try SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, SwKeyConvert.SwError.invalidKey.localizedDescription)
        }
    }

    func testPemToPKCS1DERWrongKeyPublicKey() {
        var wrongBytes = publicKeyBytes
        wrongBytes[0] = 0x40
        var base64String = Data(bytes: wrongBytes).base64EncodedString()
        var key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        var pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)

        wrongBytes = publicKeyBytes
        wrongBytes[2] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)

        wrongBytes = publicKeyBytes
        wrongBytes[17] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)

        wrongBytes = publicKeyBytes
        wrongBytes[19] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        XCTAssertNil(pkcs1DERKey)
    }

    func testDerToPKCS1PEMPublicKey() {
        let data = Data(bytes: publicKeyBytes)
        let derToPKCS1PEM = SwKeyConvert.PublicKey.derToPKCS1PEM(data)
        let base64String = Data(bytes: publicKeyBytes).base64EncodedString()
        let key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        XCTAssertEqual(derToPKCS1PEM, key)
    }

    func testDerToPKCS8PEM() {
        let data = Data(bytes: publicKeyBytes)
        let pem = SwKeyConvert.PublicKey.derToPKCS8PEM(data)
        XCTAssertNotNil(pem)
    }

    func testGetPKCS1DEROffset() {
        let data = Data(bytes: publicKeyBytes)
        let pem = SwKeyConvert.PublicKey.derToPKCS8PEM(data)
        XCTAssertNotNil(pem)
    }

}

//#MARK: - RSA tests
extension SwCryptTests {
    func testССCryptorAvailable() {
        let cryptorAvailable = CC.cryptorAvailable()
        XCTAssertTrue(cryptorAvailable)
    }

    func testССAvailable() {
        let available = CC.available()
        XCTAssertTrue(available)
    }

    func testССDecrypt() {
        let data = Data(bytes: [120, 75, 51, 169, 90, 167, 154, 124, 19, 204, 76, 180, 117, 214, 237, 91, 48, 12, 98, 164, 106, 29, 112, 115, 74, 13, 160, 155, 65, 48, 181, 197, 93, 51, 253, 200, 238, 127, 228, 197, 85, 121, 180, 97, 7, 234, 76, 63])
        let cipherKey = Data(bytes: [5, 111, 183, 109, 227, 161, 109, 212, 43, 185, 158, 143, 117, 91, 16, 214, 244, 205, 8, 106, 246, 134, 247, 92, 123, 14, 203, 53, 146, 88, 79, 149])
        let iv = Data(bytes: [94, 210, 246, 96, 253, 214, 202, 143, 236, 147, 96, 82])

        let decryptedData = try? CC.cryptAuth(.decrypt,
                                         blockMode: .gcm,
                                         algorithm: .aes,
                                         data: data,
                                         aData: Data(),
                                         key: cipherKey,
                                         iv: iv,
                                         tagLength: JWEObject.AuthenticationTagSize)

        XCTAssertNotNil(decryptedData)
    }

    func testССEncryp() {
        let data = Data(bytes: [120, 75, 51, 169, 90, 167, 154, 124, 19, 204, 76, 180, 117, 214, 237, 91, 48, 12, 98, 164, 106, 29, 112, 115, 74, 13, 160, 155, 65, 48, 181, 197, 93, 51, 253, 200, 238, 127, 228, 197, 85, 121, 180, 97, 7, 234, 76, 63])
        let cipherKey = Data(bytes: [5, 111, 183, 109, 227, 161, 109, 212, 43, 185, 158, 143, 117, 91, 16, 214, 244, 205, 8, 106, 246, 134, 247, 92, 123, 14, 203, 53, 146, 88, 79, 149])
        let iv = Data(bytes: [94, 210, 246, 96, 253, 214, 202, 143, 236, 147, 96, 82])

        let encryptedData = try? CC.cryptAuth(.encrypt,
                                              blockMode: .gcm,
                                              algorithm: .aes,
                                              data: data,
                                              aData: Data(),
                                              key: cipherKey,
                                              iv: iv,
                                              tagLength: JWEObject.AuthenticationTagSize)

        XCTAssertNotNil(encryptedData)
    }

    func testGenerateKeyPairFail() {
        do {
        let keys = try CC.RSA.generateKeyPair(0)
        XCTAssertNil(keys)
        } catch let error {
             XCTAssertEqual(error.localizedDescription, CC.CCError.decodeError.localizedDescription)
        }
    }

    func testRSAEncrypt() {
        let testString = "some string"
        let data = testString.data(using: .utf8)!
        let keys = try? CC.RSA.generateKeyPair()
        let tag = Data(bytes: [120, 75, 51, 169, 90, 167, 154, 124, 19])
        XCTAssertNotNil(keys)

        let encryptedData = try? CC.RSA.encrypt(data, derKey: keys?.0 ?? Data(), tag: tag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.rmd128)
        XCTAssertNotNil(encryptedData)

        let decryptedData = try? CC.RSA.decrypt(encryptedData ?? Data(), derKey: keys?.0 ?? Data(), tag: tag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.rmd128)
        XCTAssertEqual(testString, String(data: decryptedData?.0 ?? Data(), encoding: .utf8))
    }

    func testVerify() {
        let testString = "some string"
        let data = testString.data(using: .utf8)!
        let keys = try? CC.RSA.generateKeyPair()

        let signedData = try? CC.RSA.sign(data, derKey: keys?.0 ?? Data(), padding: CC.RSA.AsymmetricSAPadding.pss, digest: CC.DigestAlgorithm.rmd160, saltLen: 15)
        XCTAssertNotNil(signedData)

        let verifyData = (try? CC.RSA.verify(data, derKey:  keys?.1 ?? Data(), padding: CC.RSA.AsymmetricSAPadding.pss, digest: CC.DigestAlgorithm.rmd160, saltLen: 15, signedData: signedData ?? Data())) ?? false
        XCTAssertTrue(verifyData)
    }
}

//#MARK: - DH tests
extension SwCryptTests {
    func testDHComputeKey() {
        guard let dh = try? CC.DH.DH(dhParam: CC.DH.DHParam.rfc3526Group5) else {
            XCTAssert(false, "Bad init")
            return()
        }

        guard let key = try? dh.generateKey() else {
            XCTAssert(false, "can not generate key")
            return()
        }

        let computeKey = try? dh.computeKey(key)
        XCTAssertNotNil(computeKey)
    }
}

//#MARK: - EC tests
extension SwCryptTests {
    func testVerifyHash() {
        guard let key = try? CC.EC.generateKeyPair(256) else {
            XCTAssert(false, "can not generate key")
            return()
        }

        let testString = "some string"
        let data = testString.data(using: .utf8)!

        let signHash = try? CC.EC.signHash(key.0, hash: data)
        XCTAssertNotNil(signHash)

        let verifyHash = try? CC.EC.verifyHash(key.1, hash: data, signedData: signHash ?? Data())
        XCTAssertNotNil(verifyHash)
    }
}

//#MARK: - CCM tests
extension SwCryptTests {
    func testCrypt() {
        let data = Data(bytes: [120, 75, 51, 169, 90, 167, 154, 124, 19, 204, 76, 180, 117, 214, 237, 91, 48, 12, 98, 164, 106, 29, 112, 115, 74, 13, 160, 155, 65, 48, 181, 197, 93, 51, 253, 200, 238, 127, 228, 197, 85, 121, 180, 97, 7, 234, 76, 63])
        let cipherKey = Data(bytes: [5, 111, 183, 109, 227, 161, 109, 212, 43, 185, 158, 143, 117, 91, 16, 214, 244, 205, 8, 106, 246, 134, 247, 92, 123, 14, 203, 53, 146, 88, 79, 149])
        let iv = Data(bytes: [94, 210, 246, 96, 253, 214, 202, 143, 236, 147, 96, 82])

        let encryptedData = try? CC.CCM.crypt(.encrypt,
                                              algorithm: .aes,
                                              data: data,
                                              key: cipherKey,
                                              iv: iv,
                                              aData: Data(),
                                              tagLength: JWEObject.AuthenticationTagSize)
        XCTAssertNotNil(encryptedData)
    }
}

