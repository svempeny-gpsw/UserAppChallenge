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
                    .listRowSeparator(.hidden) // Remove lines
                    .listRowBackground(Color.clear) // Custom background
            }
            .refreshable { await viewModel.load(isRefresh: true) }
            .listStyle(.plain)
            .scrollContentBackground(.hidden) // Required in iOS 16+ to see your background
            .background(LinearGradient(colors: [.blue.opacity(0.1), .white], startPoint: .top, endPoint: .bottom))
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
