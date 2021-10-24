// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

import XCTest
import Foundation
@testable import ConcurrencyStew

final class AsyncThrowingUnfoldSequenceTests: XCTestCase {
    func testSimpleAsyncThrowingUnfoldSequence() async throws {
        let delayMilliSeconds: UInt64 = 10
        let expectedResult = [0, 1, 2, 3, 4]
        
        let timer = asyncSequence(first: 0, next: { i in
            if i == expectedResult.count {
                throw CancellationError()
            }
            await Task.sleep(delayMilliSeconds * 1_000_000)
            return i + 1
        })
        
        let start = Date().timeIntervalSince1970
        var actualValues: [Int] = []
        var execeptionHasBeenThrown = false
        
        do {
            for try await i in timer {
                actualValues.append(i)
            }
        }
        catch {
            execeptionHasBeenThrown = true
        }
        
        let end = Date().timeIntervalSince1970
        let durationMilliSeconds = UInt64(((end - start) * 1000.0).rounded())

        XCTAssertTrue(execeptionHasBeenThrown)
        XCTAssertEqual(expectedResult, actualValues)
        XCTAssertGreaterThanOrEqual(
            durationMilliSeconds,
            UInt64(expectedResult.count) * delayMilliSeconds)
    }
}
