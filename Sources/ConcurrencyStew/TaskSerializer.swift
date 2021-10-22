public actor TaskSerializer {
    private var previousTask: Awaitable? = nil
    
    public init() {}
    
    public func execute<T>(action: @Sendable @escaping () async throws -> T) async rethrows -> T {
        let previousTask = self.previousTask
        let newTask = Task { () async throws -> T in
            await previousTask?.completion()
            try Task.checkCancellation()
            return try await action()
        }
        self.previousTask = Awaitable(task: newTask)
        return try await withTaskCancellationHandler {
            try await newTask.value
        } onCancel: {
            newTask.cancel()
        }
    }
}

fileprivate struct Awaitable {
    let completion: () async -> Void
    
    init<R, E: Error>(task: Task<R, E>) {
        self.completion = { let _ = await task.result }
    }
}
