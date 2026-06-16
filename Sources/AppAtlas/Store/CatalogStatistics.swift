import Foundation

struct CatalogStatistics: Sendable {
    let totalApps: Int
    let appsPerCategory: [(category: String, count: Int)]
    let totalSizeInBytes: Int64
    let appsWithoutDescription: Int
    let appsWithoutIcon: Int
    let appsWithoutHomepage: Int
    let appsWithLicenseData: Int
}
