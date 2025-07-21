import Foundation
import FirebaseFirestore
import UIKit
import CoreImage

@MainActor
class QRService: ObservableObject {
    static let shared = QRService()
    
    @Published var activeSessions: [QRSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestore = Firestore.firestore()
    
    init() {
        setupListeners()
    }
    
    private func setupListeners() {
        // Listen for active QR sessions
        firestore.collection("qr_sessions")
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to QR sessions: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self?.activeSessions = documents.compactMap { document in
                        try? document.data(as: QRSession.self)
                    }
                }
            }
    }
    
    // MARK: - QR Session Management
    func createQRSession(
        sessionName: String,
        location: String? = nil,
        maxUsage: Int? = nil,
        sessionType: QRSessionType = .checkIn,
        expirationMinutes: Int = 60
    ) async throws -> QRSession {
        guard AuthService.shared.hasAdminAccess(),
              let adminId = AuthService.shared.getCurrentUserId() else {
            throw QRError.insufficientPermissions
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let code = QRSession.generateCode()
            let session = QRSession(
                code: code,
                createdBy: adminId,
                sessionName: sessionName,
                location: location,
                maxUsage: maxUsage,
                sessionType: sessionType,
                expirationMinutes: expirationMinutes
            )
            
            try await firestore.collection("qr_sessions").addDocument(from: session)
            
            isLoading = false
            return session
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    func validateQRCode(_ code: String) async throws -> QRSession {
        let snapshot = try await firestore.collection("qr_sessions")
            .whereField("code", isEqualTo: code)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()
        
        guard let document = snapshot.documents.first,
              let session = try? document.data(as: QRSession.self) else {
            throw QRError.invalidQRCode
        }
        
        guard session.canBeUsed else {
            if session.isExpired {
                throw QRError.qrCodeExpired
            } else if session.isMaxUsageReached {
                throw QRError.maxUsageReached
            } else {
                throw QRError.qrCodeInactive
            }
        }
        
        return session
    }
    
    func useQRCode(_ code: String, userId: String) async throws -> QRSession {
        let session = try await validateQRCode(code)
        
        guard let sessionId = session.id else {
            throw QRError.invalidQRCode
        }
        
        // Check if user has already used this QR code
        if session.usedBy.contains(userId) {
            throw QRError.alreadyUsed
        }
        
        // Update session usage
        let sessionRef = firestore.collection("qr_sessions").document(sessionId)
        try await sessionRef.updateData([
            "usedBy": FieldValue.arrayUnion([userId]),
            "currentUsage": FieldValue.increment(Int64(1))
        ])
        
        // Get updated session
        let updatedDocument = try await sessionRef.getDocument()
        guard let updatedSession = try? updatedDocument.data(as: QRSession.self) else {
            throw QRError.updateFailed
        }
        
        return updatedSession
    }
    
    func deactivateQRSession(sessionId: String) async throws {
        guard AuthService.shared.hasAdminAccess() else {
            throw QRError.insufficientPermissions
        }
        
        let sessionRef = firestore.collection("qr_sessions").document(sessionId)
        try await sessionRef.updateData([
            "isActive": false
        ])
    }
    
    // MARK: - QR Code Generation
    func generateQRCodeImage(from session: QRSession) -> UIImage? {
        let qrData = createQRData(from: session)
        return generateQRCode(from: qrData)
    }
    
    private func createQRData(from session: QRSession) -> String {
        let qrData = [
            "code": session.code,
            "type": session.sessionType.rawValue,
            "location": session.location ?? "",
            "sessionName": session.sessionName ?? "",
            "createdAt": ISO8601DateFormatter().string(from: session.createdAt),
            "expiresAt": ISO8601DateFormatter().string(from: session.expiresAt)
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: qrData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return session.code
        }
        
        return jsonString
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - QR Code Scanning
    func parseQRCode(_ qrString: String) -> QRCodeData? {
        // Try to parse as JSON first
        if let jsonData = qrString.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let code = jsonObject["code"] as? String,
           let typeString = jsonObject["type"] as? String,
           let sessionType = QRSessionType(rawValue: typeString) {
            
            let location = jsonObject["location"] as? String
            let sessionName = jsonObject["sessionName"] as? String
            
            var createdAt: Date?
            var expiresAt: Date?
            
            if let createdAtString = jsonObject["createdAt"] as? String {
                createdAt = ISO8601DateFormatter().date(from: createdAtString)
            }
            
            if let expiresAtString = jsonObject["expiresAt"] as? String {
                expiresAt = ISO8601DateFormatter().date(from: expiresAtString)
            }
            
            return QRCodeData(
                code: code,
                sessionType: sessionType,
                location: location,
                sessionName: sessionName,
                createdAt: createdAt,
                expiresAt: expiresAt
            )
        }
        
        // If not JSON, treat as simple code
        return QRCodeData(
            code: qrString,
            sessionType: .general,
            location: nil,
            sessionName: nil,
            createdAt: nil,
            expiresAt: nil
        )
    }
    
    // MARK: - Data Retrieval
    func fetchQRSessions(for adminId: String) async throws -> [QRSession] {
        let snapshot = try await firestore.collection("qr_sessions")
            .whereField("createdBy", isEqualTo: adminId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: QRSession.self)
        }
    }
    
    func fetchActiveQRSessions() async throws -> [QRSession] {
        let snapshot = try await firestore.collection("qr_sessions")
            .whereField("isActive", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: QRSession.self)
        }
    }
    
    func fetchQRSessionStats(sessionId: String) async throws -> QRSessionStats {
        let session = try await firestore.collection("qr_sessions").document(sessionId).getDocument()
        guard let qrSession = try? session.data(as: QRSession.self) else {
            throw QRError.sessionNotFound
        }
        
        // Fetch attendance records for this session
        let attendanceSnapshot = try await firestore.collection("attendance")
            .whereField("sessionId", isEqualTo: sessionId)
            .getDocuments()
        
        let attendanceRecords = attendanceSnapshot.documents.compactMap { document in
            try? document.data(as: Attendance.self)
        }
        
        let uniqueUsers = Set(attendanceRecords.map { $0.userId })
        let successfulScans = attendanceRecords.filter { $0.status == .checkedIn || $0.status == .approved }
        
        return QRSessionStats(
            session: qrSession,
            totalScans: attendanceRecords.count,
            uniqueUsers: uniqueUsers.count,
            successfulScans: successfulScans.count,
            failedScans: attendanceRecords.count - successfulScans.count,
            usageRate: qrSession.usagePercentage,
            timeRemaining: qrSession.timeRemaining,
            lastUsedAt: attendanceRecords.first?.timestamp
        )
    }
    
    // MARK: - Cleanup
    func cleanupExpiredSessions() async {
        do {
            let snapshot = try await firestore.collection("qr_sessions")
                .whereField("expiresAt", isLessThan: Date())
                .whereField("isActive", isEqualTo: true)
                .getDocuments()
            
            let batch = firestore.batch()
            
            for document in snapshot.documents {
                batch.updateData(["isActive": false], forDocument: document.reference)
            }
            
            try await batch.commit()
            
        } catch {
            print("Error cleaning up expired sessions: \(error)")
        }
    }
    
    func initialize() {
        // Initialize the service
        print("QRService initialized")
    }
}

