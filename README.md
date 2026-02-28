# User List App

## Overview

This task is intentionally small and designed to take **60 – 75 minutes**. It will be assessed as a commercial grade application. You will fix and extend a tiny SwiftUI feature that interacts with a real public API.

## UserList App

The main bugs identified and how they were fixed
--------------------------------------------------

1) Compilation issue: User not conforming to Identifiable
Bug:
List(users) failed to compile because User did not conform to Identifiable.

Fix:
Made User conform to Identifiable:

struct User: Decodable, Identifiable { … }

This allows SwiftUI to uniquely identify each row in the list.

2) Incorrect JSON decoding shape
Bug:
The API client attempted to decode a { users: [...] } wrapper, but the real API response is a raw [User] array, causing decoding failures.

Fix:
Updated decoding logic to decode [User] directly and routed decoding through a generic NetworkService:

return try endpoint.decoder.decode([User].self, from: data)

3) UI state updates not guaranteed on the main thread
Bug:
The ViewModel mutated UI state without ensuring execution on the main thread, risking race conditions and undefined UI behavior.

Fix:
Marked the ViewModel with @MainActor:

@MainActor
final class UsersViewModel: ObservableObject { … }

This guarantees all state updates occur on the main thread.

4) Refresh caused flicker and cancellation errors
Bug:
The old implementation treated refresh like a normal load, causing the UI to flicker to a loading state and sometimes show errors when SwiftUI cancelled tasks.

Fix:
Introduced an isRefresh flag and handled CancellationError explicitly:

if !isRefresh { state = .loading }
catch is CancellationError { /* ignore */ }

This keeps existing data visible during refresh and prevents cancellation from surfacing as an error.

5) ViewModel lifecycle misuse (@ObservedObject)
Bug:
The view recreated its own ViewModel, causing repeated initialization and making testing difficult.

Fix:
Moved ViewModel creation to App and injected it into the view:

UsersListView(viewModel: UsersViewModel(apiClient: apiClient))

This stabilises the ViewModel lifecycle and enables dependency injection for tests.

Design decisions and trade-offs
-----------------------------------

Architectural complexity:
The new design introduces protocols, endpoints, and a network layer. This increases code complexity but improves testability, separation of concerns, and scalability.

Data correctness:
Geo.lat and Geo.lng were previously String, which allowed invalid data and prevented numeric operations.
They are now decoded as Double with validation, ensuring:

safer parsing

correct mathematical usage (e.g., distance calculations)

early failure on malformed API data
