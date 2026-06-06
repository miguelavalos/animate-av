import Foundation

extension MomentsCreateViewModel {
    func runOperation(_ operation: @escaping @MainActor () async -> Void) {
        operationRunner.run(operation)
    }

    func cancelOperations() {
        operationRunner.cancelAll()
    }
}
