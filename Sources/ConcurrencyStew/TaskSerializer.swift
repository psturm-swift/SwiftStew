public actor TaskSerializer {
    private var previousTask: Task<Void, Error>? = nil
    
    public init() {}
    
    public func execute(action: @Sendable @escaping () async throws -> Void) async rethrows {
        let previousTask = self.previousTask
        let newTask = Task {
            let _ = await previousTask?.result
            try Task.checkCancellation()
            try await action()
        }
        self.previousTask = newTask
        try await withTaskCancellationHandler {
            try await newTask.value
        } onCancel: {
            newTask.cancel()
        }
    }
}
