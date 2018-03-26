//
//  A2AVerificationError.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 3/5/18.
//

/**
 Errors for A2AVerificationRequest
 */
enum A2AVerificationError: String {
    case CantProcess  = "cantProcessVerification"
    case NotSupported = "appToAppNotSupported"
    case Unknown      = "unknown"
}
