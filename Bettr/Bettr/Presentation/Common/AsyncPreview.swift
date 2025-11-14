import SwiftUI

/// A helper view for SwiftUI previews that asynchronously loads data.
///
/// This view displays a loading indicator, then either the content view with the loaded data
/// or an error message if the async operation fails. This is useful for setting up
/// previews that depend on async initializers (e.g., for a `DatabaseContainer`).
struct AsyncPreview<Value, Content: View>: View {
    @State private var value: Value?
    @State private var error: Error?

    private let operation: () async throws -> Value
    private let content: (Value) -> Content
    
    init(
        operation: @escaping () async throws -> Value,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.operation = operation
        self.content = content
    }
    
    var body: some View {
        if let value {
            content(value)
        } else if let error {
            Text(error.localizedDescription)
                .foregroundStyle(Color.red)
                .padding()
                .onTapGesture {
                    // Allow retrying by tapping the error message
                    self.error = nil
                    Task {
                        await loadValue()
                    }
                }
        } else {
            ProgressView()
                .task {
                   await loadValue()
                }
        }
    }
    
    private func loadValue() async {
        do {
            self.value = try await operation()
        } catch {
            self.error = error
            print("AsyncPreview failed to load: \(error.localizedDescription)")
        }
    }
}
