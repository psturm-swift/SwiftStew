import XCTest
@testable import ConcurrencyStew

final class TaskSerializerTests: XCTestCase {
    func testTasksAreExecutedInOrder() async {
        let taskSerizalizer = TaskSerializer()
        let resultCollector = ResultCollector()

        let t1 = Task.detached {
            await taskSerizalizer.execute {
                await resultCollector.add(index: 0)
                await Task.sleep(1_000_000_000)
                await resultCollector.add(index: 1)
            }
        }
        
        let t2 = Task.detached {
            await taskSerizalizer.execute {
                await resultCollector.add(index: 2)
                await Task.sleep(10_000_000)
                await resultCollector.add(index: 3)
            }
        }

        let t3 = Task.detached {
            await taskSerizalizer.execute {
                await resultCollector.add(index: 4)
                await Task.sleep(1_000)
                await resultCollector.add(index: 5)
            }
        }

        let _ = await t1.result
        let _ = await t2.result
        let _ = await t3.result
        
        let inOrder = await resultCollector.isInOrder()
        
        XCTAssertTrue(inOrder)
    }
    
    func testTasksAreNotExecutedInOrderWithoutSerializer() async {
        let resultCollector = ResultCollector()

        let t1 = Task.detached {
            await resultCollector.add(index: 0)
            await Task.sleep(1_000_000_000)
            await resultCollector.add(index: 1)
        }
        
        let t2 = Task.detached {
            await resultCollector.add(index: 2)
            await Task.sleep(10_000_000)
            await resultCollector.add(index: 3)
        }

        let t3 = Task.detached {
            await resultCollector.add(index: 4)
            await Task.sleep(1_000)
            await resultCollector.add(index: 5)
        }

        let _ = await t1.result
        let _ = await t2.result
        let _ = await t3.result
        
        let inOrder = await resultCollector.isInOrder()
        
        XCTAssertFalse(inOrder)
    }
}

fileprivate actor ResultCollector {
    private(set) var result: [Int] = []
    
    func add(index: Int) {
        result.append(index)
    }
    
    func isInOrder() -> Bool {
        guard let first = result.first else { return true }
        var previous = first
        
        for current in result.dropFirst() {
            if current <= previous {
                return false
            }
            previous = current
        }
        return true
    }
}
