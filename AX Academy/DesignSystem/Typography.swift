import SwiftUI

/// A namespace for reusable typography styles.  Text styles defined here
/// leverage system fonts with explicit text styles so that they scale
/// automatically with Dynamic Type【864001179352877†L287-L316】.  When using custom
/// fonts, the `relativeTo` parameter ensures the type scales relative to the
/// specified style【864001179352877†L369-L386】.
public enum DSTypography {
    /// Large title style for screen headings.
    public static func largeTitle() -> Font {
        Font.system(.largeTitle, design: .rounded)
    }
    /// Title style for section headers.
    public static func title() -> Font {
        Font.system(.title, design: .rounded)
    }
    /// Body style for general text.
    public static func body() -> Font {
        Font.system(.body, design: .rounded)
    }
    /// Caption style for supplementary text.
    public static func caption() -> Font {
        Font.system(.caption, design: .rounded)
    }
}