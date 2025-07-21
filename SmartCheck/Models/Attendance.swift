import Foundation
import FirebaseFirestoreSwift
import CoreLocation

struct Attendance: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var userName: String
    var userEmail: String
    var method: AttendanceMethod
    var timestamp: Date
    var location: AttendanceLocation?
    var status: AttendanceStatus
    var notes: String?
    var adminId: String?
    var adminName: String?
    var approvedAt: Date?
    var createdAt: Date
    var department: String?
    var sessionId: String?
    
    init(userId: String, userName: String, userEmail: String, method: AttendanceMethod, location: AttendanceLocation? = nil, status: AttendanceStatus = .pending, notes: String? = nil, department: String? = nil, sessionId: String? = nil) {
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.method = method
        self.location = location
        self.status = status
        self.notes = notes
        self.department = department
        self.sessionId = sessionId
        self.timestamp = Date()
        self.createdAt = Date()
    }
}

enum AttendanceMethod: String, CaseIterable, Codable {
    case qr = "qr"
    case face = "face"
    case manual = "manual"
    case location = "location"
    case biometric = "biometric"
    
    var displayName: String {
        switch self {
        case .qr: return "QR Code"
        case .face: return "Face Recognition"
        case .manual: return "Manual Entry"
        case .location: return "Location-based"
        case .biometric: return "Biometric"
        }
    }
    
    var icon: String {
        switch self {
        case .qr: return "qrcode"
        case .face: return "faceid"
        case .manual: return "hand.point.right"
        case .location: return "location"
        case .biometric: return "touchid"
        }
    }
}

enum AttendanceStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case checkedIn = "checked_in"
    case checkedOut = "checked_out"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .checkedIn: return "Checked In"
        case .checkedOut: return "Checked Out"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        case .checkedIn: return "blue"
        case .checkedOut: return "purple"
        }
    }
}

struct AttendanceLocation: Codable {
    var latitude: Double
    var longitude: Double
    var address: String?
    var accuracy: Double
    
    init(coordinate: CLLocationCoordinate2D, address: String? = nil, accuracy: Double = 0.0) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.accuracy = accuracy
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension Attendance {
    static let mock = Attendance(
        userId: "user123",
        userName: "John Doe",
        userEmail: "john.doe@example.com",
        method: .qr,
        status: .approved,
        department: "Computer Science"
    )
    
    static let mockData: [Attendance] = [
        Attendance(userId: "user1", userName: "Alice Johnson", userEmail: "alice@example.com", method: .qr, status: .approved, department: "Engineering"),
        Attendance(userId: "user2", userName: "Bob Smith", userEmail: "bob@example.com", method: .face, status: .pending, department: "Marketing"),
        Attendance(userId: "user3", userName: "Carol Davis", userEmail: "carol@example.com", method: .location, status: .checkedIn, department: "Design")
    ]
} 