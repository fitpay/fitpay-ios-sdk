import XCTest
import Nimble

@testable import FitpaySDK

class SwCryptTests: XCTestCase {
    let privateKeyBytes: [UInt8] = [0x30 ,0x61, 0x02, 0x80, 0x80, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x04, 0x80, 0x30]
    let publicKeyBytes: [UInt8] = [0x30 ,0x61, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x03, 0x00, 0x00]
}

// MARK: - SwKeyStore tests

extension SwCryptTests {
    
    func testSecError() {
        var storeKey = SwKeyStore.SecError(SwKeyStore.SecError.unimplemented.rawValue)
        expect(storeKey).to(equal(SwKeyStore.SecError.unimplemented))
        
        storeKey = SwKeyStore.SecError(storeKey)
        expect(storeKey).to(equal(SwKeyStore.SecError.unimplemented))
    }
    
}

// MARK: - SwKeyConvert tests

extension SwCryptTests {
    
    // MARK: - PrivateKey tests
    
    func testPemToPKCS1DERЗPrivateKey() {
        let base64String = Data(bytes: privateKeyBytes).base64EncodedString()
        let key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        let pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).toNot(beNil())
    }
    
    func testPemToPKCS1DERBadHeaderPrivateKey() {
        let base64String = Data(bytes: privateKeyBytes).base64EncodedString()
        let key = base64String
        do {
            let _ = try SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
            fail("PrivateKey conversion should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(SwKeyConvert.SwError.invalidKey.localizedDescription))
        }
    }
    
    func testPemToPKCS1DERBadEncodingPrivateKey() {
        let utf8String = String("some string".utf8)
        let key = "-----BEGIN PRIVATE KEY-----\n"+utf8String+"\n-----END PRIVATE KEY-----"
        do {
            let _ = try SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
            fail("PrivateKey conversion should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(SwKeyConvert.SwError.invalidKey.localizedDescription))
        }
    }
    
    func testPemToPKCS1DERWrongKeyPrivateKey() {
        var wrongBytes = privateKeyBytes
        wrongBytes[0] = 0x40
        var base64String = Data(bytes: wrongBytes).base64EncodedString()
        var key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        var pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
        
        wrongBytes = privateKeyBytes
        wrongBytes[2] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
        
        wrongBytes = privateKeyBytes
        wrongBytes[20] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
        
        wrongBytes = privateKeyBytes
        wrongBytes[22] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PrivateKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
    }
    
    func testDerToPKCS1PEMPrivateKey() {
        let data = Data(bytes: privateKeyBytes)
        let derToPKCS1PEM = SwKeyConvert.PrivateKey.derToPKCS1PEM(data)
        let base64String = Data(bytes:  privateKeyBytes).base64EncodedString()
        let key = "-----BEGIN RSA PRIVATE KEY-----\n"+base64String+"\n-----END RSA PRIVATE KEY-----"
        expect(derToPKCS1PEM).to(equal(key))
    }
    
    func testDecryptPEM() {
        let base64String = Data(bytes: privateKeyBytes).base64EncodedString()
        let key = "-----BEGIN RSA PRIVATE KEY-----\n"+base64String+"\n-----END RSA PRIVATE KEY-----"
        let keyAes128CBC = try? SwKeyConvert.PrivateKey.encryptPEM(key, passphrase: "", mode: SwKeyConvert.PrivateKey.EncMode.aes128CBC)
        expect(keyAes128CBC).toNot(beNil())
        
        let decryptedAes128CBC  = try? SwKeyConvert.PrivateKey.decryptPEM(keyAes128CBC ?? "", passphrase: "")
        expect(decryptedAes128CBC).to(equal(key))
        
        let keyAes256CBC = try? SwKeyConvert.PrivateKey.encryptPEM(key, passphrase: "", mode: SwKeyConvert.PrivateKey.EncMode.aes256CBC)
        expect(keyAes256CBC).toNot(beNil())
        
        let decryptedAes256CBC = try? SwKeyConvert.PrivateKey.decryptPEM(keyAes256CBC ?? "", passphrase: "")
        expect(decryptedAes256CBC).to(equal(key))
    }
    
    func testDecryptPEMBadPassphrase() {
        let base64String = Data(bytes: publicKeyBytes).base64EncodedString()
        let key = "-----BEGIN PRIVATE KEY-----\n"+base64String+"\n-----END PRIVATE KEY-----"
        let encryptedPem = try? SwKeyConvert.PrivateKey.encryptPEM(key, passphrase: "some", mode: SwKeyConvert.PrivateKey.EncMode.aes128CBC)
        expect(encryptedPem).toNot(beNil())
        
        do {
            let _ = try SwKeyConvert.PrivateKey.decryptPEM(encryptedPem ?? "", passphrase: "none")
            fail("PrivateKey conversion should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(SwKeyConvert.SwError.badPassphrase.localizedDescription))
        }
    }
    
    func testDecryptPEMKeyNotEncrypted() {
        do {
            let _ = try SwKeyConvert.PrivateKey.decryptPEM("-----BEGIN RSA PRIVATE KEY-----\nProc-Type: 4,ENCRYPTED,8316430F0483BD0187DAAEB83D0A84B8\n\nM5ehyBKpeqAUXa9KU2ZVIVVzFvAe2ymh8WSjBNtCxo4=\n-----END RSA PRIVATE KEY-----", passphrase: "some")
            fail("PrivateKey conversion should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(SwKeyConvert.SwError.keyNotEncrypted.localizedDescription))
        }
    }
    
    // MARK: - PublicKey tests
    
    func testPemToPKCS1DERЗPublicKey() {
        let bytes: [UInt8] = publicKeyBytes
        let base64String = Data(bytes: bytes).base64EncodedString()
        let key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        let pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).toNot(beNil())
    }
    
    func testPemToPKCS1DERBadHeaderPublicKey() {
        let base64String = Data(bytes: publicKeyBytes).base64EncodedString()
        let key = base64String
        do {
            let _ = try SwKeyConvert.PublicKey.pemToPKCS1DER(key)
            fail("PublicKey conversion should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(SwKeyConvert.SwError.invalidKey.localizedDescription))
        }
    }
    
    func testPemToPKCS1DERBadEncodingPublicKey() {
        let utf8String = String("some string".utf8)
        let key = "-----BEGIN KEY-----\n"+utf8String+"\n-----END KEY-----"
        do {
            let _ = try SwKeyConvert.PublicKey.pemToPKCS1DER(key)
            fail("PublicKey conversion should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(SwKeyConvert.SwError.invalidKey.localizedDescription))
        }
    }
    
    func testPemToPKCS1DERWrongKeyPublicKey() {
        var wrongBytes = publicKeyBytes
        wrongBytes[0] = 0x40
        var base64String = Data(bytes: wrongBytes).base64EncodedString()
        var key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        var pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
        
        wrongBytes = publicKeyBytes
        wrongBytes[2] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
        
        wrongBytes = publicKeyBytes
        wrongBytes[17] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
        
        wrongBytes = publicKeyBytes
        wrongBytes[19] = 0x40
        base64String = Data(bytes: wrongBytes).base64EncodedString()
        key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        pkcs1DERKey = try? SwKeyConvert.PublicKey.pemToPKCS1DER(key)
        expect(pkcs1DERKey).to(beNil())
    }
    
    func testDerToPKCS1PEMPublicKey() {
        let data = Data(bytes: publicKeyBytes)
        let derToPKCS1PEM = SwKeyConvert.PublicKey.derToPKCS1PEM(data)
        
        let base64String = Data(bytes: publicKeyBytes).base64EncodedString()
        let key = "-----BEGIN KEY-----\n"+base64String+"\n-----END KEY-----"
        
        expect(derToPKCS1PEM).to(equal(key))
    }
    
    func testDerToPKCS8PEM() {
        let data = Data(bytes: publicKeyBytes)
        let pem = SwKeyConvert.PublicKey.derToPKCS8PEM(data)
        expect(pem).toNot(beNil())
    }
    
}

// MARK: - RSA tests

extension SwCryptTests {
    
    func testССCryptorAvailable() {
        let cryptorAvailable = CC.cryptorAvailable()
        expect(cryptorAvailable).to(beTrue())
    }
    
    func testССAvailable() {
        let available = CC.available()
        expect(available).to(beTrue())
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
        
        expect(decryptedData).toNot(beNil())
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
        
        expect(encryptedData).toNot(beNil())
    }
    
    func testGenerateKeyPairFail() {
        do {
            let _ = try CC.RSA.generateKeyPair(0)
            fail("generateKeyPair should fail")
        } catch let error {
            expect(error.localizedDescription).to(equal(CC.CCError.decodeError.localizedDescription))
        }
    }
    
    func testRSAEncrypt() {
        let testString = "some string"
        let data = testString.data(using: .utf8)!
        let keys = try? CC.RSA.generateKeyPair()
        let tag = Data(bytes: [120, 75, 51, 169, 90, 167, 154, 124, 19])
        expect(keys).toNot(beNil())
        
        let encryptedData = try? CC.RSA.encrypt(data, derKey: keys?.0 ?? Data(), tag: tag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.rmd128)
        expect(encryptedData).toNot(beNil())

        let decryptedData = try? CC.RSA.decrypt(encryptedData ?? Data(), derKey: keys?.0 ?? Data(), tag: tag, padding: CC.RSA.AsymmetricPadding.oaep, digest: CC.DigestAlgorithm.rmd128)
        expect(testString).to(equal(String(data: decryptedData?.0 ?? Data(), encoding: .utf8)))
    }
    
    func testVerify() {
        let testString = "some string"
        let data = testString.data(using: .utf8)!
        let keys = try? CC.RSA.generateKeyPair()
        
        let signedData = try? CC.RSA.sign(data, derKey: keys?.0 ?? Data(), padding: CC.RSA.AsymmetricSAPadding.pss, digest: CC.DigestAlgorithm.rmd160, saltLen: 15)
        expect(signedData).toNot(beNil())
        
        let verifyData = (try? CC.RSA.verify(data, derKey:  keys?.1 ?? Data(), padding: CC.RSA.AsymmetricSAPadding.pss, digest: CC.DigestAlgorithm.rmd160, saltLen: 15, signedData: signedData ?? Data())) ?? false
        expect(verifyData).to(beTrue())
    }
}

// MARK: - DH tests

extension SwCryptTests {
    
    func testDHComputeKey() {
        guard let dh = try? CC.DH.DH(dhParam: CC.DH.DHParam.rfc3526Group5) else {
            fail("Bad init")
            return
        }
        
        guard let key = try? dh.generateKey() else {
            fail("can not generate key")
            return
        }
        
        let computeKey = try? dh.computeKey(key)
        expect(computeKey).toNot(beNil())
    }
    
}

// MARK: - EC tests

extension SwCryptTests {
    
    func testVerifyHash() {
        guard let key = try? CC.EC.generateKeyPair(256) else {
            fail("can not generate key")
            return
        }
        
        let testString = "some string"
        let data = testString.data(using: .utf8)!
        
        let signHash = try? CC.EC.signHash(key.0, hash: data)
        expect(signHash).toNot(beNil())
        
        let verifyHash = try? CC.EC.verifyHash(key.1, hash: data, signedData: signHash ?? Data())
        expect(verifyHash).toNot(beNil())
    }
    
}

// MARK: - CCM tests

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
        expect(encryptedData).toNot(beNil())
    }

}

