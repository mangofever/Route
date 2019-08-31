//
//  API.swift
//  Route
//
//  Created by 망고 on 15/08/2019.
//  Copyright © 2019 mangofever. All rights reserved.
//

import Foundation

enum Protocol {
    case http
    case https
}

class API<T> {
    let request = APIRequest()
    var response: APIResponse?
    
    var responseChain: ((APIResponse) throws -> T)?
}

class APIRequest {
    var `protocol`: Protocol = .http
    var host: String = ""
    var path: String = ""
    var query = [String: QueryValue]()
}

struct APIResponse {
    var urlResponse: URLResponse?
    var data: Data?
}

extension API {
    @discardableResult
    func request(_ builder: (APIRequestBuilder) -> APIRequestBuilder) -> API {
        _ = builder(APIRequestBuilder(request))
        return self
    }
    
    @discardableResult
    func responseChain(_ builder: (APIResponseChainBuiler<APIResponse>) -> APIResponseChainBuiler<T>) -> API {
        responseChain = builder(APIResponseChainBuiler<APIResponse> {
            return $0
        }).responseChain
        return self
    }
}

class APIRequestBuilder {
    let request: APIRequest
    init(_ request: APIRequest) {
        self.request = request
    }
    
    var http: APIRequestBuilder {
        request.protocol = .http
        return self
    }
    
    var https: APIRequestBuilder {
        request.protocol = .https
        return self
    }
    
    func host(_ host: String) -> Self {
        request.host = host
        return self
    }
    
    func path(_ path: String) -> Self {
        request.path = path
        return self
    }
    
    func query(_ query: [String: QueryValue]) -> Self {
        request.query = query
        return self
    }
    
    func appendQuery(_ query: [String: QueryValue]) -> Self {
        for (key, value) in query {
            request.query[key] = value
        }
        
        return self
    }
}

class APIResponseChainBuiler<T> {
    var responseChain: (APIResponse) throws -> T
    init(_ responseChain: @escaping (APIResponse) throws -> T) {
        self.responseChain = responseChain
    }
    
    func chain<Next>(_ handler: @escaping (T) throws -> Next) -> APIResponseChainBuiler<Next> {
        return APIResponseChainBuiler<Next> {
            return try handler(self.responseChain($0))
        }
    }
}

enum ResponseChainError: Error {
    case validationFailed
    case emptyJSONData
}

extension APIResponseChainBuiler {
    func validate(_ validator: @escaping (T) -> Bool) -> APIResponseChainBuiler<T> {
        return APIResponseChainBuiler<T> {
            let chained = try self.responseChain($0)
            if validator(chained) {
                return chained
            } else {
                throw ResponseChainError.validationFailed //TODO: validation error detail
            }
        }
    }
}

extension APIResponseChainBuiler where T == APIResponse {
    func JSONMapping<U>(_ type: U.Type) -> APIResponseChainBuiler<U> where U: Codable {
        return APIResponseChainBuiler<U> {
            let chained = try self.responseChain($0)
            guard let data = chained.data else {
                throw ResponseChainError.emptyJSONData
            }
            return try JSONDecoder().decode(U.self, from: data)
        }
    }
}

protocol QueryValue {
    var string: String { get }
}

extension String: QueryValue {
    var string: String {
        return self
    }
}

extension Int: QueryValue {
    var string: String {
        return "\(self)"
    }
}

extension Double: QueryValue {
    var string: String {
        return "\(self)"
    }
}
