//
//  APIBuilderTests.swift
//  RouteTests
//
//  Created by 망고 on 15/08/2019.
//  Copyright © 2019 mangofever. All rights reserved.
//

import XCTest

class APIBuilderTests: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetHTTP() {
        let api = API<Data>().request {
            $0.http
        }
        
        let urlRequest = api.toURLRequest()
        XCTAssert(urlRequest?.url?.scheme == "http")
    }
    
    func testSetHTTPS() {
        let api = API<Data>().request {
            $0.https
        }

        let urlRequest = api.toURLRequest()
        XCTAssert(urlRequest?.url?.scheme == "https")
    }
    
    func testHost() {
        let hostName = "test.com"
        let api = API<Data>().request {
            $0.host(hostName)
        }
        
        let urlRequest = api.toURLRequest()
        XCTAssert(urlRequest?.url?.host == hostName)
    }
    
    func testPath() {
        let path = "/index.html"
        let api = API<Data>().request {
            $0.host("test.com").path(path)
        }
        
        let urlRequest = api.toURLRequest()
        XCTAssert(urlRequest?.url?.path == path)
    }
    
    func testEscapeSlash() {
        let hostWithSlash = "test.com/"
        let pathWithSlash = "/index.html"
        let api = API<Data>().request {
            $0.host(hostWithSlash).path(pathWithSlash)
        }
        
        let urlRequest = api.toURLRequest()
        XCTAssert(urlRequest?.url?.path == pathWithSlash)
    }
    
    func testQuery() {
        let queryDictionary = ["test": 1]
        let api = API<Data>().request {
            $0.host("test").query(queryDictionary)
        }
        
        let urlRequest = api.toURLRequest()
        XCTAssert(urlRequest?.url?.query == "test=1")
    }
    
    func testAppendQuery() {
        let queryDictionary = ["test": 1]
        let appending = ["test2": 2]
        let api = API<Data>().request {
            $0.host("test")
                .query(queryDictionary)
                .appendQuery(appending)
        }
        
        let urlRequest = api.toURLRequest()
        
        guard let query = urlRequest?.url?.query else {
            XCTFail()
            return
        }
        
        XCTAssert(query.components(separatedBy: "&").count == 2)
        XCTAssert(query.contains("test=1"))
        XCTAssert(query.contains("test2=2"))
    }
}

class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    var urlRequestor: MockURLRequestor!
    override func setUp() {
        apiClient = APIClient()
        urlRequestor = MockURLRequestor()
        apiClient.URLRequestor = urlRequestor
    }
    
    override func tearDown() {}
    
    func testSend() {
        let api = API<Data>().request {
            $0.host("test.com")
        }
        
        apiClient.send(api) { _ in
            
        }
        
        XCTAssert(urlRequestor.sendCalled)
    }
    
    func testResponseChain() {
        var responseChainExecuted = false
        
        let api = API<Bool>()
        .request {
            $0.host("test.com")
        }.responseChain {
            $0.chain { data in
                return "OK"
            }
            .chain { _ in
                return true
            }
        }
        
        apiClient.send(api) {
            switch $0 {
            case .success(let boolValue):
                responseChainExecuted = boolValue
            case .failure:
                XCTFail()
            }
        }
        
        XCTAssert(responseChainExecuted)
    }
    
    func testResponseChainOrder() {
        var count = 0
        
        let api = API<Bool>()
            .request {
                $0.host("test.com")
            }.responseChain {
                $0.chain { data -> String in
                    XCTAssert(count == 0)
                    count += 1
                    return "OK"
                }
                .chain { _ in
                    XCTAssert(count == 1)
                    count += 1
                    return true
                }
        }
        
        apiClient.send(api) {
            switch $0 {
            case .success:
                XCTAssert(count == 2)
            case .failure:
                XCTFail()
            }
        }
    }
    
    func testResponseChainErrorOnLast() {
        let api = API<Bool>()
        .request {
            $0.host("test.com")
        }.responseChain {
            $0.chain { data in
                return "OK"
            }
            .chain { _ in
                throw TestError.exception
            }
        }
        
        apiClient.send(api) {
            switch $0 {
            case .failure(let error as TestError):
                XCTAssert(error == .exception)
            default:
                XCTFail()
            }
        }
    }
    
    func testResponseChainErrorOnFirst() {
        let flag = 1
        let api = API<Bool>()
        .request {
            $0.host("test.com")
        }.responseChain {
            $0.chain { data -> String in
                if flag == 1 {
                    throw TestError.exception
                } else {
                    return "OK"
                }
            }
            .chain { _ in
                return true
            }
        }
        
        apiClient.send(api) {
            switch $0 {
            case .failure(let error as TestError):
                XCTAssert(error == .exception)
            default:
                XCTFail()
            }
        }
    }
    
    func testValidatorSuccess() {
        let api = API<Bool>()
        .request {
            $0.host("test.com")
        }
        .responseChain {
            $0.validate { _ in
                return true
            }.chain { _ in
                return true
            }
        }
        
        apiClient.send(api) {
            switch $0 {
            case .success:
                XCTAssert(true)
            default:
                XCTFail()
            }
        }
    }
    
    func testValidatorFailed() {
        let api = API<Bool>()
        .request {
            $0.host("test.com")
        }
        .responseChain {
            $0.validate { _ in
                return false
            }.chain { _ in
                return true
            }
        }
        
        apiClient.send(api) {
            switch $0 {
            case let .failure(error as ResponseChainError):
                XCTAssert(error == .validationFailed)
            default:
                XCTFail()
            }
        }
    }
    
    func testJSONMapper() {
        let api = API<TestModel>()
        .request {
            $0.host("test.com")
        }
        .responseChain {
            $0.JSONMapping(TestModel.self)
        }
        
        urlRequestor.willReturnJSON(["title": "test", "name": "mango", "order": 2])
        apiClient.send(api) {
            switch $0 {
            case let .success(model):
                XCTAssert(model.title == "test")
                XCTAssert(model.name == "mango")
                XCTAssert(model.order == 2)
            case let .failure(error):
                XCTFail(error.localizedDescription)
            }
        }
    }
    
    func testJSONMapperFailure() {
        let api = API<TestModel>()
        .request {
            $0.host("test.com")
        }
        .responseChain {
            $0.JSONMapping(TestModel.self)
        }
        
        urlRequestor.willReturnJSON(["title": "test", "name": "mango"])
        apiClient.send(api) {
            switch $0 {
            case .failure(_ as DecodingError):
                XCTAssert(true)
            default:
                XCTFail()
            }
        }
    }
}

enum TestError: Error {
    case exception
    case invalid
}

class MockURLRequestor: URLRequesting {
    var sendCalled = false
    var jsonToReturn: [String: Any]?
    func send(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        sendCalled = true
        
        guard let json = jsonToReturn else {
            completion(Data(capacity: 5),nil,nil)
            return
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            completion(Data(capacity: 5),nil,nil)
            return
        }
        
        completion(data,nil,nil)
        
    }
    
    func willReturnJSON(_ json: [String: Any]) {
        jsonToReturn = json
    }
}

struct TestModel: Codable {
    let title: String
    let name: String
    let order: Int
}
