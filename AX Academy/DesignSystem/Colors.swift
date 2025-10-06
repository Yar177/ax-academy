import SwiftUI

/// A namespace for design system colours.  System colours are used because
/// they automatically adapt to Dark Mode and accessibility settings such as
/// Increase Contrast【853089050035204†L138-L167】.  Custom colours are defined via
/// the asset catalog when necessary and can be referenced here as well.
public enum DSColor {
    /// Primary foreground colour used for text and icons.  Uses the system
    /// `primary` colour to respect user settings like Dark Mode and high
    /// contrast【853089050035204†L152-L160】.
    public static let primaryText = Color.primary
    /// Secondary foreground colour used for less prominent text.
    public static let secondaryText = Color.secondary
    /// The main accent colour used for interactive elements like buttons.
    public static let accent = Color.accentColor
    /// Background colour for cards and panels.  Uses secondary system
    /// background to differentiate from the main background.
    public static let cardBackground = Color(UIColor.secondarySystemBackground)
    /// Background colour for the overall app.  Follows system grouped
    /// backgrounds to adapt to the environment.
    public static let background = Color(UIColor.systemGroupedBackground)
}