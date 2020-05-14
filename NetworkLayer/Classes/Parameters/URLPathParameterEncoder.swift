//
//  URLPathParameterEncoder.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation

public struct URLPathParameterEncoder {
    static func encode(urlRequest: inout URLRequest, with pathParameters: [String]) throws {
        guard urlRequest.url != nil else { throw NetworkError.invalidUrl }
        for parameter in pathParameters {
            urlRequest.url?.appendPathComponent(parameter)
        }
    }
}
