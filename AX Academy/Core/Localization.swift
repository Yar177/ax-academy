import Foundation
import SwiftUI

/// Convenience helper for localized strings used across SwiftUI views.  This
/// keeps string keys in one place and avoids scattering raw literals.
public enum L10n {
    public static func text(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
