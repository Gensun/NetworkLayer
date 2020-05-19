//
//  URLParameterEncoder.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation

public struct URLParameterEncoder: ParameterEncoder {
    static func encode(urlRequest: inout URLRequest, headers: HttpHeaders) throws {
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
    }

    static func encode(urlRequest: inout URLRequest, with urlParameters: Parameters) throws {
        guard let url = urlRequest.url else { throw NetworkError.invalidUrl }
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !urlParameters.isEmpty {
            urlComponents.queryItems = [URLQueryItem]()
            for (key, value) in urlParameters {
                guard !key.isEmpty else {
                    var requestUrl = urlRequest.url
                    let pathComponent = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
                    requestUrl?.appendPathComponent(pathComponent)
                    return
                }
                let queryItem = URLQueryItem(name: key,
                                             value:
                                             "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
                urlComponents.queryItems?.append(queryItem)
            }
            urlRequest.url = urlComponents.url
        }
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
    }
}
