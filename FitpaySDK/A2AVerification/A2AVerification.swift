//
//  A2AVerification.swift
//  ActionSheetPicker-3.0
//
//  Created by Illya Kyznetsov on 3/6/18.
//

import Foundation

/**  Get app-to-app verification response
      On completion of the issuer intent the OEM app must then open the web-view using the returnLocation.
      <baseUrl>/<returnLocation>?config=<base64 encoded config with a2a>
    */
@objc public protocol FitpayA2AVerificationDelegate: NSObjectProtocol {
    func verificationFinished(verificationInfo: A2AVerificationRequest?)
}
