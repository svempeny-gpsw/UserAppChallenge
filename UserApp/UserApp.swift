//
//  UserApp.swift
//  UserApp
//

import SwiftUI

@main
struct UserApp: App {
    
    private let apiClient = UsersAPIClient()
    
    var body: some Scene {
        WindowGroup {
            UsersListView(viewModel:
                            UsersViewModel(apiClient: apiClient))
        }
    }
}
