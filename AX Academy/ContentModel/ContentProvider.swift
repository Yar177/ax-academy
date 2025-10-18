import Foundation

/// Abstraction for retrieving structured curriculum data. Providers expose
/// version metadata for analytics, strands for navigation, and aggregated
/// progress information for dashboards.
public protocol ContentProviding {
    var catalogVersion: CurriculumVersion { get }
    var catalogMetadata: CurriculumCatalog.Metadata { get }
    func lessons(for grade: Grade) -> [Lesson]
    func strands(for grade: Grade) -> [LearningStrand]
    func progressMetadata(for grade: Grade) -> GradeProgressMetadata
}

/// Loads curriculum data from a bundled JSON file. The provider keeps an
/// in-memory cache of lessons and strands grouped by grade so requests remain
/// fast even on lower-powered iPads. The same schema can be hydrated from a
/// cloud endpoint by pointing this provider at a remote URL in the future.
public final class BundledJSONContentProvider: ContentProviding {
    public private(set) var catalogVersion: CurriculumVersion
    public private(set) var catalogMetadata: CurriculumCatalog.Metadata

    private let catalog: CurriculumCatalog
    private let lessonsByGrade: [Grade: [Lesson]]
    private let strandsByGrade: [Grade: [LearningStrand]]

    public init(bundle: Bundle = .main,
                resource: String = "curriculum_v1",
                fileExtension: String = "json") {
        let decoder = BundledJSONContentProvider.makeDecoder()
        let catalog = BundledJSONContentProvider.loadCatalog(
            bundle: bundle,
            resource: resource,
            fileExtension: fileExtension,
            decoder: decoder
        )
        self.catalog = catalog
        self.catalogVersion = catalog.metadata.version
        self.catalogMetadata = catalog.metadata
        self.lessonsByGrade = Dictionary(grouping: catalog.lessons, by: { $0.grade })
        self.strandsByGrade = Dictionary(grouping: catalog.strands, by: { $0.grade })
    }

    // MARK: - ContentProviding

    public func lessons(for grade: Grade) -> [Lesson] {
        lessonsByGrade[grade] ?? []
    }

    public func strands(for grade: Grade) -> [LearningStrand] {
        strandsByGrade[grade] ?? []
    }

    public func progressMetadata(for grade: Grade) -> GradeProgressMetadata {
        let gradeLessons = lessons(for: grade)
        let strandCount = (strandsByGrade[grade] ?? []).count
        let uniqueSkillCount = Set(gradeLessons.flatMap { $0.skillIDs }).count
        var variantCounts: [Lesson.Variant: Int] = Dictionary(uniqueKeysWithValues: Lesson.Variant.allCases.map { ($0, 0) })
        for lesson in gradeLessons {
            variantCounts[lesson.variant, default: 0] += 1
        }
        return GradeProgressMetadata(
            grade: grade,
            catalogVersion: catalogVersion,
            totalStrands: strandCount,
            totalSkills: uniqueSkillCount,
            totalLessons: gradeLessons.count,
            variants: variantCounts
        )
    }

    // MARK: - Private helpers

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private static func loadCatalog(bundle: Bundle,
                                    resource: String,
                                    fileExtension: String,
                                    decoder: JSONDecoder) -> CurriculumCatalog {
        guard let url = locateResource(bundle: bundle, resource: resource, fileExtension: fileExtension) else {
            assertionFailure("Unable to locate curriculum catalog resource \(resource).\(fileExtension)")
            return .empty
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(CurriculumCatalog.self, from: data)
        } catch {
            assertionFailure("Failed to decode curriculum catalog: \(error)")
            return .empty
        }
    }

    private static func locateResource(bundle: Bundle,
                                        resource: String,
                                        fileExtension: String) -> URL? {
        if let url = bundle.url(forResource: resource, withExtension: fileExtension) {
            return url
        }
        let tokenBundle = Bundle(for: BundleToken.self)
        if let url = tokenBundle.url(forResource: resource, withExtension: fileExtension) {
            return url
        }
        let fileManager = FileManager.default
        let searchPaths = [
            "AX Academy/ContentModel/Data",
            "ContentModel/Data",
            "Data"
        ]
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        for path in searchPaths {
            let url = currentDirectory.appendingPathComponent(path).appendingPathComponent("\(resource).\(fileExtension)")
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    private final class BundleToken {}
}
