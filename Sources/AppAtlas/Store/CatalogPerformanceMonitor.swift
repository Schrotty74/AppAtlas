import Foundation

struct CatalogOperationMeasurement: Sendable {
    let operation: String
    let duration: TimeInterval
    let itemCount: Int

    var itemsPerSecond: Double {
        guard duration > 0 else {
            return .infinity
        }
        return Double(itemCount) / duration
    }
}

enum CatalogPerformanceMonitor {
    static func measure<Result>(
        operation: String,
        itemCount: Int,
        _ work: () throws -> Result
    ) rethrows -> (result: Result, measurement: CatalogOperationMeasurement) {
        let start = ContinuousClock.now
        let result = try work()
        let elapsed = start.duration(to: .now)
        let components = elapsed.components
        let seconds = Double(components.seconds)
            + Double(components.attoseconds) / 1_000_000_000_000_000_000
        return (
            result,
            CatalogOperationMeasurement(
                operation: operation,
                duration: seconds,
                itemCount: itemCount
            )
        )
    }
}
