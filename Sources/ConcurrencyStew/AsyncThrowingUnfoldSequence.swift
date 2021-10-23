// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

/// A asynchronous sequence whose elements are produced by a closure depending on some state.
///
/// `AsyncThrowingUnfoldSequence` works quite similiar to `UnfoldSequence`.
/// The elements of the sequence are computed asynchronously and lazily. The sequence might produce an infinite
/// number of elements.
public struct AsyncThrowingUnfoldSequence<Element, State>: AsyncSequence {
    public typealias NextClosure = @Sendable (inout State) async throws -> Element?

    public struct AsyncIterator: AsyncIteratorProtocol {
        var state: State
        let next: NextClosure
        
        public mutating func next() async throws -> Element? {
            try await next(&state)
        }
    }
    
    private let state: State
    private let next: NextClosure

    /// Initialize the sequence with an initial state and a closure
    /// - Parameters:
    ///   - state: The initial state from which the first element is computed
    ///   - next: The closure that updates the `state` and returns the next element. `next` is allowed to throw errors.
    public init(state: State, next: @escaping NextClosure) {
        self.state = state
        self.next = next
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(state: self.state, next: self.next)
    }
}
