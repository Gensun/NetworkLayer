//
//  Endpoint.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation
import UIKit

public typealias HttpHeaders = [String: String]
public typealias Parameters = [String: Any]
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

public enum HttpTask<T: Encodable> {
    case request
    // post or get
    case requestWithParameters(bodyParameters: T?, queryParameters: Parameters?, pathParameters: [String]?)
    // get
    case GET(queryParameters: Parameters?)
    // post
    case POST(bodyParameters: T?)
    // get and can set header
    case requestWithHeaders(headers: HttpHeaders?, queryParameters: Parameters?)
}

public protocol EndpointType {
    associatedtype ParameterType: Encodable
    var baseUrl: URL { get }
    var path: String { get }
    var httpMethod: HttpMethod { get }
    var task: HttpTask<ParameterType> { get }
    var headers: HttpHeaders? { get }
    func loadCookies()
}

public extension EndpointType {
    var httpMethod: HttpMethod {
        return .post
    }

    var headers: HttpHeaders? {
        return nil
    }

    func loadCookies(){
        
    }
}
