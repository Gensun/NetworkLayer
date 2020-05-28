//
//  Router.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation
import UIKit

public typealias NetworkRouterCompletion<T> =
    (_ data: T?,
     _ response: URLResponse?,
     _ error: NetworkResponseError?) -> Void
public protocol URLSessionDataTaskProtocol {
    func resume()
    func cancel()
}

public typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void
public protocol URLSessionProtocol {
    func routerDataTask(with request: URLRequest,
                        completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

public protocol NetworkRouter: class {
    associatedtype EndPoint
    associatedtype ResponseObject
    func request(with route: EndPoint,
                 completion: @escaping NetworkRouterCompletion<ResponseObject>)
    func cancel()
}

public class Router<E: EndpointType, R: Codable>: NetworkRouter {
    public typealias EndPoint = E
    public typealias ResponseObject = R
    public var timeoutInterval: TimeInterval = 30
    private var task: URLSessionDataTaskProtocol?
    private let session: URLSessionProtocol
    public convenience init() {
        self.init(session: URLSession.shared)
    }

    public init(session: URLSessionProtocol) {
        self.session = session
    }

    public func request(with route: E, completion:
        @escaping (R?, URLResponse?, NetworkResponseError?) -> Void) {
        do {
            let request = try buildRequest(from: route)
            if let method = request.httpMethod {
                print("\n[NW]")
                print(method + ": " + request.description + "\n")
            }
            if let body = request.httpBody {
                print("[NW]")
                print("Parameters\n\n" + body.description + "\n")
            }
            if let header = request.allHTTPHeaderFields {
                print("[NW]")
                print("HEADER: " + header.description + "\n")
            }
            task = session.routerDataTask(with: request, completionHandler: { data, response, error in
                // Check status code first
                if error == nil, let urlResponse = response as? HTTPURLResponse, data != nil {
                    // If request succeded and there is a responses
                    if let statusError = self.checkStatusCode(with: urlResponse, error: error) {
                        self.handleFailureResponse(with: statusError, with: completion)
                    } else {
                        self.handleSuccessResponse(with: data!, and: response, with: completion)
                    }
                } else {
                    completion(nil, nil, NetworkResponseError.requestFailed(error: error))
                }
            })
        } catch {
            completion(nil, nil, NetworkResponseError.requestFailed(error: error))
        }
        task?.resume()
    }

    private func buildRequest(from route: E) throws -> URLRequest {
        var request = URLRequest(url: route.baseUrl.appendingPathComponent(route.path),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = route.httpMethod.rawValue
        request.allHTTPHeaderFields = route.headers

        switch route.task {
        case .request: break
        case let .requestWithParameters(bodyParameters, urlParameters, pathParameters):
            do {
                if request.httpMethod?.isEmpty ?? false {
                    print("[NW]")
                    print("need to set httpMethod")
                    break
                }
                try configureParameters(with: bodyParameters,
                                        urlParameters: urlParameters,
                                        pathParameters: pathParameters,
                                        and: &request)
            } catch {
                throw error
            }
        case let .GET(queryParameters: queryParameters):
            do {
                request.httpMethod = HttpMethod.get.rawValue
                try configureUrlParameters(with: queryParameters,
                                           headers: nil,
                                           pathParameters: nil,
                                           and: &request)
            } catch {
                throw error
            }
        case let .POST(bodyParameters: bodyParameters):
            do {
                request.httpMethod = HttpMethod.post.rawValue
                try configureParameters(with: bodyParameters,
                                        urlParameters: nil,
                                        pathParameters: nil,
                                        and: &request)
            } catch {
                throw error
            }
        case let .requestWithHeaders(headers: headers, queryParameters: queryParameters):
            do {
                request.httpMethod = HttpMethod.get.rawValue
                try configureUrlParameters(with: queryParameters,
                                           headers: headers,
                                           pathParameters: nil,
                                           and: &request)
            } catch {
                throw error
            }
        }

        return request
    }

    private func configureUrlParameters(with urlParameters: Parameters?,
                                        headers: HttpHeaders?,
                                        pathParameters: [String]?,
                                        and request: inout URLRequest) throws {
        do {
            if let headers = headers {
                try URLParameterEncoder.encode(urlRequest: &request, headers: headers)
            }
            if let urlParameters = urlParameters {
                try URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
            if let pathParameters = pathParameters {
                try URLPathParameterEncoder.encode(urlRequest: &request, with: pathParameters)
            }
        } catch {
            throw error
        }
    }

    private func configureParameters<T: Encodable>(with bodyParameters: T?,
                                                   urlParameters: Parameters?,
                                                   pathParameters: [String]?,
                                                   and request: inout URLRequest) throws {
        do {
            if let bodyParameters = bodyParameters {
                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }
            if let urlParameters = urlParameters {
                try URLParameterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
            if let pathParameters = pathParameters {
                try URLPathParameterEncoder.encode(urlRequest: &request, with: pathParameters)
            }
        } catch {
            throw error
        }
    }

    private func checkStatusCode(with urlResponse: HTTPURLResponse, error: Error?) -> NetworkResponseError? {
        switch urlResponse.statusCode {
        case 200 ... 299: return nil
        case 300 ... 399:
            return NetworkResponseError.redirected(error: error)
        case 403:
            return NetworkResponseError.forbidden(error: error)
        case 400 ... 499:
            return NetworkResponseError.badRequest(error: error)
        case 500 ... 509:
            return NetworkResponseError.serverError(error: error)
        default: return nil
        }
    }

    private func handleSuccessResponse(with data: Data, and urlResponse: URLResponse?,
                                       with completion: @escaping (R?, URLResponse?, NetworkResponseError?) -> Void) {
        NetworkLayer.didFinishWithSuccess?()
        if let urlRes = urlResponse?.url {
            print("\n[NW]")
            print("\nReceived: " + urlRes.description)
        }

        do {
            if var responseObject = try? JSONDecoder().decode(ErrorMetaData.self, from: data) {
                // 200 but error in response
                if let code = responseObject.code {
                    if code == 0 || code == 200 {
                        if var result = try? JSONDecoder().decode(ResponseObject.self, from: data) {
                            print("[\nNW]")
                            print("[S] Reponse: \n" + ((convertToDict(result)?.description) ?? ""))
                            completion(result, urlResponse, nil)
                        }
                    } else {
                        print("\n[NW]\n")
                        print("[S] Error Response: code = " + "\(code)" + "  msg = " + (responseObject.msg ?? "nil"))
                        NetworkLayer.didExecuteWithError?(NetworkResponseError.error(errorData: responseObject))
                        completion(nil, nil, NetworkResponseError.error(errorData: responseObject))
                    }
                }
            }
        } catch let error as Error {
            print("[NW]")
            print("JSONSerialization" + "\(error)")
            completion(nil, nil, NetworkResponseError.parsingError(error: error))
        }
    }

    private func handleFailureResponse(with error: NetworkResponseError,
                                       with completion: @escaping (R?, URLResponse?, NetworkResponseError?) -> Void) {
        NetworkLayer.didFinishWithError?(error)
        print("[NW]")
        print("didFinishWithError" + "\(error)")
        completion(nil, nil, error)
    }

    public func cancel() {
        task?.cancel()
    }

    open func convertToDict(_ res: ResponseObject) -> [String: Any]? {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(res)
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        } catch {
            print(error)
        }
        return [:]
    }
}

public class Downloader {
    public typealias DownloadCompletion = (UIImage?, NetworkError?) -> Void
    private let imageCache = NSCache<NSString, AnyObject>()
    static let sharedInstance = Downloader()
    func downloadImage(from url: URL, with completion: @escaping DownloadCompletion) {
        if let cachedImage = imageCache.object(forKey: url.absoluteString as NSString) as? UIImage {
            completion(cachedImage, nil)
        } else {
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    if let imageToCache = UIImage(data: data) {
                        completion(imageToCache, nil)
                        return
                    }
                    completion(nil, NetworkError.encodingFailed)
                }
            }.resume()
        }
    }
}
