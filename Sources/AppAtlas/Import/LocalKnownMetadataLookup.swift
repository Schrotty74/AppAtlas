import Foundation

struct LocalKnownMetadata: Sendable {
    let homepage: URL?
    let downloadURL: URL?
    let githubURL: URL?

    init(
        homepage: URL?,
        downloadURL: URL?,
        githubURL: URL? = nil
    ) {
        self.homepage = homepage
        self.downloadURL = downloadURL
        self.githubURL = githubURL
    }
}

enum LocalKnownMetadataLookup {
    private static let exactMatches: [String: LocalKnownMetadata] = [
        "1password": LocalKnownMetadata(
            homepage: URL(string: "https://1password.com/"),
            downloadURL: URL(string: "https://1password.com/downloads/mac/")
        ),
        "acorn": LocalKnownMetadata(
            homepage: URL(string: "https://flyingmeat.com/acorn/"),
            downloadURL: URL(string: "https://flyingmeat.com/acorn/")
        ),
        "adobecreativecloudcleanertool": LocalKnownMetadata(
            homepage: URL(string: "https://helpx.adobe.com/creative-cloud/kb/cc-cleaner-tool-installation-problems.html"),
            downloadURL: URL(string: "https://helpx.adobe.com/creative-cloud/kb/cc-cleaner-tool-installation-problems.html")
        ),
        "adobephotoshop": LocalKnownMetadata(
            homepage: URL(string: "https://www.adobe.com/products/photoshop.html"),
            downloadURL: URL(string: "https://www.adobe.com/products/photoshop.html")
        ),
        "adobephotoshop2024": LocalKnownMetadata(
            homepage: URL(string: "https://www.adobe.com/products/photoshop.html"),
            downloadURL: URL(string: "https://www.adobe.com/products/photoshop.html")
        ),
        "adobephotoshop2025": LocalKnownMetadata(
            homepage: URL(string: "https://www.adobe.com/products/photoshop.html"),
            downloadURL: URL(string: "https://www.adobe.com/products/photoshop.html")
        ),
        "adobephotoshop2026": LocalKnownMetadata(
            homepage: URL(string: "https://www.adobe.com/products/photoshop.html"),
            downloadURL: URL(string: "https://www.adobe.com/products/photoshop.html")
        ),
        "alfred": LocalKnownMetadata(
            homepage: URL(string: "https://www.alfredapp.com/"),
            downloadURL: URL(string: "https://www.alfredapp.com/")
        ),
        "affinity": LocalKnownMetadata(
            homepage: URL(string: "https://affinity.serif.com/"),
            downloadURL: URL(string: "https://affinity.serif.com/")
        ),
        "affinitysuite": LocalKnownMetadata(
            homepage: URL(string: "https://affinity.serif.com/"),
            downloadURL: URL(string: "https://affinity.serif.com/")
        ),
        "affinitydesigner": LocalKnownMetadata(
            homepage: URL(string: "https://affinity.serif.com/designer/"),
            downloadURL: URL(string: "https://affinity.serif.com/designer/")
        ),
        "affinityphoto": LocalKnownMetadata(
            homepage: URL(string: "https://affinity.serif.com/photo/"),
            downloadURL: URL(string: "https://affinity.serif.com/photo/")
        ),
        "affinitypublisher": LocalKnownMetadata(
            homepage: URL(string: "https://affinity.serif.com/publisher/"),
            downloadURL: URL(string: "https://affinity.serif.com/publisher/")
        ),
        "anydesk": LocalKnownMetadata(
            homepage: URL(string: "https://anydesk.com/"),
            downloadURL: URL(string: "https://anydesk.com/downloads/mac-os")
        ),
        "anydeskmacos": LocalKnownMetadata(
            homepage: URL(string: "https://anydesk.com/"),
            downloadURL: URL(string: "https://anydesk.com/downloads/mac-os")
        ),
        "bettertouchtool": LocalKnownMetadata(
            homepage: URL(string: "https://folivora.ai/"),
            downloadURL: URL(string: "https://folivora.ai/")
        ),
        "bravebrowser": LocalKnownMetadata(
            homepage: URL(string: "https://brave.com/"),
            downloadURL: URL(string: "https://brave.com/download/")
        ),
        "cleanshotx": LocalKnownMetadata(
            homepage: URL(string: "https://cleanshot.com/"),
            downloadURL: URL(string: "https://cleanshot.com/")
        ),
        "daisydisk": LocalKnownMetadata(
            homepage: URL(string: "https://daisydiskapp.com/"),
            downloadURL: URL(string: "https://daisydiskapp.com/")
        ),
        "discord": LocalKnownMetadata(
            homepage: URL(string: "https://discord.com/"),
            downloadURL: URL(string: "https://discord.com/download")
        ),
        "downie": LocalKnownMetadata(
            homepage: URL(string: "https://software.charliemonroe.net/downie/"),
            downloadURL: URL(string: "https://software.charliemonroe.net/downie/")
        ),
        "downie4": LocalKnownMetadata(
            homepage: URL(string: "https://software.charliemonroe.net/downie/"),
            downloadURL: URL(string: "https://software.charliemonroe.net/downie/")
        ),
        "firefox": LocalKnownMetadata(
            homepage: URL(string: "https://www.mozilla.org/firefox/"),
            downloadURL: URL(string: "https://www.mozilla.org/firefox/new/")
        ),
        "googlechrome": LocalKnownMetadata(
            homepage: URL(string: "https://www.google.com/chrome/"),
            downloadURL: URL(string: "https://www.google.com/chrome/")
        ),
        "handbrake": LocalKnownMetadata(
            homepage: URL(string: "https://handbrake.fr/"),
            downloadURL: URL(string: "https://handbrake.fr/downloads.php")
        ),
        "iina": LocalKnownMetadata(
            homepage: URL(string: "https://iina.io/"),
            downloadURL: URL(string: "https://iina.io/download/"),
            githubURL: URL(string: "https://github.com/iina/iina")
        ),
        "iterm2": LocalKnownMetadata(
            homepage: URL(string: "https://iterm2.com/"),
            downloadURL: URL(string: "https://iterm2.com/downloads.html")
        ),
        "keka": LocalKnownMetadata(
            homepage: URL(string: "https://www.keka.io/"),
            downloadURL: URL(string: "https://www.keka.io/")
        ),
        "microsoftedge": LocalKnownMetadata(
            homepage: URL(string: "https://www.microsoft.com/edge"),
            downloadURL: URL(string: "https://www.microsoft.com/edge/download")
        ),
        "microsoftoffice": LocalKnownMetadata(
            homepage: URL(string: "https://www.microsoft.com/microsoft-365"),
            downloadURL: URL(string: "https://www.microsoft.com/microsoft-365")
        ),
        "obs": LocalKnownMetadata(
            homepage: URL(string: "https://obsproject.com/"),
            downloadURL: URL(string: "https://obsproject.com/download")
        ),
        "obsstudio": LocalKnownMetadata(
            homepage: URL(string: "https://obsproject.com/"),
            downloadURL: URL(string: "https://obsproject.com/download")
        ),
        "pearcleaner": LocalKnownMetadata(
            homepage: URL(string: "https://github.com/alienator88/Pearcleaner"),
            downloadURL: URL(string: "https://github.com/alienator88/Pearcleaner/releases"),
            githubURL: URL(string: "https://github.com/alienator88/Pearcleaner")
        ),
        "pearcleanerapp": LocalKnownMetadata(
            homepage: URL(string: "https://github.com/alienator88/Pearcleaner"),
            downloadURL: URL(string: "https://github.com/alienator88/Pearcleaner/releases"),
            githubURL: URL(string: "https://github.com/alienator88/Pearcleaner")
        ),
        "rectangle": LocalKnownMetadata(
            homepage: URL(string: "https://rectangleapp.com/"),
            downloadURL: URL(string: "https://rectangleapp.com/"),
            githubURL: URL(string: "https://github.com/rxhanson/Rectangle")
        ),
        "signal": LocalKnownMetadata(
            homepage: URL(string: "https://signal.org/"),
            downloadURL: URL(string: "https://signal.org/download/")
        ),
        "spotify": LocalKnownMetadata(
            homepage: URL(string: "https://www.spotify.com/"),
            downloadURL: URL(string: "https://www.spotify.com/download/mac/")
        ),
        "steam": LocalKnownMetadata(
            homepage: URL(string: "https://store.steampowered.com/"),
            downloadURL: URL(string: "https://store.steampowered.com/about/")
        ),
        "telegram": LocalKnownMetadata(
            homepage: URL(string: "https://telegram.org/"),
            downloadURL: URL(string: "https://desktop.telegram.org/")
        ),
        "theunarchiver": LocalKnownMetadata(
            homepage: URL(string: "https://theunarchiver.com/"),
            downloadURL: URL(string: "https://theunarchiver.com/")
        ),
        "visualstudiocode": LocalKnownMetadata(
            homepage: URL(string: "https://code.visualstudio.com/"),
            downloadURL: URL(string: "https://code.visualstudio.com/download")
        ),
        "vlc": LocalKnownMetadata(
            homepage: URL(string: "https://www.videolan.org/vlc/"),
            downloadURL: URL(string: "https://www.videolan.org/vlc/download-macosx.html")
        ),
        "vlcmediaplayer": LocalKnownMetadata(
            homepage: URL(string: "https://www.videolan.org/vlc/"),
            downloadURL: URL(string: "https://www.videolan.org/vlc/download-macosx.html")
        ),
        "whatsapp": LocalKnownMetadata(
            homepage: URL(string: "https://www.whatsapp.com/"),
            downloadURL: URL(string: "https://www.whatsapp.com/download")
        )
    ]

    static func metadata(for app: AppEntry) -> LocalKnownMetadata? {
        let normalizedName = AppNameMatcher.normalized(app.name)
        if let exact = exactMatches[normalizedName] {
            return exact
        }
        let normalizedFileNames = app.files.map {
            AppNameMatcher.normalized($0.fileName)
        }
        return exactMatches.first { key, _ in
            normalizedFileNames.contains(key)
        }?.value
    }
}
