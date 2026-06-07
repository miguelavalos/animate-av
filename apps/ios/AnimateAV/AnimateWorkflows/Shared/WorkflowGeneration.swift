struct WorkflowGeneration {
    private var value = 0

    func begin() -> Int {
        value
    }

    func isCurrent(_ generation: Int) -> Bool {
        generation == value
    }

    mutating func advance() {
        value += 1
    }
}
