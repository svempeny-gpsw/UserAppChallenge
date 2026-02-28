// UsersViewModel.swift

import Foundation
import Combine

enum UsersState: Equatable {
    case idle
    case loading
    case loaded([User])
    case failed(String)
}

@MainActor
final class UsersViewModel: ObservableObject {
    @Published private(set) var state: UsersState = .idle
    private let apiClient: UsersAPIClientProtocol
    
    init(apiClient: UsersAPIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func load(isRefresh: Bool = false) async {
        // 1. Guard against redundant loads, but allow manual refreshes to pass through.
        if case .loading = state, !isRefresh { return }
    
        // 2. Only show the full-screen spinner if we don't have data yet.
        if !isRefresh {
            state = .loading
        }
        
        do {
            let users = try await apiClient.fetchUsers()
            // 3. Crucial: Check if the task was cancelled before updating the UI state.
            try Task.checkCancellation()
            state = .loaded(users)
        } catch is CancellationError {
            // Do nothing. This prevents the "Error" screen from showing during a refresh.
            print("Fetch cancelled - ignoring state update")
        } catch {
            // 4. Only show error if we aren't performing a background refresh.
            if !isRefresh {
                state = .failed("We couldn't load the users. Please check your connection.")
            }
        }
    }
    deinit {
        print("UsersViewModel deallocated")
    }
}
