//
//  URLRequestConverting.swift
//  Route
//
//  Created by 망고 on 30/10/2019.
//  Copyright © 2019 mangofever. All rights reserved.
//

import Foundation

extension API {
    func toURLRequest() -> URLRequest? {
        guard let url = URL(string: request.urlString()) else {
            return nil
        }

        return URLRequest(url: url)
    }
}

extension APIRequest {
    func urlString() -> String {
        var string = "\(self.protocol.string)://\(host.lastSlashTrimmed())\(path.startingSlashEnsured())"
        if !query.isEmpty {
            string.append("?\(query.queryString())")
        }
        return string
    }
}

private extension Protocol {
    var string: String {
        switch self {
        case .http:
            return "http"
        case .https:
            return "https"
        }
    }
}

private extension String {
    func lastSlashTrimmed() -> String {
        if last != "/" {
            return String(self)
        }

        return String(dropLast())
    }
    
    func startingSlashEnsured() -> String {
        if count == 0 {
            return ""
        }
        
        if starts(with: "/") {
            return String(self)
        }

        return String("/\(self)")
    }
}

private extension Dictionary where Key == String, Value == QueryValue {
    func queryString() -> String {
        var string = ""
        for (key, value) in self {
            if string.count > 0 {
                string.append("&")
            }
            
            string.append("\(key)=\(value.string)")
        }
        
        return string
    }
}
