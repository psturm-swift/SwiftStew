// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

/// `AsyncSection`  ensures that asynchronous functions are processed in sequence
///
///  With `AsyncSection` it is possible to make actors non-reentrant.
///  The following example shows how to avoid that two actor functions `a` and `b`
///  interleaves although they await another actor.
///  ```swift
///  actor A {
///      private var x: Int = 0
///      private let serializer = AsyncSection()
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
@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
public actor AsyncSection {
    /// The policy describes how `AsyncSection` handles the previous action if a new one should be executed.
    public enum Policy {
        case cancelPreviousAction
        case waitOnPreviousAction
    }
    
    private let policy: Policy
    private var previousTask: AnyTask? = nil
    
    /// Constructs an instance of `AsyncSection`
    /// - Parameters:
    ///   - policy:Specifies  how function `execute(action:)` should handle the previous action
    public init(policy: Policy = .waitOnPreviousAction) {
        self.policy = policy
    }

    /// Executes an action right after the previous action has been finished. This ensures that  one action after the other
    ///  can be executed on ``AsyncSection``. If `policy` is set to `Policy.cancelPreviousAction`, then
    ///  the previous action will be cancelled before the new action will be started.
    ///
    /// - Parameters:
    ///   - action: Asynchronous function that should be executed. The function may throw and return a value.
    /// - Returns: The return value of `action`
    /// - Throws: The error thrown by `action`. Especially throws `CancellationError` if the parent task has been cancelled.
    public func execute<T>(action: @Sendable @escaping () async throws -> T) async throws -> T {
        let newTask = Task { [policy, previousTask] () async throws -> T in
            if policy == .cancelPreviousAction {
                previousTask?.cancel()
            }
            await previousTask?.completion()
            try Task.checkCancellation()
            return try await action()
        }
        self.previousTask = AnyTask(inner: newTask)
        return try await withTaskCancellationHandler {
            try await newTask.value
        } onCancel: {
            newTask.cancel()
        }
    }
}
