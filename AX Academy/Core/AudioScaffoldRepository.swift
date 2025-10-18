import Foundation

/// Loads locale-specific audio scaffold metadata.  Real audio files can be
/// dropped in later following the manifest naming convention.  The repository
/// falls back to English if a requested locale is unavailable.
public final class AudioScaffoldRepository {
    private let manifest: [String: String]

    public init(locale: Locale = Locale.current) {
        let preferred = locale.languageCode ?? Locale.current.languageCode ?? "en"
        self.manifest = AudioScaffoldRepository.loadManifest(for: preferred)
    }

    public func fileName(for key: String) -> String? {
        if let file = manifest[key] {
            return file
        }
        // Fallback to English file if locale-specific asset is missing
        let fallback = AudioScaffoldRepository.loadManifest(for: "en")
        return fallback[key]
    }

    private static func loadManifest(for languageCode: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: languageCode,
                                        withExtension: "json",
                                        subdirectory: "Localization/Audio") else {
            return [:]
        }
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: String] ?? [:]
        } catch {
            DependencyContainer.shared.resolve(ErrorLogging.self)
                .log(error: error, context: "AudioScaffoldRepository")
            return [:]
        }
    }
}
