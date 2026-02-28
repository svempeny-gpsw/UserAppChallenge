// UsersListView.swift

import SwiftUI

struct UsersListView: View {
    @ObservedObject var viewModel: UsersViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .toolbar {
                    Button("Refresh") {
                        Task { await viewModel.load(isRefresh: true) }
                    }
                }
                .task {
                    // Only load on initial appear if state is idle
                    if viewModel.state == .idle {
                        await viewModel.load()
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading…").controlSize(.large)
        case .failed(let message):
            ContentUnavailableView("Error",
                                   systemImage: "exclamationmark.triangle",
                                   description: Text(message))
                .safeAreaInset(edge: .bottom) {
                    Button("Try Again") { Task { await viewModel.load(isRefresh: true) } }
                        .buttonStyle(.borderedProminent)
                }
        case .loaded(let users):
            List(users) { user in
                UserRow(user: user)
            }
            .refreshable { await viewModel.load(isRefresh: true) } 
        }
    }
}


struct UserRow: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(user.name)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
            Text(user.company.name)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        // Staff Tip: Adding a content shape makes the entire row
        // tappable if you add a NavigationLink later.
        .contentShape(Rectangle())
    }
}
