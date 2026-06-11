import Foundation

enum AppResources {
    static var bundle: Bundle {
        if let resourceURL = Bundle.main.resourceURL,
           let appBundle = Bundle(
               url: resourceURL.appendingPathComponent(
                   "AppAtlas_AppAtlas.bundle",
                   isDirectory: true
               )
           )
        {
            return appBundle
        }
        return Bundle.module
    }
}
