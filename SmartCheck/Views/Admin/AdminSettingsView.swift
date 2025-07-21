import SwiftUI

struct AdminSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab = 0
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    AdminSettingsHeader()
                        .padding()
                    
                    // Tab Selector
                    SettingsTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        GeneralSettingsView()
                            .tag(0)
                        
                        SecuritySettingsView()
                            .tag(1)
                        
                        SystemSettingsView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Admin Settings Header
struct AdminSettingsHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Admin Settings")
                        .font(AppTypography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Configure system settings and preferences")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Settings Tab Selector
struct SettingsTabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        ("General", "gear"),
        ("Security", "shield"),
        ("System", "cpu")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tabs[index].1)
                            .font(.system(size: 20, weight: .medium))
                        
                        Text(tabs[index].0)
                            .font(AppTypography.caption)
                    }
                    .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(selectedTab == index ? Color.white.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - General Settings View
struct GeneralSettingsView: View {
    @State private var attendanceReminderEnabled = true
    @State private var requireLocationForAttendance = false
    @State private var allowMultipleCheckInsPerDay = false
    @State private var automaticCheckOut = true
    @State private var checkOutTime = Date()
    @State private var notificationSettings = NotificationSettings()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Attendance Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Attendance Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsToggle(
                                title: "Attendance Reminders",
                                description: "Send reminders for attendance",
                                isOn: $attendanceReminderEnabled
                            )
                            
                            SettingsToggle(
                                title: "Require Location",
                                description: "Require location for attendance",
                                isOn: $requireLocationForAttendance
                            )
                            
                            SettingsToggle(
                                title: "Multiple Check-ins",
                                description: "Allow multiple check-ins per day",
                                isOn: $allowMultipleCheckInsPerDay
                            )
                            
                            SettingsToggle(
                                title: "Automatic Check-out",
                                description: "Automatically check out users",
                                isOn: $automaticCheckOut
                            )
                            
                            if automaticCheckOut {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Check-out Time")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    DatePicker("", selection: $checkOutTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .colorScheme(.dark)
                                }
                            }
                        }
                    }
                }
                
                // Notification Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Notification Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsToggle(
                                title: "Push Notifications",
                                description: "Enable push notifications",
                                isOn: $notificationSettings.pushEnabled
                            )
                            
                            SettingsToggle(
                                title: "Email Notifications",
                                description: "Send notifications via email",
                                isOn: $notificationSettings.emailEnabled
                            )
                            
                            SettingsToggle(
                                title: "Late Arrival Alerts",
                                description: "Alert for late arrivals",
                                isOn: $notificationSettings.lateArrivalAlerts
                            )
                            
                            SettingsToggle(
                                title: "Weekly Reports",
                                description: "Send weekly attendance reports",
                                isOn: $notificationSettings.weeklyReports
                            )
                        }
                    }
                }
                
                // Application Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Application Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsRow(
                                title: "App Version",
                                value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
                            )
                            
                            SettingsRow(
                                title: "Build Number",
                                value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
                            )
                            
                            SettingsRow(
                                title: "Database Version",
                                value: "2.1.0"
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Security Settings View
struct SecuritySettingsView: View {
    @State private var requireBiometricAuth = true
    @State private var sessionTimeout = 30.0
    @State private var twoFactorEnabled = false
    @State private var passwordStrengthRequired = true
    @State private var allowRememberMe = false
    @State private var lockAppAfterInactivity = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Authentication Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Authentication Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsToggle(
                                title: "Biometric Authentication",
                                description: "Require Face ID or Touch ID",
                                isOn: $requireBiometricAuth
                            )
                            
                            SettingsToggle(
                                title: "Two-Factor Authentication",
                                description: "Enable 2FA for additional security",
                                isOn: $twoFactorEnabled
                            )
                            
                            SettingsToggle(
                                title: "Strong Password Required",
                                description: "Enforce strong password policy",
                                isOn: $passwordStrengthRequired
                            )
                            
                            SettingsToggle(
                                title: "Remember Me",
                                description: "Allow users to stay logged in",
                                isOn: $allowRememberMe
                            )
                            
                            SettingsToggle(
                                title: "Auto-lock",
                                description: "Lock app after inactivity",
                                isOn: $lockAppAfterInactivity
                            )
                        }
                    }
                }
                
                // Session Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Session Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session Timeout: \(Int(sessionTimeout)) minutes")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Slider(value: $sessionTimeout, in: 15...120, step: 15)
                                    .accentColor(AppColors.primary)
                                
                                HStack {
                                    Text("15 min")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("120 min")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                }
                
                // Privacy Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Privacy Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsButton(
                                title: "Privacy Policy",
                                icon: "doc.text",
                                action: { }
                            )
                            
                            SettingsButton(
                                title: "Terms of Service",
                                icon: "doc.text",
                                action: { }
                            )
                            
                            SettingsButton(
                                title: "Data Usage",
                                icon: "chart.bar",
                                action: { }
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - System Settings View
struct SystemSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var enableLogging = true
    @State private var logLevel = "Info"
    @State private var enableCrashReporting = true
    @State private var enableAnalytics = false
    @State private var showingClearDataConfirmation = false
    @State private var showingLogoutConfirmation = false
    
    private let logLevels = ["Debug", "Info", "Warning", "Error"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Debug Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Debug Settings")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsToggle(
                                title: "Enable Logging",
                                description: "Enable application logging",
                                isOn: $enableLogging
                            )
                            
                            if enableLogging {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Log Level")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Menu {
                                        ForEach(logLevels, id: \.self) { level in
                                            Button(level) {
                                                logLevel = level
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(logLevel)
                                                .font(AppTypography.body)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.1))
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            
                            SettingsToggle(
                                title: "Crash Reporting",
                                description: "Send crash reports to improve app",
                                isOn: $enableCrashReporting
                            )
                            
                            SettingsToggle(
                                title: "Analytics",
                                description: "Anonymous usage analytics",
                                isOn: $enableAnalytics
                            )
                        }
                    }
                }
                
                // Maintenance Settings
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Maintenance")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsButton(
                                title: "Clear Cache",
                                icon: "trash",
                                action: { }
                            )
                            
                            SettingsButton(
                                title: "Export Logs",
                                icon: "square.and.arrow.up",
                                action: { }
                            )
                            
                            SettingsButton(
                                title: "Reset Settings",
                                icon: "arrow.clockwise",
                                action: { }
                            )
                        }
                    }
                }
                
                // Account Actions
                GlassCard {
                    VStack(spacing: 16) {
                        Text("Account Actions")
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            SettingsButton(
                                title: "Change Password",
                                icon: "key",
                                action: { }
                            )
                            
                            SettingsButton(
                                title: "Clear All Data",
                                icon: "trash.fill",
                                action: {
                                    showingClearDataConfirmation = true
                                }
                            )
                            
                            SettingsButton(
                                title: "Sign Out",
                                icon: "arrow.right.square",
                                action: {
                                    showingLogoutConfirmation = true
                                }
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .alert("Clear All Data", isPresented: $showingClearDataConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear Data", role: .destructive) {
                // Handle clear data
            }
        } message: {
            Text("This will permanently delete all attendance data. This action cannot be undone.")
        }
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Supporting Views
struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
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
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(value)
                    .font(AppTypography.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 20)
                    
                    Text(title)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationSettings {
    var pushEnabled = true
    var emailEnabled = false
    var lateArrivalAlerts = true
    var weeklyReports = true
}

// MARK: - Preview
struct AdminSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AdminSettingsView()
            .environmentObject(AuthService.shared)
    }
} 