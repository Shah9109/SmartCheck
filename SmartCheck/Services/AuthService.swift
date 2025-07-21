import Foundation
import FirebaseAuth
import FirebaseFirestore
import LocalAuthentication
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.fetchCurrentUser(uid: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Email Authentication
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchCurrentUser(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, displayName: String, role: UserRole = .student, department: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let newUser = User(
                email: email,
                displayName: displayName,
                role: role,
                department: department
            )
            
            try await saveUserToFirestore(user: newUser, uid: result.user.uid)
            await fetchCurrentUser(uid: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricNotAvailable
        }
        
        let reason = "Authenticate with Face ID or Touch ID to access SmartCheck"
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: AuthError.biometricAuthenticationFailed)
                }
            }
        }
    }
    
    func enableBiometricAuth() async throws {
        guard var user = currentUser else { return }
        
        // Test biometric authentication first
        let success = try await authenticateWithBiometrics()
        
        if success {
            user.biometricEnabled = true
            user.updatedAt = Date()
            try await updateUserProfile(user: user)
        }
    }
    
    func disableBiometricAuth() async throws {
        guard var user = currentUser else { return }
        
        user.biometricEnabled = false
        user.updatedAt = Date()
        try await updateUserProfile(user: user)
    }
    
    // MARK: - User Profile Management
    private func fetchCurrentUser(uid: String) async {
        do {
            let document = try await firestore.collection("users").document(uid).getDocument()
            if let userData = try? document.data(as: User.self) {
                currentUser = userData
                isAuthenticated = true
            }
        } catch {
            print("Error fetching user: \(error)")
        }
    }
    
    private func saveUserToFirestore(user: User, uid: String) async throws {
        try await firestore.collection("users").document(uid).setData(from: user)
    }
    
    func updateUserProfile(user: User) async throws {
        guard let uid = auth.currentUser?.uid else { return }
        
        var updatedUser = user
        updatedUser.updatedAt = Date()
        
        try await firestore.collection("users").document(uid).setData(from: updatedUser)
        currentUser = updatedUser
    }
    
    // MARK: - Profile Image
    func updateProfileImage(imageData: Data) async throws -> String {
        guard let uid = auth.currentUser?.uid else { throw AuthError.userNotAuthenticated }
        
        // In a real app, you would upload to Firebase Storage
        // For now, we'll simulate the URL
        let imageURL = "https://firebasestorage.googleapis.com/profile_images/\(uid).jpg"
        
        guard var user = currentUser else { throw AuthError.userNotAuthenticated }
        user.profileImageURL = imageURL
        user.updatedAt = Date()
        
        try await updateUserProfile(user: user)
        
        return imageURL
    }
    
    // MARK: - User Validation
    func validateUser() -> Bool {
        return currentUser != nil && isAuthenticated
    }
    
    func hasAdminAccess() -> Bool {
        return currentUser?.role.hasAdminAccess ?? false
    }
    
    // MARK: - Utility Functions
    func getCurrentUserId() -> String? {
        return auth.currentUser?.uid
    }
    
    func getCurrentUserEmail() -> String? {
        return auth.currentUser?.email
    }
    
    func initialize() {
        // Initialize the service
        print("AuthService initialized")
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case userNotAuthenticated
    case biometricNotAvailable
    case biometricAuthenticationFailed
    case invalidCredentials
    case userAlreadyExists
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userAlreadyExists:
            return "User already exists"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Biometric Helper
extension AuthService {
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        default:
            return .none
        }
    }
}

enum BiometricType {
    case none
    case faceID
    case touchID
    case opticID
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "xmark"
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        }
    }
} 