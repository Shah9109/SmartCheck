import Foundation
import FirebaseFirestoreSwift

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var role: UserRole
    var profileImageURL: String?
    var biometricEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    var phoneNumber: String?
    var department: String?
    var isActive: Bool
    
    init(email: String, displayName: String, role: UserRole = .student, profileImageURL: String? = nil, biometricEnabled: Bool = false, phoneNumber: String? = nil, department: String? = nil, isActive: Bool = true) {
        self.email = email
        self.displayName = displayName
        self.role = role
        self.profileImageURL = profileImageURL
        self.biometricEnabled = biometricEnabled
        self.phoneNumber = phoneNumber
        self.department = department
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum UserRole: String, CaseIterable, Codable {
    case student = "student"
    case employee = "employee"
    case admin = "admin"
    case manager = "manager"
    
    var displayName: String {
        switch self {
        case .student: return "Student"
        case .employee: return "Employee"
        case .admin: return "Admin"
        case .manager: return "Manager"
        }
    }
    
    var hasAdminAccess: Bool {
        return self == .admin || self == .manager
    }
}

extension User {
    static let mock = User(
        email: "john.doe@example.com",
        displayName: "John Doe",
        role: .student,
        department: "Computer Science"
    )
    
    static let mockAdmin = User(
        email: "admin@example.com",
        displayName: "Admin User",
        role: .admin,
        department: "Administration"
    )
} 