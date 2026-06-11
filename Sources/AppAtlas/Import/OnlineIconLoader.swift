import Foundation

actor OnlineIconLoader {
    static let shared = OnlineIconLoader()

    func iconData(from url: URL) async -> Data? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(
                for: request
            )
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  data.count <= 5_000_000,
                  IconQualityInspector.isLikelyAppIcon(data)
            else {
                return nil
            }
            return IconImageConverter.compactPNG(from: data)
        } catch {
            return nil
        }
    }

    func iconData(for homepage: URL) async -> Data? {
        guard let scheme = homepage.scheme,
              let host = homepage.host
        else {
            return nil
        }
        let root = URL(string: "\(scheme)://\(host)")!
        let candidates = [
            "apple-touch-icon.png",
            "apple-touch-icon-precomposed.png",
            "favicon.png",
            "favicon.ico"
        ]
        for candidate in candidates {
            if let data = await iconData(
                from: root.appendingPathComponent(candidate)
            ) {
                return data
            }
        }
        return nil
    }
}
