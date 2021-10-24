// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

/// A asynchronous sequence whose elements are produced by a closure depending on some state.
///
/// `AsyncUnfoldSequence` works quite similiar to `UnfoldSequence`.
/// The elements of the sequence are computed asynchronously and lazily. The sequence might produce an infinite
/// number of elements.
/// Instances of AsyncUnfoldSequence are created by functions ``asyncSequence(first:next:)``
/// and ``asyncSequence(state:next:)``.
@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
public struct AsyncUnfoldSequence<Element, State>: AsyncSequence {
    public typealias NextClosure = @Sendable (inout State) async -> Element?

    public struct AsyncIterator: AsyncIteratorProtocol {
        var state: State
        let next: NextClosure
        
        public mutating func next() async -> Element? {
            await next(&state)
        }
    }
    
    private let state: State
    private let next: NextClosure

    /// Initialize the sequence with an initial state and a closure
    /// - Parameters:
    ///   - state: The initial state from which the first element is computed
    ///   - next: The closure that updates the `state` and returns the next element.
    init(state: State, next: @escaping NextClosure) {
        self.state = state
        self.next = next
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(state: self.state, next: self.next)
    }
}

/// Creates  an asynchronous sequence by an initial state and an asynchronous closure.
/// - Parameters:
///   - state: The initial state from which the first element is computed
///   - next: The closure that updates the `state` and returns the next element.
@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
public func asyncSequence<Element, State>(
    state: State,
    next: @escaping AsyncUnfoldSequence<Element, State>.NextClosure
) -> AsyncUnfoldSequence<Element, State> {
    AsyncUnfoldSequence<Element, State>(state: state, next: next)
}

/// Creates  an asynchronous sequence by an initial state and an asynchronous closure.
/// - Parameters:
///   - first: First element of the sequence.
///   - next: The closure computes asynchronous the next element from the previous element
@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
public func asyncSequence<Element>(
    first: Element,
    next: @escaping @Sendable (Element) async -> Element?
) -> AsyncUnfoldSequence<Element, Element?> {
    asyncSequence(state: first) { state async -> Element? in
        guard let current = state else { return nil }
        state = await next(current)
        return current
    }
}
