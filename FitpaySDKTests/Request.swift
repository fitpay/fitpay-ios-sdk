//
//  Request.swift
//  FitpaySDK
//
//  Created by Illya Kyznetsov on 5/30/18.
//  Copyright © 2018 Fitpay. All rights reserved.
//
import UIKit
@testable import FitpaySDK

public class Request {

    var request:String?
    var response: Response!

    init (request:String){
        self.request = request
    }

    public func responseJSON(options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: (Request) -> Void) {

        completionHandler(self)
    }
}

public struct Response {
    var data: HTTPURLResponse?
    var json: String?
    var error: Error?
}

