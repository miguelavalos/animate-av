import Foundation

@MainActor
final class AnimateCreateOperationRunner {
    private var tasks: [UUID: Task<Void, Never>] = [:]

    func run(_ operation: @escaping @MainActor () async -> Void) {
        let id = UUID()
        tasks[id] = Task { [weak self] in
            await operation()
            self?.complete(id)
        }
    }

    func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }

    private func complete(_ id: UUID) {
        tasks[id] = nil
    }
}
