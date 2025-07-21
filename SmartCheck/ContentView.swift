//
//  ContentView.swift
//  SmartCheck
//
//  Created by Sanjay Shah on 13/07/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var attendanceService: AttendanceService
    @EnvironmentObject var qrService: QRService
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var faceRecognitionService: FaceRecognitionService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
                    .environmentObject(authService)
                    .environmentObject(attendanceService)
                    .environmentObject(qrService)
                    .environmentObject(locationService)
                    .environmentObject(notificationService)
                    .environmentObject(faceRecognitionService)
            } else {
                AuthenticationView()
                    .environmentObject(authService)
                    .environmentObject(attendanceService)
                    .environmentObject(qrService)
                    .environmentObject(locationService)
                    .environmentObject(notificationService)
                    .environmentObject(faceRecognitionService)
            }
        }
        .onAppear {
            // Initialize services
            authService.initialize()
            attendanceService.initialize()
            qrService.initialize()
            locationService.initialize()
            notificationService.initialize()
            faceRecognitionService.initialize()
        }
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
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Attendance Tab
            AttendanceTabView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Attendance")
                }
                .tag(1)
            
            // Admin Tab (only for admin/manager roles)
            if authService.currentUser?.role == .admin || authService.currentUser?.role == .manager {
                AdminDashboardView()
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Admin")
                    }
                    .tag(2)
            }
            
            // Profile Tab
            ProfileManagementView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(AppColors.primary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Attendance Tab View
struct AttendanceTabView: View {
    @State private var selectedMethod = 0
    
    var body: some View {
        TabView(selection: $selectedMethod) {
            QRCodeScannerView()
                .tabItem {
                    Image(systemName: "qrcode")
                    Text("QR Code")
                }
                .tag(0)
            
            FaceRecognitionView()
                .tabItem {
                    Image(systemName: "face.smiling")
                    Text("Face ID")
                }
                .tag(1)
            
            LocationAttendanceView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Location")
                }
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var attendanceService: AttendanceService
    @State private var todayAttendance: [Attendance] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Section
                        WelcomeSection()
                        
                        // Quick Actions
                        QuickActionsSection()
                        
                        // Today's Attendance
                        TodayAttendanceSection(attendanceRecords: todayAttendance)
                        
                        // Recent Activity
                        RecentActivitySection()
                    }
                    .padding()
                }
            }
            .navigationTitle("SmartCheck")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadTodayAttendance()
        }
    }
    
    private func loadTodayAttendance() {
        isLoading = true
        Task {
            do {
                let records = try await attendanceService.fetchTodayAttendance()
                await MainActor.run {
                    todayAttendance = records
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error loading today's attendance: \(error)")
            }
        }
    }
}

// MARK: - Welcome Section
struct WelcomeSection: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back,")
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(authService.currentUser?.displayName ?? "User")
                        .font(AppTypography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Ready to track your attendance?")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
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
            }
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(AppTypography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionCard(
                    title: "QR Check-in",
                    icon: "qrcode",
                    color: AppColors.primary,
                    destination: QRCodeScannerView()
                )
                
                QuickActionCard(
                    title: "Face Check-in",
                    icon: "face.smiling",
                    color: AppColors.secondary,
                    destination: FaceRecognitionView()
                )
                
                QuickActionCard(
                    title: "Location",
                    icon: "location.fill",
                    color: AppColors.success,
                    destination: LocationAttendanceView()
                )
                
                QuickActionCard(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    color: AppColors.info,
                    destination: ProfileManagementView()
                )
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            GlassCard {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Today's Attendance Section
struct TodayAttendanceSection: View {
    let attendanceRecords: [Attendance]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Attendance")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(attendanceRecords.count) records")
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if attendanceRecords.isEmpty {
                GlassCard {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("No attendance records today")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(attendanceRecords.prefix(3)) { record in
                        AttendanceRecordRow(record: record)
                    }
                }
            }
        }
    }
}

// MARK: - Attendance Record Row
struct AttendanceRecordRow: View {
    let record: Attendance
    
    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.method.displayName)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white)
                    
                    Text(record.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                StatusBadge(text: record.status.displayName, status: record.status)
            }
        }
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Recent Activity")
                .font(AppTypography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GlassCard {
                VStack(spacing: 12) {
                    ActivityItem(
                        icon: "checkmark.circle.fill",
                        title: "Check-in successful",
                        time: "9:00 AM",
                        color: AppColors.success
                    )
                    
                    ActivityItem(
                        icon: "location.fill",
                        title: "Location verified",
                        time: "9:01 AM",
                        color: AppColors.info
                    )
                    
                    ActivityItem(
                        icon: "face.smiling",
                        title: "Face recognition completed",
                        time: "9:02 AM",
                        color: AppColors.secondary
                    )
                }
            }
        }
    }
}

// MARK: - Activity Item
struct ActivityItem: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundColor(.white)
                
                Text(time)
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(AttendanceService.shared)
        .environmentObject(QRService.shared)
        .environmentObject(LocationService.shared)
        .environmentObject(NotificationService.shared)
        .environmentObject(FaceRecognitionService.shared)
}
