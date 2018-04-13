//
//  FitpaySDKConfiguration.swift
//  FitpaySDK
//
//  Created by Anton on 29.07.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

import Foundation

public let FitpaySDKVersion = "0.5.0"
internal let log = FitpaySDKLogger.sharedInstance

open class FitpaySDKConfiguration : NSObject{
    open static let defaultConfiguration = FitpaySDKConfiguration()
    
    open var clientId: String
    open var redirectUri: String
    open var baseAuthURL: String
    open var baseAPIURL: String
    open var webViewURL: String
    
    @available(*, deprecated, message: "Use commitProcessingTimeoutSecs")
    open var commitErrorTimeout: Int {
        set {
            commitProcessingTimeoutSecs = Double(newValue)
        }
        get {
            return Int(commitProcessingTimeoutSecs)
        }
    }
    
    open var commitProcessingTimeoutSecs: Double = 30.0
    
    override public init() {
        self.clientId = ""
        self.redirectUri = BASE_URL
        self.baseAuthURL = AUTHORIZE_BASE_URL
        self.baseAPIURL = API_BASE_URL
        self.webViewURL = BASE_URL
        
        super.init()
        
        self.setupLogs()
    }
    
    public init(clientId: String, redirectUri: String, baseAuthURL: String, baseAPIURL: String, webViewURL: String = BASE_URL) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.baseAuthURL = baseAuthURL
        self.baseAPIURL = baseAPIURL
        self.webViewURL = webViewURL
        
        super.init()
        
        self.setupLogs()
    }
    
    open static let sdkVersion: String = Bundle(for: FitpaySDKConfiguration.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "unk"
    
    enum EnvironmentLoadingErrors : Error {
        case clientIdIsEmpty
        case clientSecretIsEmpty
        case baseApiUrlIsEmpty
        case authorizeURLIsEmpty
    }
    
    open func loadEnvironmentVariables() -> Error? {
        let envDict = ProcessInfo.processInfo.environment

        //cleintId checks
        guard let clientId = envDict["SDK_CLIENT_ID"] else {
            return EnvironmentLoadingErrors.clientIdIsEmpty
        }
        
        guard clientId.isEmpty == false else {
            return EnvironmentLoadingErrors.clientIdIsEmpty
        }
        
        //baseAPIUrl checks
        guard let baseAPIUrl = envDict["SDK_API_BASE_URL"] else {
            return EnvironmentLoadingErrors.baseApiUrlIsEmpty
        }
        
        guard baseAPIUrl.isEmpty == false else {
            return EnvironmentLoadingErrors.baseApiUrlIsEmpty
        }
        
        //baseAuthBaseUrl checks
        guard let baseAuthBaseUrl = envDict["SDK_AUTHORIZE_BASE_URL"] else {
            return EnvironmentLoadingErrors.authorizeURLIsEmpty
        }
        
        guard baseAuthBaseUrl.isEmpty == false else {
            return EnvironmentLoadingErrors.authorizeURLIsEmpty
        }
        
        self.clientId = clientId
        self.baseAuthURL = baseAuthBaseUrl
        self.baseAPIURL = baseAPIUrl
        
        return nil
    }
    
    fileprivate func setupLogs() {
        log.addOutput(output: ConsoleOutput())
    }
}
