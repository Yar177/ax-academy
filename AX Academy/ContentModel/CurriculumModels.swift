import Foundation

/// Represents a localized string that can resolve to different translations
/// based on locale. JSON entries specify a `defaultLocale` and a dictionary of
/// translations. Authoring tools can extend this structure for pluralization
/// in a future revision without breaking existing clients.
public struct LocalizedText: Codable, Hashable {
    public var defaultLocale: String
    public var translations: [String: String]

    public init(defaultLocale: String = "en", translations: [String: String]) {
        self.defaultLocale = defaultLocale
        self.translations = translations
    }

    /// Returns the resolved string for the given locale. If no translation is
    /// available the method falls back to the default locale and finally any
    /// available translation.
    public func resolve(for locale: Locale = .current) -> String {
        let languageCode = locale.languageCode ?? defaultLocale
        if let localized = translations[languageCode] {
            return localized
        }
        if let fallback = translations[defaultLocale] {
            return fallback
        }
        return translations.values.first ?? ""
    }
}

/// Semantic version used to track curriculum catalog revisions. The version is
/// surfaced in analytics and the caregiver dashboard so that downstream systems
/// can understand which dataset produced reported results.
public struct CurriculumVersion: Codable, Hashable, CustomStringConvertible {
    public var major: Int
    public var minor: Int
    public var patch: Int

    public init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }
}

/// Root container that groups all curriculum artifacts. The metadata block
/// describes storage and localization policies so that the bundled JSON can be
/// promoted to a cloud-backed service without schema changes.
public struct CurriculumCatalog: Codable {
    public struct Metadata: Codable, Hashable {
        public var version: CurriculumVersion
        public var generatedAt: Date
        public var defaultLocale: String
        public var storage: StoragePlan
        public var localization: LocalizationPlan
    }

    /// Describes where the catalog lives today and how it migrates to the cloud
    /// in the future.
    public struct StoragePlan: Codable, Hashable {
        public var bundleResource: String
        public var cloudContainer: String
        public var stagingContainer: String
    }

    /// Captures supported locales and the resolution strategy used by authoring
    /// tools. The strategy value is intentionally descriptive so that front-end
    /// code can choose between run-time and build-time localization approaches.
    public struct LocalizationPlan: Codable, Hashable {
        public var supportedLocales: [String]
        public var fallbackLocale: String
        public var strategy: String
    }

    public var metadata: Metadata
    public var standards: [Standard]
    public var skills: [Skill]
    public var strands: [LearningStrand]
    public var lessons: [Lesson]
    public var assets: [MultimediaAsset]

    public static let empty = CurriculumCatalog(
        metadata: .init(
            version: CurriculumVersion(major: 0, minor: 0, patch: 0),
            generatedAt: Date(timeIntervalSince1970: 0),
            defaultLocale: "en",
            storage: .init(
                bundleResource: "curriculum_v1.json",
                cloudContainer: "",
                stagingContainer: ""
            ),
            localization: .init(
                supportedLocales: ["en"],
                fallbackLocale: "en",
                strategy: "bundle-only"
            )
        ),
        standards: [],
        skills: [],
        strands: [],
        lessons: [],
        assets: []
    )
}

/// Learning standards such as NY Next Generation or Common Core benchmarks. A
/// standard can be tagged to multiple skills.
public struct Standard: Identifiable, Codable, Hashable {
    public var id: String
    public var code: String
    public var grade: Grade
    private var descriptionText: LocalizedText
    public var strandID: String
    public var skillIDs: [String]

    public init(id: String,
                code: String,
                grade: Grade,
                description: LocalizedText,
                strandID: String,
                skillIDs: [String]) {
        self.id = id
        self.code = code
        self.grade = grade
        self.descriptionText = description
        self.strandID = strandID
        self.skillIDs = skillIDs
    }

    public var description: String { descriptionText.resolve() }

    private enum CodingKeys: String, CodingKey {
        case id
        case code
        case grade
        case descriptionText = "description"
        case strandID
        case skillIDs
    }
}

/// A granular learning objective aligned to one or more standards. Skills map
/// directly to lessons and analytics reporting.
public struct Skill: Identifiable, Codable, Hashable {
    public var id: String
    public var grade: Grade
    public var strandID: String
    private var titleText: LocalizedText
    private var overviewText: LocalizedText
    public var standardIDs: [String]
    public var prerequisiteSkillIDs: [String]
    public var assetIDs: [String]

    public init(id: String,
                grade: Grade,
                strandID: String,
                title: LocalizedText,
                overview: LocalizedText,
                standardIDs: [String],
                prerequisiteSkillIDs: [String],
                assetIDs: [String]) {
        self.id = id
        self.grade = grade
        self.strandID = strandID
        self.titleText = title
        self.overviewText = overview
        self.standardIDs = standardIDs
        self.prerequisiteSkillIDs = prerequisiteSkillIDs
        self.assetIDs = assetIDs
    }

