//
//  RtmConfigTests.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/29/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import XCTest
@testable import FitpaySDK

class RtmConfigTests: BaseTestProvider {
        
    func testRtmConfigParsing() {
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
}
