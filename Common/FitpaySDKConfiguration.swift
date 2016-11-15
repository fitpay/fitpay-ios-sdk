//
//  FitpaySDKConfiguration.swift
//  FitpaySDK
//
//  Created by Anton on 29.07.16.
//  Copyright © 2016 Fitpay. All rights reserved.
//

import Foundation

internal let log = FitpaySDKLogger.sharedInstance

open class FitpaySDKConfiguration {
    open static let defaultConfiguration = FitpaySDKConfiguration()
    
    open var clientId : String
    open var redirectUri : String
    open var baseAuthURL : String
    open var baseAPIURL : String
    open var webViewURL : String
    
    public init() {
        self.clientId = ""
        self.redirectUri = BASE_URL
        self.baseAuthURL = AUTHORIZE_BASE_URL
        self.baseAPIURL = API_BASE_URL
        self.webViewURL = BASE_URL
        
        self.setupLogs()
    }
    
    public init(clientId: String, redirectUri: String, baseAuthURL: String, baseAPIURL: String, webViewURL: String = BASE_URL) {
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.baseAuthURL = baseAuthURL
        self.baseAPIURL = baseAPIURL
        self.webViewURL = webViewURL
        
        self.setupLogs()
    }
    
    fileprivate func setupLogs() {
		log.addOutput(output: ConsoleOutput())
    }
    
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
        
        guard clientId.characters.count > 0 else {
            return EnvironmentLoadingErrors.clientIdIsEmpty
        }
        
        //baseAPIUrl checks
        guard let baseAPIUrl = envDict["SDK_API_BASE_URL"] else {
            return EnvironmentLoadingErrors.baseApiUrlIsEmpty
        }
        
        guard baseAPIUrl.characters.count > 0 else {
            return EnvironmentLoadingErrors.baseApiUrlIsEmpty
        }
        
        //baseAuthBaseUrl checks
        guard let baseAuthBaseUrl = envDict["SDK_AUTHORIZE_BASE_URL"] else {
            return EnvironmentLoadingErrors.authorizeURLIsEmpty
        }
        
        guard baseAuthBaseUrl.characters.count > 0 else {
            return EnvironmentLoadingErrors.authorizeURLIsEmpty
        }
        
        self.clientId = clientId
        self.baseAuthURL = baseAuthBaseUrl
        self.baseAPIURL = baseAPIUrl
        
        return nil
    }
}
