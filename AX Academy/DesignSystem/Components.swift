import SwiftUI

/// A button style for primary actions.  It uses the design system accent
/// colour for its background and ensures sufficient contrast by relying on
/// system foreground colours.  Rounded corners make the button approachable
/// for young children.  The style respects Dynamic Type sizes.
public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSTypography.title())
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(DSColor.accent)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// A button style for secondary actions.  Uses the card background with a
/// coloured border for a subtle appearance.
public struct SecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DSTypography.body())
            .foregroundColor(DSColor.accent)
            .padding()
            .frame(maxWidth: .infinity)
            .background(DSColor.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DSColor.accent, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// A reusable card view for displaying content such as questions and
/// explanations.  Cards have a subtle shadow and padded content area.
public struct CardView<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    public var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DSColor.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
}