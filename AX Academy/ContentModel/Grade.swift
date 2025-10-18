import Foundation

/// Represents supported grade levels in the app.  Additional cases can be
/// appended in future to add new curriculum without breaking existing
/// consumers.  Using raw `String` values provides stable identifiers for
/// analytics and persistence.
public enum Grade: String, CaseIterable, Codable, Identifiable {
    case kindergarten = "kindergarten"
    case grade1 = "grade1"

    public var id: String { rawValue }

    /// A localized display name used in the UI.  Provide localized strings
    /// here instead of directly embedding them in the view layer.
    public var displayName: String {
        switch self {
        case .kindergarten:
            return NSLocalizedString("grade_kindergarten", comment: "Kindergarten grade label")
        case .grade1:
            return NSLocalizedString("grade_1", comment: "Grade 1 label")
        }
    }
}
