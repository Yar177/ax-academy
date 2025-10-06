import Foundation

/// Represents supported grade levels in the app.  Additional cases can be
/// appended in future to add new curriculum without breaking existing
/// consumers.  Using raw `String` values provides stable identifiers for
/// analytics and persistence.
public enum Grade: String, CaseIterable, Codable {
    case kindergarten = "kindergarten"
    case grade1 = "grade1"

    /// A localized display name used in the UI.  Provide localized strings
    /// here instead of directly embedding them in the view layer.
    public var displayName: String {
        switch self {
        case .kindergarten:
            return "Kindergarten"
        case .grade1:
            return "Grade 1"
        }
    }
}