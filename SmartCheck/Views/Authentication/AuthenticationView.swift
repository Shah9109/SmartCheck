import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showingBiometricAuth = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // App Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        Text("SmartCheck")
                            .font(AppTypography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Smart Attendance Made Simple")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Authentication Forms
                TabView(selection: $selectedTab) {
                    LoginView()
                        .tag(0)
                    
                    SignUpView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // Tab Selector
                HStack(spacing: 0) {
                    Button(action: { selectedTab = 0 }) {
                        Text("Sign In")
                            .font(AppTypography.headline)
                            .foregroundColor(selectedTab == 0 ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Rectangle()
                                    .fill(selectedTab == 0 ? Color.white.opacity(0.1) : Color.clear)
                            )
                    }
                    
                    Button(action: { selectedTab = 1 }) {
                        Text("Sign Up")
                            .font(AppTypography.headline)
                            .foregroundColor(selectedTab == 1 ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Rectangle()
                                    .fill(selectedTab == 1 ? Color.white.opacity(0.1) : Color.clear)
                            )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Biometric Authentication Button
                if authService.getBiometricType() != .none {
                    Button(action: {
                        authenticateWithBiometrics()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: authService.getBiometricType().icon)
                                .font(.system(size: 20, weight: .medium))
                            
                            Text("Sign in with \(authService.getBiometricType().displayName)")
                                .font(AppTypography.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .animation(AppAnimations.smooth, value: selectedTab)
        .alert("Authentication Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onReceive(authService.$errorMessage) { error in
            if let error = error {
                errorMessage = error
                showingError = true
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        Task {
            do {
                let success = try await authService.authenticateWithBiometrics()
                if success {
                    // Handle successful biometric authentication
                    print("Biometric authentication successful")
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showingForgotPassword = false
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        icon: "envelope",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    
                    CustomTextField(
                        title: "Password",
                        placeholder: "Enter your password",
                        icon: "lock",
                        text: $password,
                        isSecure: true
                    )
                }
                
                VStack(spacing: 16) {
                    AnimatedButton(
                        title: isLoading ? "Signing In..." : "Sign In",
                        icon: isLoading ? nil : "arrow.right.circle",
                        backgroundColor: AppColors.primary
                    ) {
                        signIn()
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .opacity(isLoading || email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    
                    Button(action: {
                        showingForgotPassword = true
                    }) {
                        Text("Forgot Password?")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authService)
        }
        .onReceive(authService.$isLoading) { loading in
            isLoading = loading
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                HapticFeedback.notification(.success)
            } catch {
                HapticFeedback.notification(.error)
                print("Sign in error: \(error)")
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var department = ""
    @State private var selectedRole = UserRole.student
    @State private var isLoading = false
    @State private var showingRolePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    CustomTextField(
                        title: "Full Name",
                        placeholder: "Enter your full name",
                        icon: "person",
                        text: $displayName
                    )
                    
                    CustomTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        icon: "envelope",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    
                    CustomTextField(
                        title: "Department",
                        placeholder: "Enter your department",
                        icon: "building.2",
                        text: $department
                    )
                    
                    // Role Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role")
                            .font(AppTypography.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: {
                            showingRolePicker = true
                        }) {
                            HStack {
                                Image(systemName: "person.badge")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                Text(selectedRole.displayName)
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
                        title: "Password",
                        placeholder: "Create a password",
                        icon: "lock",
                        text: $password,
                        isSecure: true
                    )
                    
                    CustomTextField(
                        title: "Confirm Password",
                        placeholder: "Confirm your password",
                        icon: "lock.fill",
                        text: $confirmPassword,
                        isSecure: true
                    )
                }
                
                VStack(spacing: 16) {
                    AnimatedButton(
                        title: isLoading ? "Creating Account..." : "Create Account",
                        icon: isLoading ? nil : "person.badge.plus",
                        backgroundColor: AppColors.success
                    ) {
                        signUp()
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
                    
                    if password != confirmPassword && !confirmPassword.isEmpty {
                        Text("Passwords do not match")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                    }
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .actionSheet(isPresented: $showingRolePicker) {
            ActionSheet(
                title: Text("Select Role"),
                buttons: UserRole.allCases.map { role in
                    .default(Text(role.displayName)) {
                        selectedRole = role
                    }
                } + [.cancel()]
            )
        }
        .onReceive(authService.$isLoading) { loading in
            isLoading = loading
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               !displayName.isEmpty &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 6
    }
    
    private func signUp() {
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    displayName: displayName,
                    role: selectedRole,
                    department: department.isEmpty ? nil : department
                )
                HapticFeedback.notification(.success)
            } catch {
                HapticFeedback.notification(.error)
                print("Sign up error: \(error)")
            }
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.arrow.triangle.branch")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("Reset Password")
                            .font(AppTypography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    CustomTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        icon: "envelope",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    
                    AnimatedButton(
                        title: isLoading ? "Sending..." : "Send Reset Link",
                        icon: isLoading ? nil : "arrow.right.circle",
                        backgroundColor: AppColors.primary
                    ) {
                        resetPassword()
                    }
                    .disabled(isLoading || email.isEmpty)
                    .opacity(isLoading || email.isEmpty ? 0.6 : 1.0)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Reset Link Sent", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Check your email for instructions to reset your password.")
        }
    }
    
    private func resetPassword() {
        Task {
            isLoading = true
            do {
                try await authService.resetPassword(email: email)
                showingSuccess = true
                HapticFeedback.notification(.success)
            } catch {
                HapticFeedback.notification(.error)
                print("Reset password error: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Preview
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthService.shared)
    }
} 