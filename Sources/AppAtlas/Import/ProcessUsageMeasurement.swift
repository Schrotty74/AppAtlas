import Darwin
import Foundation

struct ProcessUsageMeasurement: Sendable {
    private let startedAt: ContinuousClock.Instant
    private let startedCPUSeconds: Double

    init() {
        startedAt = ContinuousClock.now
        startedCPUSeconds = Self.cpuSeconds()
    }

    func result(
        concurrency: Int,
        appCount: Int
    ) -> OnlineUpdatePerformance {
        let duration = Double(
            startedAt.duration(to: .now).components.seconds
        ) + Double(
            startedAt.duration(to: .now).components.attoseconds
        ) / 1_000_000_000_000_000_000
        let cpuSeconds = max(Self.cpuSeconds() - startedCPUSeconds, 0)
        let cpuPercent = duration > 0 ? cpuSeconds / duration * 100 : 0
        return OnlineUpdatePerformance(
            measuredAt: Date(),
            concurrency: concurrency,
            appCount: appCount,
            duration: duration,
            averageCPUPercent: cpuPercent
        )
    }

    private static func cpuSeconds() -> Double {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else {
            return 0
        }
        return seconds(usage.ru_utime) + seconds(usage.ru_stime)
    }

    private static func seconds(_ value: timeval) -> Double {
        Double(value.tv_sec) + Double(value.tv_usec) / 1_000_000
    }
}
