import Foundation

actor OnlineIconLoader {
    static let shared = OnlineIconLoader()
    private var processedImageCache: [String: Result<Data, LoadError>] = [:]
    private var homepageIconCache: [String: Data] = [:]

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
            let sourceURL = Self.imageSourceURL(from: url)
            let data = try await processedImageData(from: sourceURL)
            guard IconQualityInspector.isLikelyAppIcon(
                data,
                minimumPixelSize: minimumPixelSize
            ) else {
                throw LoadError.tooSmallOrGeneric
            }
            return data
        } catch {
            if let loadError = error as? LoadError {
                throw loadError
            }
            throw LoadError.downloadFailed
        }
    }

    private func processedImageData(from sourceURL: URL) async throws -> Data {
        let cacheKey = Self.cacheKey(for: sourceURL)
        if let cached = processedImageCache[cacheKey] {
            return try cached.get()
        }

        do {
            let (data, response) = try await fetchData(from: sourceURL)
            guard data.count <= 5_000_000 else {
                throw LoadError.fileTooLarge
            }
            if isSVG(data: data, response: response, url: sourceURL) {
                guard let png = await SVGIconRenderer.compactPNG(from: data) else {
                    throw LoadError.unsupportedImage
                }
                processedImageCache[cacheKey] = .success(png)
                return png
            }

            guard let png = IconImageConverter.compactPNG(from: data) else {
                throw LoadError.unsupportedImage
            }
            processedImageCache[cacheKey] = .success(png)
            return png
        } catch {
            if let loadError = error as? LoadError {
                processedImageCache[cacheKey] = .failure(loadError)
                throw loadError
            }
            processedImageCache[cacheKey] = .failure(.downloadFailed)
            throw LoadError.downloadFailed
        }
    }

    func iconData(for homepage: URL) async -> Data? {
        guard let scheme = homepage.scheme,
              let host = homepage.host
        else {
            return nil
        }
        let homepageCacheKey = Self.cacheKey(for: homepage)
        if let cached = homepageIconCache[homepageCacheKey] {
            return cached
        }

        let root = URL(string: "\(scheme)://\(host)")!
        let candidates = [
            "apple-touch-icon.png",
            "apple-touch-icon-precomposed.png",
            "favicon.png",
            "favicon.ico"
        ]
        for candidate in candidates {
            let candidateURL = root.appendingPathComponent(candidate)
            if let data = await iconData(from: candidateURL) {
                homepageIconCache[homepageCacheKey] = data
                return data
            }
        }
        return nil
    }

    nonisolated static func imageSourceURL(from url: URL) -> URL {
        guard url.path.lowercased() == "/_next/image",
              let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: true
              ),
              let encodedSource = components.queryItems?
                .first(where: { $0.name == "url" })?
                .value?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !encodedSource.isEmpty,
              let sourceURL = URL(
                string: encodedSource,
                relativeTo: url
              )?.absoluteURL
        else {
            return url
        }
        return sourceURL
    }

    nonisolated static func cacheKey(for url: URL) -> String {
        var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: true
        )
        components?.fragment = nil
        return components?.url?.absoluteString ?? url.absoluteString
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
