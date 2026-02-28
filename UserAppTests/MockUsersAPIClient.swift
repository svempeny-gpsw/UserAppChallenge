//
//  MockUsersAPIClient.swift
//  UserAppTests
//
//  Created by sheen on 28/2/2026.
//

import Foundation
@testable import UserApp

actor MockUsersAPIClient: UsersAPIClientProtocol {
    private var result: Result<[User], Error> = .success([])
    private var fetchDelay: UInt64 = 0

    // Requirement: protocol init
    init(network: NetworkServiceProtocol) {}
    
    // Convenience init for testing
    init() {}

    func fetchUsers() async throws -> [User] {
        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: fetchDelay)
        }
        return try result.get()
    }

    // Explicit stubbing methods to avoid inference errors
    func stubSuccess(_ users: [User]) {
        self.result = .success(users)
    }

    func stubFailure(_ error: Error) {
        self.result = .failure(error)
    }

    func stubDelay(_ nanoseconds: UInt64) {
        self.fetchDelay = nanoseconds
    }
}
