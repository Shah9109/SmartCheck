import SwiftUI
import FirebaseFirestore

struct UserManagementView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var users: [User] = []
    @State private var filteredUsers: [User] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedDepartment = "All"
    @State private var selectedRole = "All"
    @State private var showingAddUser = false
    @State private var editingUser: User?
    
    private let departments = ["All", "Engineering", "Marketing", "Design", "Sales", "HR", "Management"]
    private let roles = ["All", "Student", "Employee", "Manager", "Admin"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    UserManagementHeader(
                        searchText: $searchText,
                        selectedDepartment: $selectedDepartment,
                        selectedRole: $selectedRole,
                        departments: departments,
                        roles: roles,
                        showingAddUser: $showingAddUser
                    )
                    .padding()
                    
                    // User List
                    if isLoading {
                        Spacer()
                        HStack(spacing: 12) {
                            LoadingIndicator()
                            Text("Loading users...")
                                .font(AppTypography.body)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredUsers) { user in
                                    UserCard(user: user) {
                                        editingUser = user
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingAddUser) {
            AddUserView()
                .environmentObject(authService)
                .onDisappear {
                    loadUsers()
                }
        }
        .sheet(item: $editingUser) { user in
            EditUserView(user: user)
                .environmentObject(authService)
                .onDisappear {
                    loadUsers()
                }
        }
        .onAppear {
            loadUsers()
        }
        .onChange(of: searchText) { _ in
            filterUsers()
        }
        .onChange(of: selectedDepartment) { _ in
            filterUsers()
        }
        .onChange(of: selectedRole) { _ in
            filterUsers()
        }
    }
    
    private func loadUsers() {
        isLoading = true
        Task {
            do {
                let snapshot = try await Firestore.firestore().collection("users").getDocuments()
                let loadedUsers = snapshot.documents.compactMap { document in
                    try? document.data(as: User.self)
                }
                
                await MainActor.run {
                    users = loadedUsers
                    filterUsers()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error loading users: \(error)")
            }
        }
    }
    
    private func filterUsers() {
        filteredUsers = users.filter { user in
            let matchesSearch = searchText.isEmpty || 
                user.displayName.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText) ||
                (user.department?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesDepartment = selectedDepartment == "All" || 
                user.department == selectedDepartment
            
            let matchesRole = selectedRole == "All" || 
                user.role.displayName == selectedRole
            
            return matchesSearch && matchesDepartment && matchesRole
        }
    }
}

// MARK: - User Management Header
struct UserManagementHeader: View {
    @Binding var searchText: String
    @Binding var selectedDepartment: String
    @Binding var selectedRole: String
    let departments: [String]
    let roles: [String]
    @Binding var showingAddUser: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("User Management")
                    .font(AppTypography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                AnimatedButton(
                    title: "Add User",
                    icon: "person.badge.plus",
                    backgroundColor: AppColors.success
                ) {
                    showingAddUser = true
                }
            }
            
            // Search Bar
            CustomTextField(
                title: "",
                placeholder: "Search users...",
                icon: "magnifyingglass",
                text: $searchText
            )
            
            // Filters
            HStack(spacing: 16) {
                FilterPicker(
                    title: "Department",
                    selection: $selectedDepartment,
                    options: departments
                )
                
                FilterPicker(
                    title: "Role",
                    selection: $selectedRole,
                    options: roles
                )
            }
        }
    }
}

// MARK: - Filter Picker
struct FilterPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        selection = option
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(AppTypography.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - User Card
struct UserCard: View {
    let user: User
    let onEdit: () -> Void
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Profile Image
                AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                    
                    Text(user.email)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        StatusBadge(
                            text: user.role.displayName,
                            status: .approved
                        )
                        
                        if let department = user.department {
                            Text(department)
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primary)
                    }
                    
                    Circle()
                        .fill(user.isActive ? AppColors.success : AppColors.error)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Add User View
struct AddUserView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var displayName = ""
    @State private var department = ""
    @State private var selectedRole = UserRole.student
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Full Name",
                                placeholder: "Enter full name",
                                icon: "person",
                                text: $displayName
                            )
                            
                            CustomTextField(
                                title: "Email",
                                placeholder: "Enter email address",
                                icon: "envelope",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            
                            CustomTextField(
                                title: "Department",
                                placeholder: "Enter department",
                                icon: "building.2",
                                text: $department
                            )
                            
                            // Role Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Role")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Menu {
                                    ForEach(UserRole.allCases, id: \.self) { role in
                                        Button(role.displayName) {
                                            selectedRole = role
                                        }
                                    }
                                } label: {
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
                        }
                        
                        AnimatedButton(
                            title: isLoading ? "Creating..." : "Create User",
                            icon: isLoading ? nil : "person.badge.plus",
                            backgroundColor: AppColors.success
                        ) {
                            createUser()
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add User")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && !displayName.isEmpty && !department.isEmpty
    }
    
    private func createUser() {
        isLoading = true
        Task {
            do {
                // In a real app, you would create the user account and then add to Firestore
                // For now, we'll simulate user creation
                let newUser = User(
                    email: email,
                    displayName: displayName,
                    role: selectedRole,
                    department: department
                )
                
                // Simulate API delay
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
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

// MARK: - Edit User View
struct EditUserView: View {
    let user: User
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var displayName: String
    @State private var department: String
    @State private var selectedRole: UserRole
    @State private var isActive: Bool
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(user: User) {
        self.user = user
        _displayName = State(initialValue: user.displayName)
        _department = State(initialValue: user.department ?? "")
        _selectedRole = State(initialValue: user.role)
        _isActive = State(initialValue: user.isActive)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image
                        VStack(spacing: 16) {
                            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            
                            Text(user.email)
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        VStack(spacing: 16) {
                            CustomTextField(
                                title: "Full Name",
                                placeholder: "Enter full name",
                                icon: "person",
                                text: $displayName
                            )
                            
                            CustomTextField(
                                title: "Department",
                                placeholder: "Enter department",
                                icon: "building.2",
                                text: $department
                            )
                            
                            // Role Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Role")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Menu {
                                    ForEach(UserRole.allCases, id: \.self) { role in
                                        Button(role.displayName) {
                                            selectedRole = role
                                        }
                                    }
                                } label: {
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
                            
                            // Active Status Toggle
                            HStack {
                                Text("Active Status")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                                
                                Toggle("", isOn: $isActive)
                                    .toggleStyle(SwitchToggleStyle(tint: AppColors.success))
                            }
                        }
                        
                        AnimatedButton(
                            title: isLoading ? "Updating..." : "Update User",
                            icon: isLoading ? nil : "checkmark",
                            backgroundColor: AppColors.primary
                        ) {
                            updateUser()
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit User")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !displayName.isEmpty && !department.isEmpty
    }
    
    private func updateUser() {
        isLoading = true
        Task {
            do {
                // In a real app, you would update the user in Firebase
                // For now, we'll simulate the update
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
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

// MARK: - Preview
struct UserManagementView_Previews: PreviewProvider {
    static var previews: some View {
        UserManagementView()
            .environmentObject(AuthService.shared)
    }
} 