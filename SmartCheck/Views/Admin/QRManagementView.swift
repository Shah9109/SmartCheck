import SwiftUI

struct QRManagementView: View {
    @EnvironmentObject var qrService: QRService
    @Environment(\.presentationMode) var presentationMode
    @State private var showingCreateQR = false
    @State private var qrSessions: [QRSession] = []
    @State private var isLoading = false
    @State private var selectedSession: QRSession?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    QRManagementHeader(showingCreateQR: $showingCreateQR)
                        .padding()
                    
                    // QR Sessions List
                    if isLoading {
                        Spacer()
                        HStack(spacing: 12) {
                            LoadingIndicator()
                            Text("Loading QR sessions...")
                                .font(AppTypography.body)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    } else if qrSessions.isEmpty {
                        Spacer()
                        GlassCard {
                            VStack(spacing: 16) {
                                Image(systemName: "qrcode")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("No QR Sessions")
                                    .font(AppTypography.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Create your first QR code session to get started")
                                    .font(AppTypography.body)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                AnimatedButton(
                                    title: "Create QR Session",
                                    icon: "plus.circle",
                                    backgroundColor: AppColors.primary
                                ) {
                                    showingCreateQR = true
                                }
                                .padding(.top, 16)
                            }
                            .padding()
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(qrSessions) { session in
                                    QRSessionCard(session: session) {
                                        selectedSession = session
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingCreateQR) {
            CreateQRSessionView()
                .environmentObject(qrService)
                .onDisappear {
                    loadQRSessions()
                }
        }
        .sheet(item: $selectedSession) { session in
            QRSessionDetailView(session: session)
                .environmentObject(qrService)
                .onDisappear {
                    loadQRSessions()
                }
        }
        .onAppear {
            loadQRSessions()
        }
    }
    
    private func loadQRSessions() {
        isLoading = true
        Task {
            do {
                let sessions = try await qrService.fetchActiveQRSessions()
                await MainActor.run {
                    qrSessions = sessions
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error loading QR sessions: \(error)")
            }
        }
    }
}

// MARK: - QR Management Header
struct QRManagementHeader: View {
    @Binding var showingCreateQR: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("QR Code Management")
                    .font(AppTypography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Create and manage QR code sessions")
                    .font(AppTypography.body)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            AnimatedButton(
                title: "Create QR",
                icon: "qrcode",
                backgroundColor: AppColors.success
            ) {
                showingCreateQR = true
            }
        }
    }
}

// MARK: - QR Session Card
struct QRSessionCard: View {
    let session: QRSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onTap()
        }) {
            GlassCard {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.sessionName ?? "QR Session")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                            
                            Text("Code: \(session.code)")
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .fontFamily(.monospaced)
                            
                            if let location = session.location {
                                Text(location)
                                    .font(AppTypography.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            StatusBadge(
                                text: session.sessionType.displayName,
                                status: .approved
                            )
                            
                            Text(session.isActive ? "Active" : "Inactive")
                                .font(AppTypography.caption)
                                .foregroundColor(session.isActive ? AppColors.success : AppColors.error)
                        }
                    }
                    
                    // Usage Stats
                    VStack(spacing: 8) {
                        HStack {
                            Text("Usage")
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            if let maxUsage = session.maxUsage {
                                Text("\(session.currentUsage)/\(maxUsage)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Text("\(session.currentUsage)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        if let maxUsage = session.maxUsage {
                            ProgressView(value: Double(session.currentUsage), total: Double(maxUsage))
                                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        }
                    }
                    
                    // Time Remaining
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(timeRemainingText)
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeRemainingText: String {
        let remaining = session.timeRemaining
        if remaining <= 0 {
            return "Expired"
        }
        
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}

// MARK: - Create QR Session View
struct CreateQRSessionView: View {
    @EnvironmentObject var qrService: QRService
    @Environment(\.presentationMode) var presentationMode
    @State private var sessionName = ""
    @State private var location = ""
    @State private var selectedType = QRSessionType.checkIn
    @State private var maxUsage = ""
    @State private var expirationHours = 1.0
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Session Name",
                                placeholder: "Enter session name",
                                icon: "tag",
                                text: $sessionName
                            )
                            
                            CustomTextField(
                                title: "Location (Optional)",
                                placeholder: "Enter location",
                                icon: "location",
                                text: $location
                            )
                            
                            // Session Type Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Session Type")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Menu {
                                    ForEach(QRSessionType.allCases, id: \.self) { type in
                                        Button(action: {
                                            selectedType = type
                                        }) {
                                            HStack {
                                                Image(systemName: type.icon)
                                                Text(type.displayName)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedType.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 20)
                                        
                                        Text(selectedType.displayName)
                                            .font(AppTypography.body)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                            
                            CustomTextField(
                                title: "Max Usage (Optional)",
                                placeholder: "Leave empty for unlimited",
                                icon: "number",
                                text: $maxUsage,
                                keyboardType: .numberPad
                            )
                            
                            // Expiration Slider
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expires in: \(Int(expirationHours)) hours")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Slider(value: $expirationHours, in: 1...24, step: 1)
                                    .accentColor(AppColors.primary)
                                
                                HStack {
                                    Text("1 hour")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("24 hours")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        AnimatedButton(
                            title: isLoading ? "Creating..." : "Create QR Session",
                            icon: isLoading ? nil : "qrcode",
                            backgroundColor: AppColors.success
                        ) {
                            createQRSession()
                        }
                        .disabled(isLoading || sessionName.isEmpty)
                        .opacity(isLoading || sessionName.isEmpty ? 0.6 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Create QR Session")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createQRSession() {
        isLoading = true
        Task {
            do {
                let maxUsageInt = maxUsage.isEmpty ? nil : Int(maxUsage)
                let expirationMinutes = Int(expirationHours * 60)
                
                let session = try await qrService.createQRSession(
                    sessionName: sessionName,
                    location: location.isEmpty ? nil : location,
                    maxUsage: maxUsageInt,
                    sessionType: selectedType,
                    expirationMinutes: expirationMinutes
                )
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
                
                HapticFeedback.notification(.success)
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                
                HapticFeedback.notification(.error)
            }
        }
    }
}

// MARK: - QR Session Detail View
struct QRSessionDetailView: View {
    let session: QRSession
    @EnvironmentObject var qrService: QRService
    @Environment(\.presentationMode) var presentationMode
    @State private var showingQRCode = false
    @State private var sessionStats: QRSessionStats?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // QR Code Display
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("QR Code")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                if let qrImage = qrService.generateQRCodeImage(from: session) {
                                    Image(uiImage: qrImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 200, height: 200)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 200, height: 200)
                                        .overlay(
                                            Text("QR Code\nUnavailable")
                                                .font(AppTypography.body)
                                                .foregroundColor(.white.opacity(0.7))
                                                .multilineTextAlignment(.center)
                                        )
                                }
                                
                                Text("Code: \(session.code)")
                                    .font(AppTypography.body)
                                    .fontFamily(.monospaced)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                    )
                                
                                AnimatedButton(
                                    title: "Share QR Code",
                                    icon: "square.and.arrow.up",
                                    backgroundColor: AppColors.primary
                                ) {
                                    shareQRCode()
                                }
                            }
                        }
                        
                        // Session Info
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Session Information")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    InfoRow(title: "Name", value: session.sessionName ?? "Unnamed Session")
                                    InfoRow(title: "Type", value: session.sessionType.displayName)
                                    InfoRow(title: "Location", value: session.location ?? "Not specified")
                                    InfoRow(title: "Created", value: session.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    InfoRow(title: "Expires", value: session.expiresAt.formatted(date: .abbreviated, time: .shortened))
                                    InfoRow(title: "Status", value: session.isActive ? "Active" : "Inactive")
                                }
                            }
                        }
                        
                        // Statistics
                        if let stats = sessionStats {
                            GlassCard {
                                VStack(spacing: 16) {
                                    Text("Usage Statistics")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                        StatItem(title: "Total Scans", value: "\(stats.totalScans)", color: AppColors.primary)
                                        StatItem(title: "Unique Users", value: "\(stats.uniqueUsers)", color: AppColors.success)
                                        StatItem(title: "Successful", value: "\(stats.successfulScans)", color: AppColors.info)
                                        StatItem(title: "Failed", value: "\(stats.failedScans)", color: AppColors.error)
                                    }
                                    
                                    if let lastUsed = stats.lastUsedAt {
                                        InfoRow(title: "Last Used", value: lastUsed.formatted(date: .abbreviated, time: .shortened))
                                    }
                                }
                            }
                        }
                        
                        // Actions
                        VStack(spacing: 12) {
                            if session.isActive {
                                AnimatedButton(
                                    title: "Deactivate Session",
                                    icon: "stop.circle",
                                    backgroundColor: AppColors.error
                                ) {
                                    deactivateSession()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("QR Session")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            loadSessionStats()
        }
    }
    
    private func loadSessionStats() {
        guard let sessionId = session.id else { return }
        
        isLoading = true
        Task {
            do {
                let stats = try await qrService.fetchQRSessionStats(sessionId: sessionId)
                await MainActor.run {
                    sessionStats = stats
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error loading session stats: \(error)")
            }
        }
    }
    
    private func shareQRCode() {
        // In a real app, you would implement sharing functionality
        HapticFeedback.impact(.medium)
    }
    
    private func deactivateSession() {
        guard let sessionId = session.id else { return }
        
        Task {
            do {
                try await qrService.deactivateQRSession(sessionId: sessionId)
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
                HapticFeedback.notification(.success)
            } catch {
                HapticFeedback.notification(.error)
                print("Error deactivating session: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(AppTypography.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct QRManagementView_Previews: PreviewProvider {
    static var previews: some View {
        QRManagementView()
            .environmentObject(QRService.shared)
    }
} 