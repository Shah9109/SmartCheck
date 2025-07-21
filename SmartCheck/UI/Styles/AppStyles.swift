import SwiftUI

// MARK: - App Colors
struct AppColors {
    static let primary = Color(hex: "#007AFF")
    static let secondary = Color(hex: "#5856D6")
    static let accent = Color(hex: "#FF9500")
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
    static let error = Color(hex: "#FF3B30")
    static let info = Color(hex: "#007AFF")
    
    // Glassmorphism colors
    static let glassPrimary = Color.white.opacity(0.1)
    static let glassSecondary = Color.white.opacity(0.05)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Neumorphism colors
    static let neuLight = Color(hex: "#FFFFFF")
    static let neuDark = Color(hex: "#E6E6E6")
    static let neuShadowLight = Color.white.opacity(0.7)
    static let neuShadowDark = Color.black.opacity(0.3)
    
    // Background gradients
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(hex: "#667eea"),
            Color(hex: "#764ba2")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - App Typography
struct AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 20, weight: .medium, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .medium, design: .default)
    static let subheadline = Font.system(size: 15, weight: .medium, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let caption2 = Font.system(size: 11, weight: .medium, design: .default)
}

// MARK: - Glassmorphism Style
struct GlassmorphismStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var blur: CGFloat = 20
    var opacity: Double = 0.1
    var borderOpacity: Double = 0.2
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(opacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(borderOpacity), lineWidth: 1)
                    )
                    .backdrop(blur: blur)
            )
    }
}

// MARK: - Neumorphism Style
struct NeumorphismStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.neuLight)
                    .shadow(
                        color: isPressed ? AppColors.neuShadowDark : AppColors.neuShadowLight,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? 1 : -5,
                        y: isPressed ? 1 : -5
                    )
                    .shadow(
                        color: isPressed ? AppColors.neuShadowLight : AppColors.neuShadowDark,
                        radius: isPressed ? 2 : 8,
                        x: isPressed ? -1 : 5,
                        y: isPressed ? -1 : 5
                    )
            )
    }
}

// MARK: - Card Style
struct CardStyle: ViewModifier {
    var backgroundColor: Color = Color.white.opacity(0.1)
    var cornerRadius: CGFloat = 16
    var shadowColor: Color = Color.black.opacity(0.1)
    var shadowRadius: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 5)
            )
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppColors.primary
    var foregroundColor: Color = .white
    var cornerRadius: CGFloat = 12
    var scaleEffect: CGFloat = 0.95
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            )
            .scaleEffect(configuration.isPressed ? scaleEffect : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ButtonStyle {
    var backgroundColor: Color = AppColors.primary
    var size: CGFloat = 56
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Input Field Style
struct InputFieldStyle: ViewModifier {
    var backgroundColor: Color = Color.white.opacity(0.1)
    var borderColor: Color = Color.white.opacity(0.3)
    var cornerRadius: CGFloat = 12
    var isFocused: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTypography.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .stroke(
                        isFocused ? AppColors.primary : borderColor,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Badge Style
struct BadgeStyle: ViewModifier {
    var backgroundColor: Color = AppColors.primary
    var textColor: Color = .white
    var cornerRadius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .font(AppTypography.caption)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
    }
}

// MARK: - View Extensions
extension View {
    func glassmorphism(
        cornerRadius: CGFloat = 16,
        blur: CGFloat = 20,
        opacity: Double = 0.1,
        borderOpacity: Double = 0.2
    ) -> some View {
        self.modifier(GlassmorphismStyle(
            cornerRadius: cornerRadius,
            blur: blur,
            opacity: opacity,
            borderOpacity: borderOpacity
        ))
    }
    
    func neumorphism(
        cornerRadius: CGFloat = 16,
        isPressed: Bool = false
    ) -> some View {
        self.modifier(NeumorphismStyle(
            cornerRadius: cornerRadius,
            isPressed: isPressed
        ))
    }
    
    func cardStyle(
        backgroundColor: Color = Color.white.opacity(0.1),
        cornerRadius: CGFloat = 16,
        shadowColor: Color = Color.black.opacity(0.1),
        shadowRadius: CGFloat = 10
    ) -> some View {
        self.modifier(CardStyle(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            shadowColor: shadowColor,
            shadowRadius: shadowRadius
        ))
    }
    
    func inputFieldStyle(
        backgroundColor: Color = Color.white.opacity(0.1),
        borderColor: Color = Color.white.opacity(0.3),
        cornerRadius: CGFloat = 12,
        isFocused: Bool = false
    ) -> some View {
        self.modifier(InputFieldStyle(
            backgroundColor: backgroundColor,
            borderColor: borderColor,
            cornerRadius: cornerRadius,
            isFocused: isFocused
        ))
    }
    
    func badgeStyle(
        backgroundColor: Color = AppColors.primary,
        textColor: Color = .white,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self.modifier(BadgeStyle(
            backgroundColor: backgroundColor,
            textColor: textColor,
            cornerRadius: cornerRadius
        ))
    }
    
    func backdrop(blur: CGFloat = 20) -> some View {
        self.background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: blur)
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animation Presets
struct AppAnimations {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.5)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 30)
    static let smooth = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.5)
} 