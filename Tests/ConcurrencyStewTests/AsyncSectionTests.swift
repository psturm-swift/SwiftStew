// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

import XCTest
@testable import ConcurrencyStew

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
final class AsyncSectionTests: XCTestCase {
    func testTasksAreExecutedInOrderOnANonReentrantActor() async {
        let actor = TestActor()

        let t1 = Task.detached { try await actor.executeNonReentrant(id: 1, executionTimeMS: 1_000) }
        let t2 = Task.detached { try await actor.executeNonReentrant(id: 2, executionTimeMS: 100) }
        let t3 = Task.detached { try await actor.executeNonReentrant(id: 3, executionTimeMS: 10) }
        let t4 = Task.detached { try await actor.executeNonReentrant(id: 4, executionTimeMS: 12) }

        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value
        
        let result = await actor.result
        
        let nonInterleaved = result.tasksHaveBeenExecutedInSequence()
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(2, r2)
        XCTAssertEqual(3, r3)
        XCTAssertEqual(4, r4)
        XCTAssertTrue(nonInterleaved)
    }

    func testTasksAreStillExecutedInOrderOnANonReentrantActorIfATaskInTheMiddleIsCancelled() async {
        let actor = TestActor()

        let t1 = Task.detached { try await actor.executeNonReentrant(id: 1, executionTimeMS: 1_000) }
        let t2 = Task.detached { try await actor.executeNonReentrant(id: 2, executionTimeMS: 100) }
        let t3 = Task.detached { try await actor.executeNonReentrant(id: 3, executionTimeMS: 10) }
        let t4 = Task.detached { try await actor.executeNonReentrant(id: 4, executionTimeMS: 12) }

        t2.cancel()
        
        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value
        
        let result = await actor.result
        let nonInterleaved = result.tasksHaveBeenExecutedInSequence()

        XCTAssertEqual(1, r1)
        XCTAssertEqual(nil, r2)
        XCTAssertEqual(3, r3)
        XCTAssertEqual(4, r4)
        XCTAssertTrue(nonInterleaved)
    }
    
    func testAllTasksAreCancelledButOne() async {
        let actor = TestActor(policy: .cancelPreviousAction)

        let t1 = Task.detached { try await actor.executeNonReentrant(id: 1, executionTimeMS: 1_000) }
        let t2 = Task.detached { try await actor.executeNonReentrant(id: 2, executionTimeMS: 100) }
        let t3 = Task.detached { try await actor.executeNonReentrant(id: 3, executionTimeMS: 10) }
        let t4 = Task.detached { try await actor.executeNonReentrant(id: 4, executionTimeMS: 12) }

        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value

        XCTAssertEqual([r1, r2, r3, r4].compactMap({ $0 }).count, 1)
    }

    func testTasksAreNotExecutedInOrderOnAReentrantActor() async throws {
        let actor = TestActor()
        
        let t1 = Task.detached { try await actor.executeReentrant(id: 1, executionTimeMS: 1_000) }
        let t2 = Task.detached { try await actor.executeReentrant(id: 2, executionTimeMS: 100) }
        let t3 = Task.detached { try await actor.executeReentrant(id: 3, executionTimeMS: 10) }
        let t4 = Task.detached { try await actor.executeReentrant(id: 4, executionTimeMS: 12) }

        let r1 = try await t1.value
        let r2 = try await t2.value
        let r3 = try await t3.value
        let r4 = try await t4.value
        
        let result = await actor.result
        let interleaved = !result.tasksHaveBeenExecutedInSequence()

        XCTAssertEqual(1, r1)
        XCTAssertEqual(2, r2)
        XCTAssertEqual(3, r3)
        XCTAssertEqual(4, r4)
        XCTAssertTrue(interleaved)
    }
}

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
fileprivate actor TestActor {
    private let section: AsyncQueue
    private(set) var result: [Int] = []
    
    init(policy: AsyncQueue.Policy = .waitOnPreviousAction) {
        self.section = AsyncQueue(policy: policy)
    }

    func executeReentrant(id: Int, executionTimeMS: UInt64) async throws -> Int {
        return try await execute(id, executionTimeMS)
    }
    
    func executeNonReentrant(id: Int, executionTimeMS: UInt64) async throws -> Int {
        try await section.execute {
            try await self.execute(id, executionTimeMS)
        }
    }

    func indices() async -> [Int] { result }

    private func execute(_ id: Int, _ executionTimeMS: UInt64) async throws -> Int {
        result.append(id)
        try await Task.sleep(nanoseconds: executionTimeMS * 1_000_000)
        result.append(id)

        return id
    }
}

fileprivate extension Array where Element == Int {
    func tasksHaveBeenExecutedInSequence() -> Bool {
        guard count % 2 == 0 else { return false }
        for i in stride(from: 0, to: count, by: 2) {
            if self[i] != self[i + 1] {
                return false
            }
        }
        return true
    }
}
