import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import CoreLocation

@MainActor
class AttendanceService: ObservableObject {
    static let shared = AttendanceService()
    
    @Published var attendanceRecords: [Attendance] = []
    @Published var todayAttendance: [Attendance] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analytics: AttendanceAnalytics?
    
    private let firestore = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupListeners()
    }
    
    private func setupListeners() {
        // Listen for real-time attendance updates
        firestore.collection("attendance")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to attendance: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self?.attendanceRecords = documents.compactMap { document in
                        try? document.data(as: Attendance.self)
                    }
                    
                    self?.updateTodayAttendance()
                    await self?.updateAnalytics()
                }
            }
    }
    
    // MARK: - Attendance Creation
    func checkIn(method: AttendanceMethod, location: AttendanceLocation? = nil, notes: String? = nil, sessionId: String? = nil) async throws {
        guard let user = AuthService.shared.currentUser,
              let userId = AuthService.shared.getCurrentUserId() else {
            throw AttendanceError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let attendance = Attendance(
                userId: userId,
                userName: user.displayName,
                userEmail: user.email,
                method: method,
                location: location,
                status: method == .manual ? .pending : .checkedIn,
                notes: notes,
                department: user.department,
                sessionId: sessionId
            )
            
            try await saveAttendance(attendance)
            
            // Send notification for manual attendance
            if method == .manual {
                await NotificationService.shared.sendAttendanceNotification(
                    to: user,
                    type: .attendanceReminder,
                    title: "Manual Attendance Submitted",
                    message: "Your manual attendance is pending approval."
                )
            }
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func checkOut(method: AttendanceMethod, location: AttendanceLocation? = nil, notes: String? = nil) async throws {
        guard let user = AuthService.shared.currentUser,
              let userId = AuthService.shared.getCurrentUserId() else {
            throw AttendanceError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let attendance = Attendance(
                userId: userId,
                userName: user.displayName,
                userEmail: user.email,
                method: method,
                location: location,
                status: .checkedOut,
                notes: notes,
                department: user.department
            )
            
            try await saveAttendance(attendance)
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    private func saveAttendance(_ attendance: Attendance) async throws {
        try await firestore.collection("attendance").addDocument(from: attendance)
    }
    
    // MARK: - Attendance Management (Admin)
    func approveAttendance(attendanceId: String, adminNotes: String? = nil) async throws {
        guard AuthService.shared.hasAdminAccess(),
              let adminUser = AuthService.shared.currentUser else {
            throw AttendanceError.insufficientPermissions
        }
        
        let attendanceRef = firestore.collection("attendance").document(attendanceId)
        
        try await attendanceRef.updateData([
            "status": AttendanceStatus.approved.rawValue,
            "adminId": AuthService.shared.getCurrentUserId() ?? "",
            "adminName": adminUser.displayName,
            "approvedAt": Date(),
            "notes": adminNotes ?? ""
        ])
        
        // Send notification to user
        if let attendance = attendanceRecords.first(where: { $0.id == attendanceId }) {
            await NotificationService.shared.sendAttendanceNotification(
                userId: attendance.userId,
                type: .attendanceApproved,
                title: "Attendance Approved",
                message: "Your attendance has been approved by \(adminUser.displayName)"
            )
        }
    }
    
    func rejectAttendance(attendanceId: String, reason: String) async throws {
        guard AuthService.shared.hasAdminAccess(),
              let adminUser = AuthService.shared.currentUser else {
            throw AttendanceError.insufficientPermissions
        }
        
        let attendanceRef = firestore.collection("attendance").document(attendanceId)
        
        try await attendanceRef.updateData([
            "status": AttendanceStatus.rejected.rawValue,
            "adminId": AuthService.shared.getCurrentUserId() ?? "",
            "adminName": adminUser.displayName,
            "approvedAt": Date(),
            "notes": reason
        ])
        
        // Send notification to user
        if let attendance = attendanceRecords.first(where: { $0.id == attendanceId }) {
            await NotificationService.shared.sendAttendanceNotification(
                userId: attendance.userId,
                type: .attendanceRejected,
                title: "Attendance Rejected",
                message: "Your attendance has been rejected: \(reason)"
            )
        }
    }
    
    // MARK: - Data Retrieval
    func fetchAttendanceForUser(userId: String, startDate: Date? = nil, endDate: Date? = nil) async throws -> [Attendance] {
        var query: Query = firestore.collection("attendance")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
        
        if let startDate = startDate {
            query = query.whereField("timestamp", isGreaterThanOrEqualTo: startDate)
        }
        
        if let endDate = endDate {
            query = query.whereField("timestamp", isLessThanOrEqualTo: endDate)
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Attendance.self)
        }
    }
    
    func fetchAttendanceForDate(_ date: Date) async throws -> [Attendance] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let snapshot = try await firestore.collection("attendance")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Attendance.self)
        }
    }
    
    func fetchPendingAttendance() async throws -> [Attendance] {
        let snapshot = try await firestore.collection("attendance")
            .whereField("status", isEqualTo: AttendanceStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Attendance.self)
        }
    }
    
    // MARK: - Analytics
    private func updateTodayAttendance() {
        let calendar = Calendar.current
        let today = Date()
        todayAttendance = attendanceRecords.filter { attendance in
            calendar.isDate(attendance.timestamp, inSameDayAs: today)
        }
    }
    
    func updateAnalytics() async {
        do {
            // Fetch all users for total count
            let usersSnapshot = try await firestore.collection("users").getDocuments()
            let totalUsers = usersSnapshot.documents.count
            
            // Calculate analytics
            let now = Date()
            let calendar = Calendar.current
            
            let startOfToday = calendar.startOfDay(for: now)
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? startOfToday
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? startOfToday
            
            let todayRecords = attendanceRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
            let weeklyRecords = attendanceRecords.filter { $0.timestamp >= startOfWeek }
            let monthlyRecords = attendanceRecords.filter { $0.timestamp >= startOfMonth }
            
            // Calculate department stats
            var departmentStats: [String: Int] = [:]
            var methodStats: [String: Int] = [:]
            
            for record in todayRecords {
                if let department = record.department {
                    departmentStats[department, default: 0] += 1
                }
                methodStats[record.method.rawValue, default: 0] += 1
            }
            
            // Calculate active users (users who have checked in today)
            let activeUsers = Set(todayRecords.map { $0.userId }).count
            
            // Calculate late arrivals and early departures
            let lateArrivals = todayRecords.filter { record in
                let hour = calendar.component(.hour, from: record.timestamp)
                return record.status == .checkedIn && hour > 9 // After 9 AM
            }.count
            
            let earlyDepartures = todayRecords.filter { record in
                let hour = calendar.component(.hour, from: record.timestamp)
                return record.status == .checkedOut && hour < 17 // Before 5 PM
            }.count
            
            // Calculate average times
            let checkInTimes = todayRecords.filter { $0.status == .checkedIn }.map { $0.timestamp }
            let checkOutTimes = todayRecords.filter { $0.status == .checkedOut }.map { $0.timestamp }
            
            let averageCheckInTime = calculateAverageTime(from: checkInTimes)
            let averageCheckOutTime = calculateAverageTime(from: checkOutTimes)
            
            analytics = AttendanceAnalytics(
                totalUsers: totalUsers,
                activeUsers: activeUsers,
                todayAttendance: todayRecords.count,
                weeklyAttendance: weeklyRecords.count,
                monthlyAttendance: monthlyRecords.count,
                averageCheckInTime: averageCheckInTime,
                averageCheckOutTime: averageCheckOutTime,
                departmentStats: departmentStats,
                methodStats: methodStats,
                lateArrivals: lateArrivals,
                earlyDepartures: earlyDepartures,
                lastUpdated: Date()
            )
            
        } catch {
            print("Error updating analytics: \(error)")
        }
    }
    
    private func calculateAverageTime(from dates: [Date]) -> String {
        guard !dates.isEmpty else { return "00:00" }
        
        let calendar = Calendar.current
        let totalMinutes = dates.reduce(0) { total, date in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return total + (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
        
        let averageMinutes = totalMinutes / dates.count
        let hours = averageMinutes / 60
        let minutes = averageMinutes % 60
        
        return String(format: "%02d:%02d", hours, minutes)
    }
    
    // MARK: - Utility Functions
    func getTodayAttendanceForUser(userId: String) -> [Attendance] {
        return todayAttendance.filter { $0.userId == userId }
    }
    
    func hasCheckedInToday(userId: String) -> Bool {
        return todayAttendance.contains { $0.userId == userId && $0.status == .checkedIn }
    }
    
    func hasCheckedOutToday(userId: String) -> Bool {
        return todayAttendance.contains { $0.userId == userId && $0.status == .checkedOut }
    }
    
    func getLastCheckIn(userId: String) -> Attendance? {
        return attendanceRecords.first { $0.userId == userId && $0.status == .checkedIn }
    }
    
    func getLastCheckOut(userId: String) -> Attendance? {
        return attendanceRecords.first { $0.userId == userId && $0.status == .checkedOut }
    }
    
    // MARK: - Additional Methods
    func fetchTodayAttendance() async throws -> [Attendance] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let snapshot = try await firestore.collection("attendance")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Attendance.self)
        }
    }
    
    func fetchPendingAttendance() async throws -> [Attendance] {
        let snapshot = try await firestore.collection("attendance")
            .whereField("status", isEqualTo: AttendanceStatus.pending.rawValue)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Attendance.self)
        }
    }
    
    func approveAttendance(attendanceId: String) async throws {
        guard let adminId = AuthService.shared.getCurrentUserId(),
              let admin = AuthService.shared.currentUser else {
            throw AttendanceError.userNotAuthenticated
        }
        
        guard admin.role.hasAdminAccess else {
            throw AttendanceError.insufficientPermissions
        }
        
        try await firestore.collection("attendance").document(attendanceId).updateData([
            "status": AttendanceStatus.approved.rawValue,
            "adminId": adminId,
            "adminName": admin.displayName,
            "approvedAt": Date()
        ])
    }
    
    func rejectAttendance(attendanceId: String, reason: String) async throws {
        guard let adminId = AuthService.shared.getCurrentUserId(),
              let admin = AuthService.shared.currentUser else {
            throw AttendanceError.userNotAuthenticated
        }
        
        guard admin.role.hasAdminAccess else {
            throw AttendanceError.insufficientPermissions
        }
        
        try await firestore.collection("attendance").document(attendanceId).updateData([
            "status": AttendanceStatus.rejected.rawValue,
            "adminId": adminId,
            "adminName": admin.displayName,
            "approvedAt": Date(),
            "notes": reason
        ])
    }
    
    func exportAttendanceData(parameters: ExportParameters) async throws -> URL {
        // This is a simplified version - in a real app you'd implement proper export logic
        let fileName = "attendance_export_\(Date().timeIntervalSince1970).\(parameters.format.rawValue)"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Create mock CSV data for now
        let csvContent = "Date,User,Method,Status\n2024-01-15,John Doe,QR Code,Approved\n"
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    func initialize() {
        // Initialize the service
        print("AttendanceService initialized")
    }
}

// MARK: - Attendance Errors
enum AttendanceError: LocalizedError {
    case userNotAuthenticated
    case insufficientPermissions
    case alreadyCheckedIn
    case alreadyCheckedOut
    case qrCodeExpired
    case qrCodeInvalid
    case locationNotAllowed
    case faceRecognitionFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .insufficientPermissions:
            return "Insufficient permissions to perform this action"
        case .alreadyCheckedIn:
            return "Already checked in today"
        case .alreadyCheckedOut:
            return "Already checked out today"
        case .qrCodeExpired:
            return "QR code has expired"
        case .qrCodeInvalid:
            return "Invalid QR code"
        case .locationNotAllowed:
            return "Location access is required for this check-in method"
        case .faceRecognitionFailed:
            return "Face recognition failed"
        case .networkError:
            return "Network error occurred"
        }
    }
} 