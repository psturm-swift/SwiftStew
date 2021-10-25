// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

import XCTest
@testable import ConcurrencyStew

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
final class AsyncSectionTests: XCTestCase {
    func testTasksAreExecutedInOrderOnANonReentrantActor() async {
        let actor = NonReentrantActor()

        let t1 = Task.detached { try await actor.add(id: 1, milliseconds: 1_000) }
        let t2 = Task.detached { try await actor.add(id: 3, milliseconds: 100) }
        let t3 = Task.detached { try await actor.add(id: 5, milliseconds: 10) }
        let t4 = Task.detached { try await actor.add(id: 7, milliseconds: 12) }

        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value
        
        let result = await actor.result
        let nonInterleaved = result.nonInterleaved()
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(3, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertTrue(nonInterleaved)
    }

    func testTasksAreStillExecutedInOrderOnANonReentrantActorIfATaskInTheMiddleIsCancelled() async {
        let actor = NonReentrantActor()

        let t1 = Task.detached { try await actor.add(id: 1, milliseconds: 1_000) }
        let t2 = Task.detached { try await actor.add(id: 3, milliseconds: 100) }
        let t3 = Task.detached { try await actor.add(id: 5, milliseconds: 10) }
        let t4 = Task.detached { try await actor.add(id: 7, milliseconds: 12) }

        t2.cancel()
        
        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value
        
        let result = await actor.result.filter { $0 != 3}
        let nonInterleaved = result.nonInterleaved()
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(nil, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertTrue(nonInterleaved)
    }
    
    func testAllTasksAreCancelledButOne() async {
        let actor = NonReentrantActor(policy: .cancelPreviousAction)

        let t1 = Task.detached { try await actor.add(id: 1, milliseconds: 1_000) }
        let t2 = Task.detached { try await actor.add(id: 3, milliseconds: 500) }
        let t3 = Task.detached { try await actor.add(id: 5, milliseconds: 400) }
        let t4 = Task.detached { try await actor.add(id: 7, milliseconds: 100) }

        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value

        XCTAssertEqual([r1, r2, r3, r4].compactMap({ $0 }).count, 1)
    }

    func testTasksAreNotExecutedInOrderOnAReentrantActor() async {
        let actor = ReentrantActor()
        
        let t1 = Task.detached { await actor.add(id: 1, milliseconds: 1_000) }
        let t2 = Task.detached { await actor.add(id: 3, milliseconds: 100) }
        let t3 = Task.detached { await actor.add(id: 5, milliseconds: 10) }
        let t4 = Task.detached { await actor.add(id: 7, milliseconds: 12) }

        let r1 = await t1.value
        let r2 = await t2.value
        let r3 = await t3.value
        let r4 = await t4.value
        
        let result = await actor.result
        let interleaved = !result.nonInterleaved()
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(3, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertTrue(interleaved)
    }
}

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
fileprivate actor NonReentrantActor {
    private let section: AsyncSection
    private(set) var result: [Int] = []
    
    init(policy: AsyncSection.Policy = .waitOnPreviousAction) {
        self.section = AsyncSection(policy: policy)
    }
    
    func add(id: Int, milliseconds: UInt64) async throws -> Int {
        return try await section.execute {
            await self.add(index: id)
            try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
            await self.add(index: id + 1)
            
            return id
        }
    }

    func indices() async -> [Int] { result }

    private func add(index: Int) { result.append(index) }
}

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
fileprivate actor ReentrantActor {
    private(set) var result: [Int] = []
    
    func add(id: Int, milliseconds: UInt64) async -> Int {
        self.add(index: id)
        await Task.sleep(milliseconds * 1_000_000)
        self.add(index: id + 1)

        return id
    }
    
    func indices() async -> [Int] { result }

    private func add(index: Int) { result.append(index) }
}

fileprivate extension Array where Element == Int {
    func nonInterleaved() -> Bool {
        for i in stride(from: 0, to: count, by: 2) {
            guard i + 1 < count else { return false }
            if self[i] + 1 != self[i + 1] {
                return false
            }
        }
        return true
    }
}
