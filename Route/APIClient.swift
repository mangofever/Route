//
//  APIClient.swift
//  Route
//
//  Created by 망고 on 20/08/2019.
//  Copyright © 2019 mangofever. All rights reserved.
//

import Foundation

protocol URLRequesting {
    func send(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

class APIClient {
    var URLRequestor: URLRequesting?
    
    func send<T>(_ api: API<T>, completion: @escaping (Result<T, Error>) -> Void) {
        guard let request = api.toURLRequest() else { return }
        
        URLRequestor?.send(request) { data, urlResponse, error in
            guard let data = data else {
                return
            }
            
            guard let responseChain = api.responseChain else {
                return
            }
            
            do {
                let result = try responseChain(APIResponse(urlResponse: urlResponse, data: data))
                completion(Result.success(result))
            } catch(let error) {
                completion(Result.failure(error))
            }
        }
    }
}
