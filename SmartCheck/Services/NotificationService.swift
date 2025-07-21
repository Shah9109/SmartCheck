import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount = 0
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var isNotificationEnabled = false
    
    private let firestore = Firestore.firestore()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        setupNotificationCenter()
        setupListeners()
    }
    
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
        checkNotificationPermission()
    }
    
    private func setupListeners() {
        // Listen for user's notifications
        guard let userId = AuthService.shared.getCurrentUserId() else { return }
        
        firestore.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error listening to notifications: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                Task { @MainActor in
                    self?.notifications = documents.compactMap { document in
                        try? document.data(as: AppNotification.self)
                    }
                    
                    self?.updateUnreadCount()
                }
            }
    }
    
    // MARK: - Permission Management
    func requestNotificationPermission() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            notificationPermissionStatus = granted ? .authorized : .denied
            isNotificationEnabled = granted
            
            if granted {
                await UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }
    
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { settings in
            Task { @MainActor in
                self.notificationPermissionStatus = settings.authorizationStatus
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String,
        timeInterval: TimeInterval,
        userInfo: [String: Any] = [:]
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: unreadCount + 1)
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleAttendanceReminder(for date: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        guard let reminderDate = calendar.date(from: components) else { return }
        let reminderTime = calendar.date(byAdding: .hour, value: 9, to: reminderDate) ?? reminderDate
        
        if reminderTime > Date() {
            let timeInterval = reminderTime.timeIntervalSinceNow
            
            scheduleLocalNotification(
                title: "Attendance Reminder",
                body: "Don't forget to check in for today!",
                identifier: "attendance_reminder_\(reminderDate.timeIntervalSince1970)",
                timeInterval: timeInterval,
                userInfo: ["type": "attendance_reminder"]
            )
        }
    }
    
    func scheduleCheckoutReminder(after checkInTime: Date) {
        let checkoutTime = Calendar.current.date(byAdding: .hour, value: 8, to: checkInTime) ?? checkInTime
        let timeInterval = checkoutTime.timeIntervalSinceNow
        
        if timeInterval > 0 {
            scheduleLocalNotification(
                title: "Check Out Reminder",
                body: "Don't forget to check out!",
                identifier: "checkout_reminder_\(checkInTime.timeIntervalSince1970)",
                timeInterval: timeInterval,
                userInfo: ["type": "checkout_reminder"]
            )
        }
    }
    
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Cloud Notifications
    func sendAttendanceNotification(
        to user: User,
        type: NotificationType,
        title: String,
        message: String,
        actionData: [String: String]? = nil
    ) async {
        guard let userId = user.id else { return }
        
        await sendAttendanceNotification(
            userId: userId,
            type: type,
            title: title,
            message: message,
            actionData: actionData
        )
    }
    
    func sendAttendanceNotification(
        userId: String,
        type: NotificationType,
        title: String,
        message: String,
        actionData: [String: String]? = nil
    ) async {
        let notification = AppNotification(
            title: title,
            message: message,
            type: type,
            userId: userId,
            actionData: actionData
        )
        
        do {
            try await firestore.collection("notifications").addDocument(from: notification)
            
            // Send push notification
            await sendPushNotification(
                userId: userId,
                title: title,
                message: message,
                data: actionData
            )
            
        } catch {
            print("Error sending notification: \(error)")
        }
    }
    
    func sendLocationNotification(title: String, message: String) async {
        scheduleLocalNotification(
            title: title,
            body: message,
            identifier: "location_\(Date().timeIntervalSince1970)",
            timeInterval: 1,
            userInfo: ["type": "location"]
        )
    }
    
    func sendQRCodeExpirationNotification(qrSession: QRSession) async {
        guard let adminId = AuthService.shared.getCurrentUserId() else { return }
        
        await sendAttendanceNotification(
            userId: adminId,
            type: .qrCodeExpiring,
            title: "QR Code Expiring",
            message: "QR code '\(qrSession.sessionName ?? qrSession.code)' will expire in 30 minutes",
            actionData: ["sessionId": qrSession.id ?? ""]
        )
    }
    
    private func sendPushNotification(
        userId: String,
        title: String,
        message: String,
        data: [String: String]? = nil
    ) async {
        // In a real app, this would integrate with Firebase Cloud Messaging
        // to send push notifications to specific users
        print("Sending push notification to user \(userId): \(title)")
    }
    
    // MARK: - Notification Management
    func markNotificationAsRead(notificationId: String) async {
        do {
            try await firestore.collection("notifications").document(notificationId).updateData([
                "isRead": true
            ])
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func markAllNotificationsAsRead() async {
        let userId = AuthService.shared.getCurrentUserId() ?? ""
        
        do {
            let snapshot = try await firestore.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .whereField("isRead", isEqualTo: false)
                .getDocuments()
            
            let batch = firestore.batch()
            
            for document in snapshot.documents {
                batch.updateData(["isRead": true], forDocument: document.reference)
            }
            
            try await batch.commit()
            
        } catch {
            print("Error marking all notifications as read: \(error)")
        }
    }
    
    func deleteNotification(notificationId: String) async {
        do {
            try await firestore.collection("notifications").document(notificationId).delete()
        } catch {
            print("Error deleting notification: \(error)")
        }
    }
    
    func deleteAllNotifications() async {
        let userId = AuthService.shared.getCurrentUserId() ?? ""
        
        do {
            let snapshot = try await firestore.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let batch = firestore.batch()
            
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
            
        } catch {
            print("Error deleting all notifications: \(error)")
        }
    }
    
    // MARK: - Utility Functions
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        updateAppBadge()
    }
    
    private func updateAppBadge() {
        UIApplication.shared.applicationIconBadgeNumber = unreadCount
    }
    
    func getNotificationsByType(_ type: NotificationType) -> [AppNotification] {
        return notifications.filter { $0.type == type }
    }
    
    func getUnreadNotifications() -> [AppNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    func getRecentNotifications(limit: Int = 10) -> [AppNotification] {
        return Array(notifications.prefix(limit))
    }
    
    // MARK: - Bulk Operations
    func sendBulkNotification(
        userIds: [String],
        type: NotificationType,
        title: String,
        message: String,
        actionData: [String: String]? = nil
    ) async {
        for userId in userIds {
            await sendAttendanceNotification(
                userId: userId,
                type: type,
                title: title,
                message: message,
                actionData: actionData
            )
        }
    }
    
    func sendDepartmentNotification(
        department: String,
        type: NotificationType,
        title: String,
        message: String,
        actionData: [String: String]? = nil
    ) async {
        do {
            let snapshot = try await firestore.collection("users")
                .whereField("department", isEqualTo: department)
                .getDocuments()
            
            let userIds = snapshot.documents.compactMap { document in
                document.documentID
            }
            
            await sendBulkNotification(
                userIds: userIds,
                type: type,
                title: title,
                message: message,
                actionData: actionData
            )
            
        } catch {
            print("Error sending department notification: \(error)")
        }
    }
    
    func sendRoleBasedNotification(
        role: UserRole,
        type: NotificationType,
        title: String,
        message: String,
        actionData: [String: String]? = nil
    ) async {
        do {
            let snapshot = try await firestore.collection("users")
                .whereField("role", isEqualTo: role.rawValue)
                .getDocuments()
            
            let userIds = snapshot.documents.compactMap { document in
                document.documentID
            }
            
            await sendBulkNotification(
                userIds: userIds,
                type: type,
                title: title,
                message: message,
                actionData: actionData
            )
            
        } catch {
            print("Error sending role-based notification: \(error)")
        }
    }
    
    // MARK: - Cleanup
    func cleanupExpiredNotifications() async {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        do {
            let snapshot = try await firestore.collection("notifications")
                .whereField("createdAt", isLessThan: thirtyDaysAgo)
                .getDocuments()
            
            let batch = firestore.batch()
            
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
            
        } catch {
            print("Error cleaning up expired notifications: \(error)")
        }
    }
    
    func initialize() {
        // Initialize the service
        print("NotificationService initialized")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationAction(userInfo: userInfo)
        completionHandler()
    }
    
    private func handleNotificationAction(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "attendance_reminder":
            // Navigate to attendance screen
            break
        case "checkout_reminder":
            // Navigate to checkout screen
            break
        case "location":
            // Handle location-based notification
            break
        case "qr_code_expiring":
            // Navigate to QR management screen
            break
        default:
            break
        }
    }
}

// MARK: - Notification Errors
enum NotificationError: LocalizedError {
    case permissionDenied
    case scheduleError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission is denied"
        case .scheduleError:
            return "Failed to schedule notification"
        case .networkError:
            return "Network error occurred while sending notification"
        }
    }
} 