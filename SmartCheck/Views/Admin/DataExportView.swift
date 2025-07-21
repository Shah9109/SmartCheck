import SwiftUI
import UniformTypeIdentifiers

struct DataExportView: View {
    @EnvironmentObject var attendanceService: AttendanceService
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFormat = ExportFormat.csv
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var selectedDepartment = "All"
    @State private var selectedRole = "All"
    @State private var selectedMethod = "All"
    @State private var isExporting = false
    @State private var exportProgress = 0.0
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let departments = ["All", "Engineering", "Marketing", "Design", "Sales", "HR", "Management"]
    private let roles = ["All", "Student", "Employee", "Manager", "Admin"]
    private let methods = ["All", "QR Code", "Face Recognition", "Location", "Biometric", "Manual"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Export Format Selection
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Export Format")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(ExportFormat.allCases, id: \.self) { format in
                                        FormatSelectionCard(
                                            format: format,
                                            isSelected: selectedFormat == format
                                        ) {
                                            selectedFormat = format
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Date Range Selection
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Date Range")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .colorScheme(.dark)
                                    
                                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .colorScheme(.dark)
                                }
                                
                                HStack(spacing: 8) {
                                    QuickDateButton(title: "Last 7 Days") {
                                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                                        endDate = Date()
                                    }
                                    
                                    QuickDateButton(title: "Last 30 Days") {
                                        startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                                        endDate = Date()
                                    }
                                    
                                    QuickDateButton(title: "This Month") {
                                        let calendar = Calendar.current
                                        let now = Date()
                                        startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
                                        endDate = now
                                    }
                                }
                            }
                        }
                        
                        // Filters
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Filters")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    FilterRow(title: "Department", selection: $selectedDepartment, options: departments)
                                    FilterRow(title: "Role", selection: $selectedRole, options: roles)
                                    FilterRow(title: "Method", selection: $selectedMethod, options: methods)
                                }
                            }
                        }
                        
                        // Export Summary
                        GlassCard {
                            VStack(spacing: 16) {
                                Text("Export Summary")
                                    .font(AppTypography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 8) {
                                    SummaryRow(title: "Format", value: selectedFormat.displayName)
                                    SummaryRow(title: "Date Range", value: "\(startDate.formatted(date: .abbreviated, time: .omitted)) - \(endDate.formatted(date: .abbreviated, time: .omitted))")
                                    SummaryRow(title: "Department", value: selectedDepartment)
                                    SummaryRow(title: "Role", value: selectedRole)
                                    SummaryRow(title: "Method", value: selectedMethod)
                                }
                            }
                        }
                        
                        // Export Button
                        if isExporting {
                            GlassCard {
                                VStack(spacing: 16) {
                                    Text("Exporting Data...")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white)
                                    
                                    ProgressView(value: exportProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                    
                                    Text("\(Int(exportProgress * 100))% Complete")
                                        .font(AppTypography.body)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        } else {
                            AnimatedButton(
                                title: "Export Data",
                                icon: "square.and.arrow.up",
                                backgroundColor: AppColors.success
                            ) {
                                exportData()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Data Export")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func exportData() {
        isExporting = true
        exportProgress = 0.0
        
        Task {
            do {
                // Simulate export progress
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    await MainActor.run {
                        exportProgress = Double(i) / 10.0
                    }
                }
                
                // Create export parameters
                let parameters = ExportParameters(
                    format: selectedFormat,
                    startDate: startDate,
                    endDate: endDate,
                    department: selectedDepartment == "All" ? nil : selectedDepartment,
                    role: selectedRole == "All" ? nil : selectedRole,
                    method: selectedMethod == "All" ? nil : selectedMethod
                )
                
                // Export data
                let fileURL = try await attendanceService.exportAttendanceData(parameters: parameters)
                
                await MainActor.run {
                    isExporting = false
                    exportedFileURL = fileURL
                    showingShareSheet = true
                }
                
                HapticFeedback.notification(.success)
                
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportProgress = 0.0
                    errorMessage = error.localizedDescription
                    showingError = true
                }
                
                HapticFeedback.notification(.error)
            }
        }
    }
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case excel = "xlsx"
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
    
    var icon: String {
        switch self {
        case .csv: return "doc.text"
        case .excel: return "tablecells"
        case .pdf: return "doc.richtext"
        case .json: return "curlybraces"
        }
    }
    
    var description: String {
        switch self {
        case .csv: return "Comma-separated values"
        case .excel: return "Excel spreadsheet"
        case .pdf: return "PDF document"
        case .json: return "JSON data format"
        }
    }
}

// MARK: - Export Parameters
struct ExportParameters {
    let format: ExportFormat
    let startDate: Date
    let endDate: Date
    let department: String?
    let role: String?
    let method: String?
}

// MARK: - Format Selection Card
struct FormatSelectionCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            onSelect()
        }) {
            VStack(spacing: 12) {
                Image(systemName: format.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.primary : .white.opacity(0.7))
                
                Text(format.displayName)
                    .font(AppTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(format.description)
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppColors.primary.opacity(0.2) : Color.white.opacity(0.05))
                    .stroke(isSelected ? AppColors.primary : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Date Button
struct QuickDateButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(.light)
            action()
        }) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Row
struct FilterRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
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

// MARK: - Summary Row
struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Chart Bar Component
struct ChartBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(height: CGFloat(value / maxValue) * 100)
                    .frame(maxHeight: 100)
                
                Text("\(Int(value))")
                    .font(AppTypography.caption)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview
struct DataExportView_Previews: PreviewProvider {
    static var previews: some View {
        DataExportView()
            .environmentObject(AttendanceService.shared)
    }
} 