// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
//
// See LICENSE file for licensing information.

/// `TaskSerializer`  ensures that asynchronous functions are processed in sequence
///
///  With `TaskSerizalizer` it is possible to make actors non-reentrant.
///  The following example actor functions `a` and `b` cannot interleave although they await another actor.
///  ```swift
///  actor A {
///      private var x: Int = 0
///      private let serializer = TaskSerializer()
///      private var other: OtherActor
///
///      func a() async {
///          await serializer.execute {
///              x += 1
///              await other.a()
///              x -= 1
///          }
///      }
///
///      func b() async -> Int {
///          return await serializer.execute {
///              x += 1
///              await other.b()
///              x -= 1
///              return x
///          }
///      }
///  }
///  ```
public actor TaskSerializer {
    private var previousTask: Awaitable? = nil
    
    /// Constructs an instance of `TaskSerializer`
    public init() {}

    /// Executes an action right after the previous action has been finished. This ensures that  one action after the other
    ///  can be executed on ``TaskSerializer``.
    ///
    /// - Parameters:
    ///   - action: Asynchronous function that should be executed. The function may throw and return a value.
    /// - Returns: The return value of `action`
    /// - Throws: The error thrown by `action`
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
