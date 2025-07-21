//
//  SmartCheckApp.swift
//  SmartCheck
//
//  Created by Sanjay Shah on 13/07/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up services
        setupServices()
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    private func setupServices() {
        // Initialize services
        _ = AuthService.shared
        _ = AttendanceService.shared
        _ = QRService.shared
        _ = LocationService.shared
        _ = NotificationService.shared
        _ = FaceRecognitionService.shared
        
        // Setup location monitoring
        LocationService.shared.requestLocationPermission()
        
        // Setup notification handling
        NotificationService.shared.requestNotificationPermission()
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle device token for push notifications
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
}

// MARK: - Main App
@main
struct SmartCheckApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var attendanceService = AttendanceService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var qrService = QRService.shared
    @StateObject private var faceService = FaceRecognitionService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(attendanceService)
                .environmentObject(notificationService)
                .environmentObject(locationService)
                .environmentObject(qrService)
                .environmentObject(faceService)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupAppearance()
                }
        }
    }
    
    private func setupAppearance() {
        // Customize navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Customize tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Attendance Tab
            AttendanceView()
                .tabItem {
                    Label("Attendance", systemImage: "calendar")
                }
                .tag(1)
            
            // QR Scanner Tab (Center)
            QRScannerView()
                .tabItem {
                    Label("Scan", systemImage: "qrcode.viewfinder")
                }
                .tag(2)
            
            // Admin Tab (if admin user)
            if authService.hasAdminAccess() {
                AdminView()
                    .tabItem {
                        Label("Admin", systemImage: "person.badge.key")
                    }
                    .tag(3)
            }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(authService.hasAdminAccess() ? 4 : 3)
        }
        .accentColor(AppColors.primary)
        .background(AppColors.backgroundGradient.ignoresSafeArea())
    }
}

// MARK: - Placeholder Views (will be implemented later)
struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var attendanceService: AttendanceService
    @State private var showingAttendanceOptions = false
    @State private var showingQRScanner = false
    @State private var showingFaceRecognition = false
    @State private var showingLocationAttendance = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Welcome Header
                        VStack(spacing: 8) {
                            Text("Welcome back,")
                                .font(AppTypography.title2)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(authService.currentUser?.displayName ?? "User")
                                .font(AppTypography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        // Quick Actions
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Quick Actions")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                    AttendanceMethodButton(
                                        method: .qr,
                                        isEnabled: true
                                    ) {
                                        showingQRScanner = true
                                    }
                                    
                                    AttendanceMethodButton(
                                        method: .face,
                                        isEnabled: true
                                    ) {
                                        showingFaceRecognition = true
                                    }
                                    
                                    AttendanceMethodButton(
                                        method: .location,
                                        isEnabled: true
                                    ) {
                                        showingLocationAttendance = true
                                    }
                                    
                                    AttendanceMethodButton(
                                        method: .manual,
                                        isEnabled: authService.hasAdminAccess()
                                    ) {
                                        showingAttendanceOptions = true
                                    }
                                }
                            }
                        }
                        
                        // Today's Attendance
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Today's Attendance")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if attendanceService.todayAttendance.isEmpty {
                                    Text("No attendance records for today")
                                        .font(AppTypography.body)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding()
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(attendanceService.todayAttendance.prefix(5)) { attendance in
                                            AttendanceCard(attendance: attendance)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAttendanceOptions) {
            AttendanceOptionsSheet()
        }
        .sheet(isPresented: $showingQRScanner) {
            QRCodeScannerView()
                .environmentObject(QRService.shared)
                .environmentObject(AttendanceService.shared)
        }
        .sheet(isPresented: $showingFaceRecognition) {
            FaceRecognitionView()
                .environmentObject(FaceRecognitionService.shared)
                .environmentObject(AttendanceService.shared)
        }
        .sheet(isPresented: $showingLocationAttendance) {
            LocationAttendanceView()
                .environmentObject(LocationService.shared)
                .environmentObject(AttendanceService.shared)
        }
    }
}

struct AttendanceView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                Text("Attendance View")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(.white)
            }
            .navigationTitle("Attendance")
        }
    }
}

struct QRScannerView: View {
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white)
                    
                    Text("QR Scanner")
                        .font(AppTypography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Scan QR codes for quick attendance")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    AnimatedButton(
                        title: "Open QR Scanner",
                        icon: "qrcode.viewfinder",
                        backgroundColor: AppColors.primary
                    ) {
                        showingScanner = true
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("QR Scanner")
        }
        .sheet(isPresented: $showingScanner) {
            QRCodeScannerView()
                .environmentObject(QRService.shared)
                .environmentObject(AttendanceService.shared)
        }
    }
}

struct AdminView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                Text("Admin View")
                    .font(AppTypography.largeTitle)
                    .foregroundColor(.white)
            }
            .navigationTitle("Admin")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: authService.currentUser?.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        Text(authService.currentUser?.displayName ?? "User")
                            .font(AppTypography.title1)
                            .foregroundColor(.white)
                        
                        Text(authService.currentUser?.email ?? "")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    
                    // Sign Out Button
                    AnimatedButton(
                        title: "Sign Out",
                        icon: "arrow.right.square",
                        backgroundColor: AppColors.error
                    ) {
                        do {
                            try authService.signOut()
                        } catch {
                            print("Sign out error: \(error)")
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Attendance Options Sheet
struct AttendanceOptionsSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingQRScanner = false
    @State private var showingFaceRecognition = false
    @State private var showingLocationAttendance = false
    @State private var showingBiometricAuth = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Choose Attendance Method")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        AttendanceMethodButton(method: .qr, isEnabled: true) {
                            showingQRScanner = true
                        }
                        
                        AttendanceMethodButton(method: .face, isEnabled: true) {
                            showingFaceRecognition = true
                        }
                        
                        AttendanceMethodButton(method: .location, isEnabled: true) {
                            showingLocationAttendance = true
                        }
                        
                        AttendanceMethodButton(method: .biometric, isEnabled: true) {
                            showingBiometricAuth = true
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingQRScanner) {
            QRCodeScannerView()
                .environmentObject(QRService.shared)
                .environmentObject(AttendanceService.shared)
        }
        .sheet(isPresented: $showingFaceRecognition) {
            FaceRecognitionView()
                .environmentObject(FaceRecognitionService.shared)
                .environmentObject(AttendanceService.shared)
        }
        .sheet(isPresented: $showingLocationAttendance) {
            LocationAttendanceView()
                .environmentObject(LocationService.shared)
                .environmentObject(AttendanceService.shared)
        }
        .alert("Biometric Authentication", isPresented: $showingBiometricAuth) {
            Button("Cancel", role: .cancel) { }
            Button("Authenticate") {
                performBiometricAuth()
            }
        } message: {
            Text("Use biometric authentication to check in?")
        }
    }
    
    private func performBiometricAuth() {
        Task {
            do {
                let success = try await AuthService.shared.authenticateWithBiometrics()
                if success {
                    try await AttendanceService.shared.checkIn(
                        method: .biometric,
                        notes: "Biometric authentication successful"
                    )
                    HapticFeedback.notification(.success)
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                HapticFeedback.notification(.error)
                print("Biometric authentication error: \(error)")
            }
        }
    }
}
