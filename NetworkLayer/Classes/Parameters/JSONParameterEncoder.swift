//
//  JSONParameterEncoder.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation

public struct JSONParameterEncoder: ParameterEncoder {
    static func encode<T: Encodable>(urlRequest: inout URLRequest, with parameters: T) throws {
        let jsonData = try JSONEncoder().encode(parameters)
        urlRequest.httpBody = jsonData
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }
}
