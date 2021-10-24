// Copyright (c) 2021 Patrick Sturm <psturm-swift@e.mail.de>
// See LICENSE file for licensing information.

import Foundation

@available(iOS 15.0.0, macOS 12.0.0, tvOS 15.0.0, watchOS 8.0.0, *)
struct AnyTask {
    let completion: () async -> Void
    let cancel: () -> Void
    
    init<R, E: Error>(inner task: Task<R, E>) {
        self.completion = { let _ = await task.result }
        self.cancel = { task.cancel() }
    }
}
