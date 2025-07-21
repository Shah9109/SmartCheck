import SwiftUI

// MARK: - Animated Button
struct AnimatedButton: View {
    let title: String
    let icon: String?
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        backgroundColor: Color = AppColors.primary,
        foregroundColor: Color = .white,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(AppTypography.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AppAnimations.spring, value: isPressed)
        }
        .pressEvents {
            withAnimation { isPressed = true }
        } onRelease: {
            withAnimation { isPressed = false }
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let backgroundColor: Color
    let size: CGFloat
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        icon: String,
        backgroundColor: Color = AppColors.primary,
        size: CGFloat = 56,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(backgroundColor)
                        .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(AppAnimations.spring, value: isPressed)
        }
        .pressEvents {
            withAnimation { isPressed = true }
        } onRelease: {
            withAnimation { isPressed = false }
        }
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let title: String
    let placeholder: String
    let icon: String?
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var isFocused = false
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                    }
                }
                .font(AppTypography.body)
                .foregroundColor(.white)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.5))
                }
                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { _ in
                    isFocused = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)) { _ in
                    isFocused = false
                }
                
                if isSecure {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .stroke(
                        isFocused ? AppColors.primary : Color.white.opacity(0.3),
                        lineWidth: isFocused ? 2 : 1
                    )
                    .animation(AppAnimations.easeInOut, value: isFocused)
            )
        }
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let blur: CGFloat
    
    init(
        cornerRadius: CGFloat = 16,
        blur: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.blur = blur
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .backdrop(blur: blur)
            )
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let status: AttendanceStatus
    
    var body: some View {
        Text(text)
            .font(AppTypography.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return AppColors.warning
        case .approved:
            return AppColors.success
        case .rejected:
            return AppColors.error
        case .checkedIn:
            return AppColors.info
        case .checkedOut:
            return AppColors.secondary
        }
    }
}

// MARK: - Loading Indicator
struct LoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.7)
            .stroke(AppColors.primary, lineWidth: 3)
            .frame(width: 24, height: 24)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Attendance Method Button
struct AttendanceMethodButton: View {
    let method: AttendanceMethod
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            action()
        }) {
            VStack(spacing: 12) {
                Image(systemName: method.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
                
                Text(method.displayName)
                    .font(AppTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isEnabled ? .white : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? AppColors.glassPrimary : AppColors.glassSecondary)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(AppAnimations.spring, value: isPressed)
            .disabled(!isEnabled)
        }
        .pressEvents {
            withAnimation { isPressed = true }
        } onRelease: {
            withAnimation { isPressed = false }
        }
    }
}

// MARK: - Attendance Card
struct AttendanceCard: View {
    let attendance: Attendance
    let onTap: (() -> Void)?
    
    init(attendance: Attendance, onTap: (() -> Void)? = nil) {
        self.attendance = attendance
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attendance.userName)
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                        
                        if let department = attendance.department {
                            Text(department)
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    StatusBadge(text: attendance.status.displayName, status: attendance.status)
                }
                
                HStack {
                    Image(systemName: attendance.method.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(attendance.method.displayName)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(attendance.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.glassPrimary)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Chart Bar
struct ChartBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let label: String
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(height: 120)
                
                Rectangle()
                    .fill(color)
                    .frame(height: CGFloat(animatedValue / maxValue) * 120)
                    .animation(AppAnimations.spring.delay(0.1), value: animatedValue)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .onAppear {
            withAnimation {
                animatedValue = value
            }
        }
    }
}

// MARK: - Helper Extensions
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
    
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: {})
    }
}

// MARK: - Preview Helpers
struct ReusableComponents_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                AnimatedButton(
                    title: "Check In",
                    icon: "checkmark.circle",
                    backgroundColor: AppColors.success
                ) {
                    print("Check In tapped")
                }
                
                FloatingActionButton(icon: "plus") {
                    print("FAB tapped")
                }
                
                CustomTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    icon: "envelope",
                    text: .constant("")
                )
                
                AttendanceCard(attendance: Attendance.mock)
            }
            .padding()
        }
    }
} 