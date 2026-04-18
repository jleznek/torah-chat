import Foundation

/// Sliding-window RPM rate limiter, ported from the desktop TypeScript implementation.
actor RateLimiter {
    private var timestamps: [Date] = []

    /// Wait until there is capacity under the given RPM limit.
    func waitForCapacity(rpm: Int, windowMs: Int) async {
        let window = Double(windowMs) / 1_000
        let effectiveLimit = max(1, rpm - 1) // 1-request safety margin
        while true {
            prune(windowSeconds: window)
            if timestamps.count < effectiveLimit { return }
            let oldest = timestamps[0]
            let waitSeconds = max(0.5, oldest.addingTimeInterval(window).timeIntervalSinceNow + 0.2)
            try? await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))
        }
    }

    func record() {
        timestamps.append(Date())
    }

    func currentUsage(windowMs: Int) -> Int {
        prune(windowSeconds: Double(windowMs) / 1_000)
        return timestamps.count
    }

    private func prune(windowSeconds: Double) {
        let cutoff = Date().addingTimeInterval(-windowSeconds)
        timestamps = timestamps.filter { $0 > cutoff }
    }
}
