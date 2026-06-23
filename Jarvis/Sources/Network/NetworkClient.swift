//
//  NetworkClient.swift
//  Jarvis
//
//  Created by Ajaya Mati on 22/06/26.
//

import Foundation

/// HTTP method types for network requests
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Network errors
public enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data?)
    case networkError(Error)
    case noData
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .invalidResponse:
            return "The response from the server was invalid."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, _):
            return "Server error with status code: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data was returned from the server."
        }
    }
}

/// A generic network client for making HTTP requests
public class NetworkClient {
    private let session: URLSession
    
    static var shared = NetworkClient()
    
    /// Initialize a NetworkClient with an optional custom URLSession
    /// - Parameter session: URLSession to use for requests. Defaults to shared session.
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Make a network request and decode the response
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: The HTTP method to use (default: GET)
    ///   - body: Optional request body (will be JSON encoded)
    ///   - headers: Optional custom HTTP headers
    ///   - responseType: The type to decode the response into
    /// - Returns: Decoded response of type T
    public func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type = T.self
    ) async throws -> T {
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.timeoutInterval = 30
        
        // Set default content type and accept headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Apply custom headers
        if let headers = headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Encode body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.networkError(error)
            }
        }
        
        // Make the request
        let (data, response) = try await session.data(for: urlRequest)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Ensure we have data
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        
        // Decode response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

/// Helper struct to encode any Encodable type
private struct AnyEncodable: Encodable {
    private let value: Encodable
    
    init(_ value: Encodable) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
