import Foundation
import FirebaseFirestoreSwift

struct QRSession: Codable, Identifiable {
    @DocumentID var id: String?
    var code: String
    var createdAt: Date
    var expiresAt: Date
    var usedBy: [String] // Array of user IDs who have used this QR code
    var isActive: Bool
    var createdBy: String // Admin/Manager ID who created this session
    var sessionName: String?
    var location: String?
    var maxUsage: Int? // Maximum number of times this QR can be used
    var currentUsage: Int
    var sessionType: QRSessionType
    var metadata: [String: String]?
    
    init(code: String, createdBy: String, sessionName: String? = nil, location: String? = nil, maxUsage: Int? = nil, sessionType: QRSessionType = .checkIn, expirationMinutes: Int = 60) {
        self.code = code
        self.createdBy = createdBy
        self.sessionName = sessionName
        self.location = location
        self.maxUsage = maxUsage
        self.sessionType = sessionType
        self.usedBy = []
        self.currentUsage = 0
        self.isActive = true
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expirationMinutes * 60))
        self.metadata = [:]
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var isMaxUsageReached: Bool {
        guard let maxUsage = maxUsage else { return false }
        return currentUsage >= maxUsage
    }
    
    var canBeUsed: Bool {
        return isActive && !isExpired && !isMaxUsageReached
    }
    
    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
    
    var usagePercentage: Double {
        guard let maxUsage = maxUsage, maxUsage > 0 else { return 0.0 }
        return Double(currentUsage) / Double(maxUsage)
    }
}

enum QRSessionType: String, CaseIterable, Codable {
    case checkIn = "check_in"
    case checkOut = "check_out"
    case event = "event"
    case meeting = "meeting"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .checkIn: return "Check In"
        case .checkOut: return "Check Out"
        case .event: return "Event"
        case .meeting: return "Meeting"
        case .general: return "General"
        }
    }
    
    var icon: String {
        switch self {
        case .checkIn: return "arrow.down.circle"
        case .checkOut: return "arrow.up.circle"
        case .event: return "calendar"
        case .meeting: return "person.3"
        case .general: return "qrcode"
        }
    }
}

// MARK: - QR Code Generation Helper
extension QRSession {
    static func generateCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
    
    static let mock = QRSession(
        code: "ABC12345",
        createdBy: "admin123",
        sessionName: "Morning Check-in",
        location: "Main Office",
        maxUsage: 100,
        sessionType: .checkIn
    )
    
    static let mockData: [QRSession] = [
        QRSession(code: "ABC12345", createdBy: "admin1", sessionName: "Morning Check-in", location: "Main Office", maxUsage: 100, sessionType: .checkIn),
        QRSession(code: "XYZ67890", createdBy: "admin1", sessionName: "Team Meeting", location: "Conference Room A", maxUsage: 20, sessionType: .meeting),
        QRSession(code: "DEF54321", createdBy: "admin2", sessionName: "Evening Check-out", location: "Main Office", maxUsage: 100, sessionType: .checkOut)
    ]
} 