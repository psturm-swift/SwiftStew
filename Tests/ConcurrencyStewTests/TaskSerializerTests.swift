import XCTest
@testable import ConcurrencyStew

final class TaskSerializerTests: XCTestCase {
    func testTasksAreExecutedInOrderOnANonReentrantActor() async {
        let actor = NonReentrantActor()

        let t1 = Task.detached { await actor.add(index1: 0, index2: 1, milliseconds: 1_000) }
        let t2 = Task.detached { await actor.add(index1: 2, index2: 3, milliseconds: 100) }
        let t3 = Task.detached { await actor.add(index1: 4, index2: 5, milliseconds: 10) }
        let t4 = Task.detached { await actor.add(index1: 6, index2: 7, milliseconds: 10) }

        let r1 = await t1.value
        let r2 = await t2.value
        let r3 = await t3.value
        let r4 = await t4.value
        
        let inOrder = await actor.result.isInOrder()
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(3, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertTrue(inOrder)
    }
    
    func testTasksAreNotExecutedInOrderOnAReentrantActor() async {
        let actor = ReentrantActor()

        let t1 = Task.detached { await actor.add(index1: 0, index2: 1, milliseconds: 1_000) }
        let t2 = Task.detached { await actor.add(index1: 2, index2: 3, milliseconds: 100) }
        let t3 = Task.detached { await actor.add(index1: 4, index2: 5, milliseconds: 10) }
        let t4 = Task.detached { await actor.add(index1: 6, index2: 7, milliseconds: 10) }

        let r1 = await t1.value
        let r2 = await t2.value
        let r3 = await t3.value
        let r4 = await t4.value

        let inOrder = await actor.result.isInOrder()
        
        XCTAssertEqual(1, r1)
        XCTAssertEqual(3, r2)
        XCTAssertEqual(5, r3)
        XCTAssertEqual(7, r4)
        XCTAssertFalse(inOrder)
    }
}

fileprivate actor NonReentrantActor {
    private let taskSerializer = TaskSerializer()
    private(set) var result: [Int] = []
    
    func add(index1: Int, index2: Int, milliseconds: UInt64) async -> Int {
        return await taskSerializer.execute {
            await self.addIndex(index: index1)
            await Task.sleep(milliseconds * 1_000)
            await self.addIndex(index: index2)
            return index2
        }
    }
    
    func indices() async -> [Int] { result }

    private func addIndex(index: Int) { result.append(index) }
}

fileprivate actor ReentrantActor {
    private(set) var result: [Int] = []
    
    func add(index1: Int, index2: Int, milliseconds: UInt64) async -> Int {
        self.addIndex(index: index1)
        await Task.sleep(milliseconds * 1_000)
        self.addIndex(index: index2)
        return index2
    }
    
    func indices() async -> [Int] { result }

    private func addIndex(index: Int) { result.append(index) }
}

fileprivate extension Array where Element: Comparable {
    func isInOrder() -> Bool {
        guard let first = first else { return true }
        var previous = first

        for current in dropFirst() {
            if current <= previous {
                return false
            }
            previous = current
        }
        return true
    }
}
