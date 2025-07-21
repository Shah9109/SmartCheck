import Foundation
import FirebaseFirestoreSwift

// MARK: - Notification Model
struct AppNotification: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var message: String
    var type: NotificationType
    var userId: String
    var isRead: Bool
    var createdAt: Date
    var actionData: [String: String]?
    var expiresAt: Date?
    
    init(title: String, message: String, type: NotificationType, userId: String, actionData: [String: String]? = nil, expiresAt: Date? = nil) {
        self.title = title
        self.message = message
        self.type = type
        self.userId = userId
        self.actionData = actionData
        self.expiresAt = expiresAt
        self.isRead = false
        self.createdAt = Date()
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

enum NotificationType: String, CaseIterable, Codable {
    case attendanceReminder = "attendance_reminder"
    case attendanceApproved = "attendance_approved"
    case attendanceRejected = "attendance_rejected"
    case qrCodeExpiring = "qr_code_expiring"
    case adminAction = "admin_action"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .attendanceReminder: return "Attendance Reminder"
        case .attendanceApproved: return "Attendance Approved"
        case .attendanceRejected: return "Attendance Rejected"
        case .qrCodeExpiring: return "QR Code Expiring"
        case .adminAction: return "Admin Action"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .attendanceReminder: return "bell"
        case .attendanceApproved: return "checkmark.circle"
        case .attendanceRejected: return "xmark.circle"
        case .qrCodeExpiring: return "qrcode"
        case .adminAction: return "person.badge.key"
        case .general: return "info.circle"
        }
    }
}

// MARK: - App Settings Model
struct AppSettings: Codable {
    var theme: AppTheme
    var language: AppLanguage
    var notificationsEnabled: Bool
    var biometricEnabled: Bool
    var locationTrackingEnabled: Bool
    var soundEnabled: Bool
    var autoCheckoutEnabled: Bool
    var autoCheckoutDelay: Int // in minutes
    var lastSyncDate: Date?
    
    init() {
        self.theme = .system
        self.language = .english
        self.notificationsEnabled = true
        self.biometricEnabled = false
        self.locationTrackingEnabled = true
        self.soundEnabled = true
        self.autoCheckoutEnabled = false
        self.autoCheckoutDelay = 480 // 8 hours
        self.lastSyncDate = nil
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "gear"
        }
    }
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
}

// MARK: - Analytics Model
struct AttendanceAnalytics: Codable {
    var totalUsers: Int
    var activeUsers: Int
    var todayAttendance: Int
    var weeklyAttendance: Int
    var monthlyAttendance: Int
    var averageCheckInTime: String
    var averageCheckOutTime: String
    var departmentStats: [String: Int]
    var methodStats: [String: Int]
    var lateArrivals: Int
    var earlyDepartures: Int
    var lastUpdated: Date
    
    init() {
        self.totalUsers = 0
        self.activeUsers = 0
        self.todayAttendance = 0
        self.weeklyAttendance = 0
        self.monthlyAttendance = 0
        self.averageCheckInTime = "09:00"
        self.averageCheckOutTime = "17:00"
        self.departmentStats = [:]
        self.methodStats = [:]
        self.lateArrivals = 0
        self.earlyDepartures = 0
        self.lastUpdated = Date()
    }
}

// MARK: - Export Model
struct ExportRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var requestedBy: String
    var requestedByName: String
    var dateRange: DateRange
    var format: ExportFormat
    var filters: ExportFilters
    var status: ExportStatus
    var downloadURL: String?
    var createdAt: Date
    var completedAt: Date?
    var errorMessage: String?
    
    init(requestedBy: String, requestedByName: String, dateRange: DateRange, format: ExportFormat, filters: ExportFilters) {
        self.requestedBy = requestedBy
        self.requestedByName = requestedByName
        self.dateRange = dateRange
        self.format = format
        self.filters = filters
        self.status = .pending
        self.createdAt = Date()
    }
}

struct DateRange: Codable {
    var startDate: Date
    var endDate: Date
}

struct ExportFilters: Codable {
    var departments: [String]
    var userRoles: [String]
    var attendanceMethods: [String]
    var attendanceStatus: [String]
    var includeLocation: Bool
    var includeNotes: Bool
    
    init() {
        self.departments = []
        self.userRoles = []
        self.attendanceMethods = []
        self.attendanceStatus = []
        self.includeLocation = true
        self.includeNotes = false
    }
}

enum ExportFormat: String, CaseIterable, Codable {
    case csv = "csv"
    case excel = "excel"
    case pdf = "pdf"
    case json = "json"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .excel: return "Excel"
        case .pdf: return "PDF"
        case .json: return "JSON"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .csv: return ".csv"
        case .excel: return ".xlsx"
        case .pdf: return ".pdf"
        case .json: return ".json"
        }
    }
}

enum ExportStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
} 