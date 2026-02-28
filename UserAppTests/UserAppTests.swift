//
//  UserAppTests.swift
//  UserAppTests
//
//  Created by Micah Napier on 11/12/2025.
//

import Testing
import Foundation
@testable import UserApp

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var dataToReturn: Data?
    var errorToThrow: Error?
    
    func fetchData<T: Decodable>(endpoint: EndPointProviding) async throws -> T {
        if let error = errorToThrow { throw error }
        guard let data = dataToReturn else {
            throw APIError.invalidURL // Or a specific test error
        }
        return try endpoint.decoder.decode(T.self, from: data)
    }
}

@Suite("User API Client Tests")
struct UserAPIClientTests {
    
    @Test("Verify fetchUsers parses valid JSON correctly")
    func fetchUsersSuccess() async throws {
        // Arrange
        let mockNetwork = MockNetworkService()
        let client = await UsersAPIClient(network: mockNetwork)
        
        // This JSON simulates the exact structure from JSONPlaceholder,
        // including the stringified lat/lng which our Geo init handles.
        let jsonString = """
        [
            {
                "id": 1,
                "name": "Leanne Graham",
                "username": "Bret",
                "email": "Sincere@april.biz",
                "address": {
                    "street": "Kulas Light",
                    "suite": "Apt. 556",
                    "city": "Gwenborough",
                    "zipcode": "92998-3874",
                    "geo": { "lat": "-37.3159", "lng": "81.1496" }
                },
                "phone": "1-770-736-8031 x56442",
                "website": "hildegard.org",
                "company": {
                    "name": "Romaguera-Crona",
                    "catchPhrase": "Multi-layered client-server neural-net",
                    "bs": "harness real-time e-markets"
                }
            }
        ]
        """
        mockNetwork.dataToReturn = jsonString.data(using: .utf8)
        
        // Act
        let users = try await client.fetchUsers()
        
        // Assert
        #expect(users.count == 1)
        #expect(users.first?.name == "Leanne Graham")
        await #expect(users.first?.address.geo?.lat == -37.3159) // Verified custom Double conversion
    }
    
    @Test("Verify fetchUsers throws decoding error on malformed Geo data")
    func fetchUsersDecodingFailure() async throws {
        // Arrange
        let mockNetwork = MockNetworkService()
        let client = await UsersAPIClient(network: mockNetwork)
        
        // Malformed lat/lng (not numbers)
        let badJson = """
        [ { "id": 1, "address": { "geo": { "lat": "not-a-number", "lng": "81.1496" } } } ]
        """
        mockNetwork.dataToReturn = badJson.data(using: .utf8)
        
        // Act & Assert
        await #expect(throws: Error.self) {
            try await client.fetchUsers()
        }
    }
}
