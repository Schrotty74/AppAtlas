import AppKit
import SwiftUI

@MainActor
final class SystemAppearanceObserver: ObservableObject {
    @Published private(set) var colorScheme: ColorScheme

    private var observation: NSKeyValueObservation?

    init(application: NSApplication = .shared) {
        colorScheme = Self.colorScheme(for: application.effectiveAppearance)
        observation = application.observe(
            \.effectiveAppearance,
            options: [.new]
        ) { [weak self, weak application] _, _ in
            Task { @MainActor [weak self, weak application] in
                guard let application else {
                    return
                }
                self?.colorScheme = Self.colorScheme(
                    for: application.effectiveAppearance
                )
            }
        }
    }

    static func colorScheme(for appearance: NSAppearance) -> ColorScheme {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? .dark
            : .light
    }
}
