// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

import XCTest
import Foundation
@testable import ConcurrencyStew

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
final class AsyncUnfoldSequenceTests: XCTestCase {
    func testSimpleAsyncUnfoldSequence() async throws {
        let delayMilliSeconds: UInt64 = 10
        let expectedResult = [0, 1, 2, 3, 4]
        
        let timer = asyncSequence(first: 0, next: { i in
            await Task.sleep(delayMilliSeconds * 1_000_000)
            return i + 1
        })
        
        let start = Date().timeIntervalSince1970
        var actualValues: [Int] = []
        
        for try await i in timer.prefix(expectedResult.count) {
            actualValues.append(i)
        }

        let end = Date().timeIntervalSince1970
        let durationMilliSeconds = UInt64(((end - start) * 1000.0).rounded())

        XCTAssertEqual(expectedResult, actualValues)
        XCTAssertGreaterThanOrEqual(
            durationMilliSeconds,
            UInt64(expectedResult.count) * delayMilliSeconds)
    }
}
