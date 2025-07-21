import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTheme = AppTheme.system
    @State private var selectedLanguage = "English"
    @State private var notificationsEnabled = true
    @State private var faceIDEnabled = true
    @State private var locationEnabled = true
    @State private var hapticFeedbackEnabled = true
    @State private var autoCheckout = false
    @State private var soundEnabled = true
    @State private var showingLogoutAlert = false
    @State private var showingLanguageSheet = false
    @State private var showingThemeSheet = false
    @State private var showingAbout = false
    
    private let languages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Japanese", "Korean", "Chinese"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Section
                        ProfileSectionView()
                        
                        // Appearance Settings
                        SettingsSection(title: "Appearance") {
                            SettingsRow(
                                title: "Theme",
                                value: selectedTheme.displayName,
                                icon: "paintbrush"
                            ) {
                                showingThemeSheet = true
                            }
                            
                            SettingsRow(
                                title: "Language",
                                value: selectedLanguage,
                                icon: "globe"
                            ) {
                                showingLanguageSheet = true
                            }
                        }
                        
                        // Notifications Settings
                        SettingsSection(title: "Notifications") {
                            SettingsToggleRow(
                                title: "Push Notifications",
                                description: "Receive attendance reminders and updates",
                                icon: "bell",
                                isOn: $notificationsEnabled
                            )
                            
                            SettingsToggleRow(
                                title: "Sound",
                                description: "Play sounds for notifications",
                                icon: "speaker.wave.2",
                                isOn: $soundEnabled
                            )
                            
                            SettingsToggleRow(
                                title: "Haptic Feedback",
                                description: "Feel vibrations for interactions",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: $hapticFeedbackEnabled
                            )
                        }
                        
                        // Privacy & Security
                        SettingsSection(title: "Privacy & Security") {
                            SettingsToggleRow(
                                title: "Face ID / Touch ID",
                                description: "Use biometric authentication",
                                icon: "faceid",
                                isOn: $faceIDEnabled
                            )
                            
                            SettingsToggleRow(
                                title: "Location Services",
                                description: "Allow location-based attendance",
                                icon: "location",
                                isOn: $locationEnabled
                            )
                            
                            SettingsRow(
                                title: "Privacy Policy",
                                value: "",
                                icon: "doc.text"
                            ) {
                                // Handle privacy policy
                            }
                        }
                        
                        // Attendance Settings
                        SettingsSection(title: "Attendance") {
                            SettingsToggleRow(
                                title: "Auto Check-out",
                                description: "Automatically check out at end of day",
                                icon: "clock.arrow.circlepath",
                                isOn: $autoCheckout
                            )
                            
                            SettingsRow(
                                title: "Attendance History",
                                value: "",
                                icon: "calendar"
                            ) {
                                // Handle attendance history
                            }
                            
                            SettingsRow(
                                title: "Export Data",
                                value: "",
                                icon: "square.and.arrow.up"
                            ) {
                                // Handle export data
                            }
                        }
                        
                        // About Section
                        SettingsSection(title: "About") {
                            SettingsRow(
                                title: "Version",
                                value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0",
                                icon: "info.circle"
                            ) {
                                showingAbout = true
                            }
                            
                            SettingsRow(
                                title: "Help & Support",
                                value: "",
                                icon: "questionmark.circle"
                            ) {
                                // Handle help & support
                            }
                            
                            SettingsRow(
                                title: "Terms of Service",
                                value: "",
                                icon: "doc.text"
                            ) {
                                // Handle terms of service
                            }
                        }
                        
                        // Sign Out Button
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("Sign Out")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.error)
                            )
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingThemeSheet) {
            ThemeSelectionView(selectedTheme: $selectedTheme)
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguageSelectionView(selectedLanguage: $selectedLanguage, languages: languages)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Profile Section View
struct ProfileSectionView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: authService.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.currentUser?.displayName ?? "User")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(authService.currentUser?.email ?? "")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let department = authService.currentUser?.department {
                        Text(department)
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    StatusBadge(
                        text: authService.currentUser?.role.displayName ?? "User",
                        status: .approved
                    )
                }
                
                Spacer()
                
                NavigationLink(destination: ProfileManagementView()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                Text(title)
                    .font(AppTypography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let value: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
        }
        .padding(.vertical, 8)
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @Binding var selectedTheme: AppTheme
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeOption(
                            theme: theme,
                            isSelected: selectedTheme == theme
                        ) {
                            selectedTheme = theme
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Theme")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Theme Option
struct ThemeOption: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            GlassCard {
                HStack {
                    Image(systemName: theme.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? AppColors.primary : .white.opacity(0.8))
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.displayName)
                            .font(AppTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(themeDescription(for: theme))
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func themeDescription(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "Follow system appearance"
        case .light: return "Light mode"
        case .dark: return "Dark mode"
        }
    }
}

// MARK: - Language Selection View
struct LanguageSelectionView: View {
    @Binding var selectedLanguage: String
    let languages: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(languages, id: \.self) { language in
                            LanguageOption(
                                language: language,
                                isSelected: selectedLanguage == language
                            ) {
                                selectedLanguage = language
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Language")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Language Option
struct LanguageOption: View {
    let language: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            GlassCard {
                HStack {
                    Text(language)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon and Name
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(.white)
                            
                            Text("SmartCheck")
                                .font(AppTypography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // App Description
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("About SmartCheck")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("SmartCheck is a comprehensive attendance tracking application that uses modern technology including QR codes, face recognition, and location services to provide accurate and efficient attendance management.")
                                    .font(AppTypography.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        
                        // Features
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Features")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    FeatureRow(text: "QR Code Scanning")
                                    FeatureRow(text: "Face Recognition")
                                    FeatureRow(text: "Location-based Attendance")
                                    FeatureRow(text: "Biometric Authentication")
                                    FeatureRow(text: "Real-time Analytics")
                                    FeatureRow(text: "Data Export")
                                }
                            }
                        }
                        
                        // Developer Info
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Developer")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Developed with ❤️ using SwiftUI and Firebase")
                                    .font(AppTypography.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.success)
            
            Text(text)
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthService.shared)
    }
} 