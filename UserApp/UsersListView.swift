// UsersListView.swift

import SwiftUI

struct UsersListView: View {
    @ObservedObject var viewModel: UsersViewModel
    @Namespace private var userTransition
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user)
                        .navigationTransition(.zoom(sourceID: user.id, in: userTransition))
                        .navigationBarBackButtonHidden(true)
                }
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
                ZStack(alignment: .leading) {
                    UserRow(user: user)
                    NavigationLink(value: user) {
                        EmptyView()
                    }
                    .opacity(0)
                }
                .matchedTransitionSource(id: user.id, in: userTransition)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.load(isRefresh: true)
            }
            .scrollContentBackground(.hidden)
            .background {
                LinearGradient(
                    colors: [.blue.opacity(0.12), .white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct UserDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(.blue.gradient)
                .frame(width: 100, height: 100)
                .overlay {
                    Text(user.name.prefix(1))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }
            
            Text(user.name)
                .font(.title.bold())
            
            Text(user.email)
                .foregroundStyle(.secondary)
            
            Divider()
            
            Label(user.company.name, systemImage: "building.2")
            Label(user.phone, systemImage: "phone")
            Label(user.website, systemImage: "globe")
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
        .toolbar {
            Button("Done") {
                dismiss()
            }
        }
        
    }
}
