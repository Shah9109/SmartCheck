import SwiftUI
import PhotosUI

struct ProfileManagementView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var displayName = ""
    @State private var email = ""
    @State private var department = ""
    @State private var phoneNumber = ""
    @State private var bio = ""
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingImagePicker = false
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Section
                        ProfileImageSection(
                            profileImage: $profileImage,
                            showingImagePicker: $showingImagePicker,
                            imageSource: $imageSource,
                            isEditing: isEditing
                        )
                        
                        // Personal Information
                        GlassCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Personal Information")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        if isEditing {
                                            saveProfile()
                                        } else {
                                            isEditing = true
                                        }
                                    }) {
                                        if isLoading {
                                            LoadingIndicator(size: 20)
                                        } else {
                                            Text(isEditing ? "Save" : "Edit")
                                                .font(AppTypography.subheadline)
                                                .foregroundColor(AppColors.primary)
                                        }
                                    }
                                    .disabled(isLoading)
                                }
                                
                                VStack(spacing: 16) {
                                    if isEditing {
                                        CustomTextField(
                                            title: "Display Name",
                                            placeholder: "Enter your name",
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
                                        .disabled(true) // Email usually can't be changed
                                        
                                        CustomTextField(
                                            title: "Department",
                                            placeholder: "Enter your department",
                                            icon: "building.2",
                                            text: $department
                                        )
                                        
                                        CustomTextField(
                                            title: "Phone Number",
                                            placeholder: "Enter your phone number",
                                            icon: "phone",
                                            text: $phoneNumber,
                                            keyboardType: .phonePad
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Bio")
                                                .font(AppTypography.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            TextEditor(text: $bio)
                                                .frame(minHeight: 80)
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.white.opacity(0.1))
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        ProfileInfoRow(title: "Name", value: displayName)
                                        ProfileInfoRow(title: "Email", value: email)
                                        ProfileInfoRow(title: "Department", value: department.isEmpty ? "Not specified" : department)
                                        ProfileInfoRow(title: "Phone", value: phoneNumber.isEmpty ? "Not specified" : phoneNumber)
                                        
                                        if !bio.isEmpty {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Bio")
                                                    .font(AppTypography.subheadline)
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Text(bio)
                                                    .font(AppTypography.body)
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.leading)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                    }
                                }
                                
                                if isEditing {
                                    HStack(spacing: 12) {
                                        Button("Cancel") {
                                            isEditing = false
                                            loadUserData()
                                        }
                                        .font(AppTypography.body)
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.1))
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                        
                                        AnimatedButton(
                                            title: "Save Changes",
                                            icon: "checkmark",
                                            backgroundColor: AppColors.success
                                        ) {
                                            saveProfile()
                                        }
                                        .disabled(isLoading)
                                    }
                                }
                            }
                        }
                        
                        // Attendance Stats
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Attendance Summary")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                    StatCard(
                                        title: "This Month",
                                        value: "22 days",
                                        icon: "calendar",
                                        color: AppColors.primary
                                    )
                                    
                                    StatCard(
                                        title: "On Time",
                                        value: "95%",
                                        icon: "clock",
                                        color: AppColors.success
                                    )
                                    
                                    StatCard(
                                        title: "Total Hours",
                                        value: "176 hrs",
                                        icon: "timer",
                                        color: AppColors.info
                                    )
                                    
                                    StatCard(
                                        title: "Streak",
                                        value: "12 days",
                                        icon: "flame",
                                        color: AppColors.warning
                                    )
                                }
                            }
                        }
                        
                        // Account Settings
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Account Settings")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    SettingsActionRow(
                                        title: "Change Password",
                                        icon: "key",
                                        action: { }
                                    )
                                    
                                    SettingsActionRow(
                                        title: "Notification Settings",
                                        icon: "bell",
                                        action: { }
                                    )
                                    
                                    SettingsActionRow(
                                        title: "Privacy Settings",
                                        icon: "shield",
                                        action: { }
                                    )
                                    
                                    SettingsActionRow(
                                        title: "Export My Data",
                                        icon: "square.and.arrow.up",
                                        action: { }
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserData()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                selectedImage: $profileImage,
                sourceType: imageSource
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadUserData() {
        guard let user = authService.currentUser else { return }
        
        displayName = user.displayName
        email = user.email
        department = user.department ?? ""
        phoneNumber = user.phoneNumber ?? ""
        bio = user.bio ?? ""
        
        // Load profile image if available
        if let imageURL = user.profileImageURL {
            loadImageFromURL(imageURL)
        }
    }
    
    private func loadImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        profileImage = image
                    }
                }
            } catch {
                print("Error loading profile image: \(error)")
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            do {
                // In a real app, you would update the user profile in Firebase
                // For now, we'll simulate the save operation
                
                // Upload profile image if changed
                if let image = profileImage {
                    // Upload image to Firebase Storage
                    // let imageURL = try await uploadProfileImage(image)
                }
                
                // Update user profile
                let updatedUser = User(
                    id: authService.currentUser?.id,
                    email: email,
                    displayName: displayName,
                    role: authService.currentUser?.role ?? .student,
                    department: department.isEmpty ? nil : department,
                    phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                    bio: bio.isEmpty ? nil : bio,
                    profileImageURL: authService.currentUser?.profileImageURL
                )
                
                // Simulate API delay
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isLoading = false
                    isEditing = false
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

// MARK: - Profile Image Section
struct ProfileImageSection: View {
    @Binding var profileImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var imageSource: UIImagePickerController.SourceType
    let isEditing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.white.opacity(0.7))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                }
                
                if isEditing {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Circle()
                                    .fill(AppColors.primary)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                            }
                            .offset(x: -10, y: -10)
                        }
                    }
                }
            }
            .frame(width: 120, height: 120)
            
            if isEditing {
                HStack(spacing: 16) {
                    Button("Camera") {
                        imageSource = .camera
                        showingImagePicker = true
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
                    
                    Button("Gallery") {
                        imageSource = .photoLibrary
                        showingImagePicker = true
                    }
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Profile Info Row
struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Action Row
struct SettingsActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTypography.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(AppTypography.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
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

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct ProfileManagementView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileManagementView()
            .environmentObject(AuthService.shared)
    }
} 