// MARK: - Supporting Models
struct QRCodeData {
    let code: String
    let sessionType: QRSessionType
    let location: String?
    let sessionName: String?
    let createdAt: Date?
    let expiresAt: Date?
}

struct QRSessionStats {
    let session: QRSession
    let totalScans: Int
    let uniqueUsers: Int
    let successfulScans: Int
    let failedScans: Int
    let usageRate: Double
    let timeRemaining: TimeInterval
    let lastUsedAt: Date?
}

// MARK: - QR Errors
enum QRError: LocalizedError {
    case insufficientPermissions
    case invalidQRCode
    case qrCodeExpired
    case qrCodeInactive
    case maxUsageReached
    case alreadyUsed
    case sessionNotFound
    case updateFailed
    case generationFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Insufficient permissions to manage QR codes"
        case .invalidQRCode:
            return "Invalid QR code"
        case .qrCodeExpired:
            return "QR code has expired"
        case .qrCodeInactive:
            return "QR code is not active"
        case .maxUsageReached:
            return "QR code has reached maximum usage limit"
        case .alreadyUsed:
            return "You have already used this QR code"
        case .sessionNotFound:
            return "QR session not found"
        case .updateFailed:
            return "Failed to update QR session"
        case .generationFailed:
            return "Failed to generate QR code"
        }
    }
} 