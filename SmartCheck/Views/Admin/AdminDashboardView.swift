import SwiftUI
import Charts

struct AdminDashboardView: View {
    @EnvironmentObject var attendanceService: AttendanceService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var qrService: QRService
    @State private var selectedTab = 0
    @State private var showingUserManagement = false
    @State private var showingQRManagement = false
    @State private var showingDataExport = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    AdminHeaderView()
                        .padding()
                    
                    // Tab Selector
                    AdminTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        AnalyticsView()
                            .tag(0)
                        
                        PendingApprovalsView()
                            .tag(1)
                        
                        QuickActionsView(
                            showingUserManagement: $showingUserManagement,
                            showingQRManagement: $showingQRManagement,
                            showingDataExport: $showingDataExport,
                            showingSettings: $showingSettings
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingUserManagement) {
            UserManagementView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingQRManagement) {
            QRManagementView()
                .environmentObject(qrService)
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView()
                .environmentObject(attendanceService)
        }
        .sheet(isPresented: $showingSettings) {
            AdminSettingsView()
                .environmentObject(authService)
        }
    }
}

// MARK: - Admin Header
struct AdminHeaderView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Admin Dashboard")
                        .font(AppTypography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Welcome, \(authService.currentUser?.displayName ?? "Admin")")
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                AsyncImage(url: URL(string: authService.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            }
        }
    }
}

// MARK: - Admin Tab Selector
struct AdminTabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        ("Analytics", "chart.bar.fill"),
        ("Approvals", "checkmark.circle"),
        ("Actions", "gear")
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

