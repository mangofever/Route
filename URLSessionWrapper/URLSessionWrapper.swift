//
//  URLSessionWrapper.swift
//  Route
//
//  Created by 망고 on 30/10/2019.
//  Copyright © 2019 mangofever. All rights reserved.
//

import Foundation

class URLSessionWrapper: URLRequesting {
    func send(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let session = URLSession(configuration: .default)
        session.dataTask(with: request) { data, urlResponse, error in
            completion(data, urlResponse, error)
        }
    }
}