    public var title: String { titleText.resolve() }
    public var overview: String { overviewText.resolve() }

    private enum CodingKeys: String, CodingKey {
        case id
        case grade
        case strandID
        case titleText = "title"
        case overviewText = "overview"
        case standardIDs
        case prerequisiteSkillIDs
        case assetIDs
    }
}

/// Organises skills into instructional sequences. Each strand surfaces to the
/// learner as a pathway with practice, challenge, and remediation experiences.
public struct LearningStrand: Identifiable, Codable, Hashable {
    public var id: String
    public var grade: Grade
    private var titleText: LocalizedText
    private var summaryText: LocalizedText
    public var skillIDs: [String]
    public var standardIDs: [String]
    public var assetIDs: [String]

    public init(id: String,
                grade: Grade,
                title: LocalizedText,
                summary: LocalizedText,
                skillIDs: [String],
                standardIDs: [String],
                assetIDs: [String]) {
        self.id = id
        self.grade = grade
        self.titleText = title
        self.summaryText = summary
        self.skillIDs = skillIDs
        self.standardIDs = standardIDs
        self.assetIDs = assetIDs
    }

    public var title: String { titleText.resolve() }
    public var summary: String { summaryText.resolve() }

    private enum CodingKeys: String, CodingKey {
        case id
        case grade
        case titleText = "title"
        case summaryText = "summary"
        case skillIDs
        case standardIDs
        case assetIDs
    }
}

/// Metadata for multimedia assets such as instructional videos, AR
/// manipulatives, or printable PDFs. Storage locations describe how the app can
/// access the assets locally today and remotely when cloud distribution is
/// enabled.
public struct MultimediaAsset: Identifiable, Codable, Hashable {
    public enum Kind: String, Codable { case illustration, audio, video, interactive, document }

    public struct Storage: Codable, Hashable {
        public var bundleResource: String?
        public var remoteURL: String?
        public var checksum: String?
    }

    public struct Localization: Codable, Hashable {
        public var supportedLocales: [String]
        public var defaultLocale: String
        public var captionPolicy: String
    }

    public struct Accessibility: Codable, Hashable {
        private var altTextValue: LocalizedText?
        public var hasCaptions: Bool
        public var hasAudioDescription: Bool

        public init(altText: LocalizedText?, hasCaptions: Bool, hasAudioDescription: Bool) {
            self.altTextValue = altText
            self.hasCaptions = hasCaptions
            self.hasAudioDescription = hasAudioDescription
        }

        public var altText: String? {
            altTextValue?.resolve()
        }

        private enum CodingKeys: String, CodingKey {
            case altTextValue
            case altText
            case hasCaptions
            case hasAudioDescription
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let localized = try container.decodeIfPresent(LocalizedText.self, forKey: .altTextValue) {
                altTextValue = localized
            } else {
                altTextValue = try container.decodeIfPresent(LocalizedText.self, forKey: .altText)
            }
            hasCaptions = try container.decode(Bool.self, forKey: .hasCaptions)
            hasAudioDescription = try container.decode(Bool.self, forKey: .hasAudioDescription)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(altTextValue, forKey: .altTextValue)
            try container.encode(hasCaptions, forKey: .hasCaptions)
            try container.encode(hasAudioDescription, forKey: .hasAudioDescription)
        }
    }

    public var id: String
    public var kind: Kind
    private var titleText: LocalizedText
    private var descriptionText: LocalizedText
    public var tags: [String]
    public var storage: Storage
    public var localization: Localization
    public var accessibility: Accessibility

    public init(id: String,
                kind: Kind,
                title: LocalizedText,
                description: LocalizedText,
                tags: [String],
                storage: Storage,
                localization: Localization,
                accessibility: Accessibility) {
        self.id = id
        self.kind = kind
        self.titleText = title
        self.descriptionText = description
        self.tags = tags
        self.storage = storage
        self.localization = localization
        self.accessibility = accessibility
    }

    public var title: String { titleText.resolve() }
    public var description: String { descriptionText.resolve() }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case titleText = "title"
        case descriptionText = "description"
        case tags
        case storage
        case localization
        case accessibility
    }
}

/// Aggregated progress metadata used by analytics dashboards and caregiver
/// reporting. The content provider computes these values dynamically based on
/// the lessons available to a given grade band.
public struct GradeProgressMetadata: Codable, Hashable {
    public var grade: Grade
    public var catalogVersion: CurriculumVersion
    public var totalStrands: Int
    public var totalSkills: Int
    public var totalLessons: Int
    public var variants: [Lesson.Variant: Int]
}
