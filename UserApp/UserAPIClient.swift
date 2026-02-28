// UsersAPIClient.swift

import Foundation

protocol APIConfiguration: Sendable {
    var baseURL: URL { get }
}

enum APIError: Error {
    case invalidURL
    case transportError(Error)
    case serverError(statusCode: Int, data: Data?)
    case decodingError(Error, rawData: Data?)
}

struct APIEnvironment: APIConfiguration {
    let baseURL: URL
    
    static let production = APIEnvironment(baseURL: URL(string: "https://jsonplaceholder.typicode.com")!)
    static let staging = APIEnvironment(baseURL: URL(string: "https://staging-api.com")!)
}

protocol NetworkServiceProtocol: Sendable {
    func fetchData<T: Decodable>(endpoint: EndPointProviding) async throws -> T
}

final class NetworkService: NetworkServiceProtocol, Sendable {
    private let session: URLSession
    private let configuration: APIConfiguration
    
    init(session: URLSession = .shared,
         configuration: APIConfiguration = APIEnvironment.production) {
        self.session = session
        self.configuration = configuration
    }
    
    func fetchData<T: Decodable>(endpoint: EndPointProviding) async throws -> T {
        let baseURL = configuration.baseURL
        let cleanPath = endpoint.path.trimmingCharacters(in: .init(charactersIn: "/"))
        let fullURL = baseURL.appendingPathComponent(cleanPath)
        
        guard var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        components.queryItems = endpoint.queryItems
        guard let finalURL = components.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method
        endpoint.headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.transportError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(statusCode: 0, data: data)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
        
        do {
            return try endpoint.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error, rawData: data)
        }
    }
}

protocol EndPointProviding: Sendable {
    var path: String { get }
    var method: String { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
    var decoder: JSONDecoder { get }
}

extension EndPointProviding {
    var method: String { "GET" }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }
}

enum UserEndpoint: EndPointProviding {
    case allUsers
    
    var path: String {
        switch self {
        case .allUsers:
            "users"
        }
    }
    
    private static let sharedDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    var decoder: JSONDecoder {
        Self.sharedDecoder
    }
    
}


protocol UsersAPIClientProtocol: Sendable {
    init(network: NetworkServiceProtocol)
    func fetchUsers() async throws -> [User]
    
}

struct UsersAPIClient: UsersAPIClientProtocol {
    private let network: NetworkServiceProtocol
    
    // Senior Move: Inject the protocol, not the concrete class.
    init(network: NetworkServiceProtocol = NetworkService()) {
        self.network = network
    }
    
    func fetchUsers() async throws -> [User] {
        return try await network.fetchData(endpoint: UserEndpoint.allUsers)
    }
    
}
