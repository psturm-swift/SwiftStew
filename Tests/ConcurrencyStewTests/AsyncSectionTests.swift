// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

import XCTest
@testable import ConcurrencyStew

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
final class AsyncSectionTests: XCTestCase {
    func testTasksAreExecutedInOrderOnANonReentrantActor() async {
        let actor = NonReentrantActor()

        let t1 = Task.detached { try await actor.add(id1: 1, id2: 2, milliseconds: 1_000) }
        let t2 = Task.detached { try await actor.add(id1: 3, id2: 4, milliseconds: 100) }
        let t3 = Task.detached { try await actor.add(id1: 5, id2: 6, milliseconds: 10) }
        let t4 = Task.detached { try await actor.add(id1: 7, id2: 8, milliseconds: 12) }

        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value
        
        let result = await actor.result
        let nonInterleaved =
            result.areConsecutive(id1: 1, id2: 2) &&
            result.areConsecutive(id1: 3, id2: 4) &&
            result.areConsecutive(id1: 5, id2: 6) &&
            result.areConsecutive(id1: 7, id2: 8)
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(3, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertTrue(nonInterleaved)
    }

    func testTasksAreStillExecutedInOrderOnANonReentrantActorIfATaskInTheMiddleIsCancelled() async {
        let actor = NonReentrantActor()

        let t1 = Task.detached { try await actor.add(id1: 1, id2: 2, milliseconds: 1_000) }
        let t2 = Task.detached { try await actor.add(id1: 3, id2: 4, milliseconds: 100) }
        let t3 = Task.detached { try await actor.add(id1: 5, id2: 6, milliseconds: 10) }
        let t4 = Task.detached { try await actor.add(id1: 7, id2: 8, milliseconds: 12) }

        t2.cancel()
        
        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value
        
        let result = await actor.result
        let nonInterleaved =
            result.areConsecutive(id1: 1, id2: 2) &&
            result.areConsecutive(id1: 5, id2: 6) &&
            result.areConsecutive(id1: 7, id2: 8)

        XCTAssertEqual(1, r1)
        XCTAssertEqual(nil, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertTrue(nonInterleaved)
    }
    
    func testAllTasksAreCancelledButOne() async {
        let actor = NonReentrantActor(policy: .cancelPreviousAction)

        let t1 = Task.detached { try await actor.add(id1: 1, id2: 2, milliseconds: 1_000) }
        let t2 = Task.detached { try await actor.add(id1: 3, id2: 4, milliseconds: 100) }
        let t3 = Task.detached { try await actor.add(id1: 5, id2: 6, milliseconds: 10) }
        let t4 = Task.detached { try await actor.add(id1: 7, id2: 8, milliseconds: 12) }

        let r1 = try? await t1.value
        let r2 = try? await t2.value
        let r3 = try? await t3.value
        let r4 = try? await t4.value

        XCTAssertEqual([r1, r2, r3, r4].compactMap({ $0 }).count, 1)
    }

    func testTasksAreNotExecutedInOrderOnAReentrantActor() async {
        let actor = ReentrantActor()
        
        let t1 = Task.detached { await actor.add(id1: 1, id2: 2, milliseconds: 1_000) }
        let t2 = Task.detached { await actor.add(id1: 3, id2: 4, milliseconds: 100) }
        let t3 = Task.detached { await actor.add(id1: 5, id2: 6, milliseconds: 10) }
        let t4 = Task.detached { await actor.add(id1: 7, id2: 8, milliseconds: 12) }

        let r1 = await t1.value
        let r2 = await t2.value
        let r3 = await t3.value
        let r4 = await t4.value
        
        let result = await actor.result
        let interleaved =
            !result.areConsecutive(id1: 1, id2: 2) ||
            !result.areConsecutive(id1: 3, id2: 4) ||
            !result.areConsecutive(id1: 5, id2: 6) ||
            !result.areConsecutive(id1: 7, id2: 8)

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
    
    func add(id1: Int, id2: Int, milliseconds: UInt64) async throws -> Int {
        return try await section.execute {
            await self.add(index: id1)
            try await Task.sleep(nanoseconds: milliseconds * 1_000_000)
            await self.add(index: id2)
            
            return id1
        }
    }

    func indices() async -> [Int] { result }

    private func add(index: Int) { result.append(index) }
}

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
fileprivate actor ReentrantActor {
    private(set) var result: [Int] = []
    
    func add(id1: Int, id2: Int, milliseconds: UInt64) async -> Int {
        self.add(index: id1)
        await Task.sleep(milliseconds * 1_000_000)
        self.add(index: id2)

        return id1
    }
    
    func indices() async -> [Int] { result }

    private func add(index: Int) { result.append(index) }
}

fileprivate extension Array where Element == Int {
    func areConsecutive(id1: Int, id2: Int) -> Bool {
        guard let index1 = firstIndex(of: id1) else { return false }
        guard let index2 = firstIndex(of: id2) else { return false }
        return index1 + 1 == index2
    }
}
