//
//  Untitled.swift
//  QantasCodeChallenge
//
//  Created by Micah Napier on 12/12/2025.
//

import XCTest
@testable import UserApp

final class UsersViewModelTests: XCTestCase {
    private var mockClient: MockUsersAPIClient!
    
    override func setUp() {
        super.setUp()
        mockClient = MockUsersAPIClient()
    }

    @MainActor
    func test_init_startsInIdleState() {
        let viewModel = UsersViewModel(apiClient: mockClient)
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func test_load_transitionsToLoadedOnSuccess() async {
        // Arrange
        let expectedUsers = [User.stub(id: 1, name: "Test")]
        await mockClient.stubSuccess(expectedUsers)
        let viewModel = UsersViewModel(apiClient: mockClient)

        // Act
        await viewModel.load()

        // Assert
        XCTAssertEqual(viewModel.state, .loaded(expectedUsers))
    }

    @MainActor
    func test_load_transitionsToFailedOnError() async {
        // Arrange
        let error = NSError(domain: "Network", code: -1)
        await mockClient.stubFailure(error)
        let viewModel = UsersViewModel(apiClient: mockClient)

        // Act
        await viewModel.load()

        // Assert
        if case .failed(let message) = viewModel.state {
            XCTAssertTrue(message.contains("connection"))
        } else {
            XCTFail("State should be .failed")
        }
    }

    @MainActor
    func test_load_skipsLoadingStateDuringRefresh() async throws {
        // 1. Pre-load data
        await mockClient.stubSuccess([User.stub(id: 1)])
        let viewModel = UsersViewModel(apiClient: mockClient)
        await viewModel.load()
        
        await mockClient.stubDelay(100_000_000) // 0.1s
        let refreshTask = Task { await viewModel.load(isRefresh: true) }
        // 3. Peek at the state during the fetch
        try await Task.sleep(nanoseconds: 20_000_000) // 0.02s
        // State should remain .loaded during the background fetch, not flip to .loading
        XCTAssertNotEqual(viewModel.state, .loading, "Refresh should maintain existing data on screen")
        await refreshTask.value
    }
    
    @MainActor
    func test_load_handlesCancellationGracefully() async throws {
        // Arrange
        let viewModel = UsersViewModel(apiClient: mockClient)
        await mockClient.stubDelay(500_000_000) // Long delay
        // Act
        let task = Task { await viewModel.load() }
        task.cancel()
        await task.value
        
        // Assert
        // State should either be .loading (if caught early) or .idle,
        // but NEVER .failed because we ignore CancellationError.
        if case .failed = viewModel.state {
            XCTFail("Cancellation should not result in a failed state")
        }
    }
}

// MARK: - Test Stubs
extension User {
    static func stub(id: Int, name: String = "Test User") -> User {
        User(
            id: id,
            name: name,
            username: "testuser",
            email: "test@example.com",
            phone: "1-234-567",
            website: "test.com",
            address: Address(street: "", suite: "", city: "", zipcode: "", geo: nil),
            company: Company(name: "Test Co", catchPhrase: "", bs: "")
        )
    }
}
