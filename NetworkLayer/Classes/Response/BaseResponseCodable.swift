//
//  BaseResponseCodable.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation

public enum NetworkResponseError: Error {
    case error(errorData: ErrorMetaData)
    case parsingError(error: Error?)
    case requestFailed(error: Error?)
    case badRequest(error: Error?)
    case forbidden(error: Error?)
    case serverError(error: Error?)
    case redirected(error: Error?)
    case migration(error: Error?)
}

public enum ResponseErrors: Int {
    case migration = 111
    case unknown = 999
}

public protocol ErrorHandler {
    var code: Int? { get }
    var msg: String? { get }
}

public typealias ServiceResponseCodable = Codable & ErrorHandler

public protocol ServiceResponseProtocol: Codable {
    func getServiceResponse() -> ServiceResponseCodable
}

public struct ErrorMetaData: Codable {
    var startupTitle: String?
    var startupMessage: String?
}
