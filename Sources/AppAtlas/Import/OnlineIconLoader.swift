import Foundation

actor OnlineIconLoader {
    static let shared = OnlineIconLoader()

    enum LoadError: LocalizedError {
        case downloadFailed
        case fileTooLarge
        case unsupportedImage
        case tooSmallOrGeneric

        var errorDescription: String? {
            switch self {
            case .downloadFailed:
                "Das Icon konnte von dieser URL nicht geladen werden."
            case .fileTooLarge:
                "Die Bilddatei ist zu groß."
            case .unsupportedImage:
                "Dieses Bildformat konnte nicht als Icon verarbeitet werden."
            case .tooSmallOrGeneric:
                "Das Bild wirkt nicht wie ein verwendbares App-Icon."
            }
        }
    }

    func iconData(from url: URL) async -> Data? {
        try? await iconData(from: url, minimumPixelSize: 128)
    }

    func manualIconData(from url: URL) async throws -> Data {
        try await iconData(from: url, minimumPixelSize: 32)
    }

    private func iconData(
        from url: URL,
        minimumPixelSize: CGFloat
    ) async throws -> Data {
        do {
            let (data, response) = try await fetchData(from: url)
            guard data.count <= 5_000_000 else {
                throw LoadError.fileTooLarge
            }
            if isSVG(data: data, response: response, url: url) {
                guard let png = await SVGIconRenderer.compactPNG(from: data),
                      IconQualityInspector.isLikelyAppIcon(
                        png,
                        minimumPixelSize: minimumPixelSize
                      )
                else {
                    throw LoadError.unsupportedImage
                }
                return png
            }

            guard IconQualityInspector.isLikelyAppIcon(
                data,
                minimumPixelSize: minimumPixelSize
            ) else {
                throw LoadError.tooSmallOrGeneric
            }
            guard let png = IconImageConverter.compactPNG(from: data) else {
                throw LoadError.unsupportedImage
            }
            return png
        } catch {
            if let loadError = error as? LoadError {
                throw loadError
            }
            throw LoadError.downloadFailed
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

    private func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("AppAtlas/0.1", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw LoadError.downloadFailed
        }
        return (data, response)
    }

    private func isSVG(
        data: Data,
        response: URLResponse,
        url: URL
    ) -> Bool {
        if url.pathExtension.lowercased() == "svg" {
            return true
        }
        if response.mimeType?.lowercased().contains("svg") == true {
            return true
        }
        let prefix = String(
            decoding: data.prefix(256),
            as: UTF8.self
        ).lowercased()
        return prefix.contains("<svg") || prefix.contains("image/svg+xml")
    }
}