// MARK: - Analytics View
struct AnalyticsView: View {
    @EnvironmentObject var attendanceService: AttendanceService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats Cards
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    if let analytics = attendanceService.analytics {
                        StatCard(
                            title: "Total Users",
                            value: "\(analytics.totalUsers)",
                            icon: "person.3.fill",
                            color: AppColors.primary
                        )
                        
                        StatCard(
                            title: "Active Today",
                            value: "\(analytics.activeUsers)",
                            icon: "person.circle.fill",
                            color: AppColors.success
                        )
                        
                        StatCard(
                            title: "Today's Attendance",
                            value: "\(analytics.todayAttendance)",
                            icon: "calendar",
                            color: AppColors.info
                        )
                        
                        StatCard(
                            title: "Late Arrivals",
                            value: "\(analytics.lateArrivals)",
                            icon: "clock.fill",
                            color: AppColors.warning
                        )
                    }
                }
                
                // Charts
                if let analytics = attendanceService.analytics {
                    GlassCard {
                        VStack(spacing: 16) {
                            Text("Department Breakdown")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                ForEach(Array(analytics.departmentStats.keys), id: \.self) { department in
                                    if let count = analytics.departmentStats[department] {
                                        ChartBar(
                                            value: Double(count),
                                            maxValue: Double(analytics.departmentStats.values.max() ?? 1),
                                            color: AppColors.primary,
                                            label: department
                                        )
                                    }
                                }
                            }
                        }
                    }
                    
                    GlassCard {
                        VStack(spacing: 16) {
                            Text("Attendance Methods")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                ForEach(Array(analytics.methodStats.keys), id: \.self) { method in
                                    if let count = analytics.methodStats[method] {
                                        ChartBar(
                                            value: Double(count),
                                            maxValue: Double(analytics.methodStats.values.max() ?? 1),
                                            color: AppColors.secondary,
                                            label: method.capitalized
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(AppTypography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Pending Approvals View
struct PendingApprovalsView: View {
    @EnvironmentObject var attendanceService: AttendanceService
    @State private var pendingAttendance: [Attendance] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    HStack(spacing: 12) {
                        LoadingIndicator()
                        Text("Loading pending approvals...")
                            .font(AppTypography.body)
                            .foregroundColor(.white)
                    }
                    .padding()
                } else if pendingAttendance.isEmpty {
                    GlassCard {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(AppColors.success)
                            
                            Text("All Caught Up!")
                                .font(AppTypography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("No pending attendance approvals")
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(pendingAttendance) { attendance in
                            PendingAttendanceCard(attendance: attendance) {
                                loadPendingAttendance()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadPendingAttendance()
        }
    }
    
    private func loadPendingAttendance() {
        isLoading = true
        Task {
            do {
                let pending = try await attendanceService.fetchPendingAttendance()
                await MainActor.run {
                    pendingAttendance = pending
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error loading pending attendance: \(error)")
            }
        }
    }
}

// MARK: - Pending Attendance Card
struct PendingAttendanceCard: View {
    let attendance: Attendance
    let onUpdate: () -> Void
    @State private var isProcessing = false
    @State private var showingRejectReason = false
    @State private var rejectReason = ""
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attendance.userName)
                            .font(AppTypography.headline)
                            .foregroundColor(.white)
                        
                        Text(attendance.userEmail)
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let department = attendance.department {
                            Text(department)
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(attendance.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        StatusBadge(text: attendance.method.displayName, status: attendance.status)
                    }
                }
                
                if let notes = attendance.notes, !notes.isEmpty {
                    Text("Notes: \(notes)")
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 12) {
                    AnimatedButton(
                        title: "Approve",
                        icon: "checkmark",
                        backgroundColor: AppColors.success
                    ) {
                        approveAttendance()
                    }
                    .disabled(isProcessing)
                    
                    AnimatedButton(
                        title: "Reject",
                        icon: "xmark",
                        backgroundColor: AppColors.error
                    ) {
                        showingRejectReason = true
                    }
                    .disabled(isProcessing)
                }
            }
        }
        .alert("Reject Attendance", isPresented: $showingRejectReason) {
            TextField("Reason for rejection", text: $rejectReason)
            Button("Cancel", role: .cancel) { }
            Button("Reject") {
                rejectAttendance()
            }
        } message: {
            Text("Please provide a reason for rejecting this attendance record.")
        }
    }
    
    private func approveAttendance() {
        guard let attendanceId = attendance.id else { return }
        
        isProcessing = true
        Task {
            do {
                try await AttendanceService.shared.approveAttendance(attendanceId: attendanceId)
                await MainActor.run {
                    isProcessing = false
                    onUpdate()
                }
                HapticFeedback.notification(.success)
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
                HapticFeedback.notification(.error)
                print("Error approving attendance: \(error)")
            }
        }
    }
    
    private func rejectAttendance() {
        guard let attendanceId = attendance.id else { return }
        
        isProcessing = true
        Task {
            do {
                try await AttendanceService.shared.rejectAttendance(attendanceId: attendanceId, reason: rejectReason)
                await MainActor.run {
                    isProcessing = false
                    rejectReason = ""
                    onUpdate()
                }
                HapticFeedback.notification(.success)
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
                HapticFeedback.notification(.error)
                print("Error rejecting attendance: \(error)")
            }
        }
    }
}

// MARK: - Quick Actions View
struct QuickActionsView: View {
    @Binding var showingUserManagement: Bool
    @Binding var showingQRManagement: Bool
    @Binding var showingDataExport: Bool
    @Binding var showingSettings: Bool
    
    private let actions = [
        AdminAction(title: "User Management", icon: "person.3", color: AppColors.primary, action: "userManagement"),
        AdminAction(title: "QR Codes", icon: "qrcode", color: AppColors.secondary, action: "qrManagement"),
        AdminAction(title: "Export Data", icon: "square.and.arrow.up", color: AppColors.success, action: "dataExport"),
        AdminAction(title: "Settings", icon: "gear", color: AppColors.warning, action: "settings")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(actions, id: \.title) { action in
                        AdminActionCard(action: action) {
                            handleAction(action.action)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleAction(_ action: String) {
        switch action {
        case "userManagement":
            showingUserManagement = true
        case "qrManagement":
            showingQRManagement = true
        case "dataExport":
            showingDataExport = true
        case "settings":
            showingSettings = true
        default:
            break
        }
    }
}

// MARK: - Admin Action
struct AdminAction {
    let title: String
    let icon: String
    let color: Color
    let action: String
}

// MARK: - Admin Action Card
struct AdminActionCard: View {
    let action: AdminAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.medium)
            onTap()
        }) {
            GlassCard {
                VStack(spacing: 16) {
                    Image(systemName: action.icon)
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(action.color)
                    
                    Text(action.title)
                        .font(AppTypography.headline)
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

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
            .environmentObject(AttendanceService.shared)
            .environmentObject(AuthService.shared)
            .environmentObject(QRService.shared)
    }
} 