import SwiftUI
import AVFoundation
import Vision

struct FaceRecognitionView: View {
    @EnvironmentObject var faceService: FaceRecognitionService
    @EnvironmentObject var attendanceService: AttendanceService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = false
    @State private var isProcessing = false
    @State private var recognitionResult: FaceRecognitionResult?
    @State private var showingResult = false
    @State private var showingTips = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "faceid")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("Face Recognition")
                            .font(AppTypography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Use face recognition for secure attendance")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Camera/Image Area
                    GlassCard {
                        VStack(spacing: 20) {
                            if let image = capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Take a photo for face recognition")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 300)
                            }
                            
                            if isProcessing {
                                HStack(spacing: 12) {
                                    LoadingIndicator()
                                    Text("Analyzing face...")
                                        .font(AppTypography.body)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            if let result = recognitionResult {
                                FaceQualityIndicator(result: result)
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            AnimatedButton(
                                title: "Take Photo",
                                icon: "camera",
                                backgroundColor: AppColors.primary
                            ) {
                                takeFacePhoto()
                            }
                            .disabled(isProcessing)
                            
                            if capturedImage != nil {
                                AnimatedButton(
                                    title: "Retake",
                                    icon: "arrow.clockwise",
                                    backgroundColor: AppColors.secondary
                                ) {
                                    retakePhoto()
                                }
                            }
                        }
                        
                        if let result = recognitionResult, result.isSuccessful {
                            AnimatedButton(
                                title: "Check In",
                                icon: "checkmark.circle",
                                backgroundColor: AppColors.success
                            ) {
                                performFaceAttendance()
                            }
                            .disabled(isProcessing)
                        }
                        
                        Button(action: {
                            showingTips = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb")
                                Text("Face Recognition Tips")
                            }
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Help") {
                    showingTips = true
                }
            )
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraView { image in
                handleCapturedImage(image)
            }
        }
        .sheet(isPresented: $showingResult) {
            FaceRecognitionResultView(
                result: recognitionResult,
                onDismiss: {
                    showingResult = false
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .actionSheet(isPresented: $showingTips) {
            ActionSheet(
                title: Text("Face Recognition Tips"),
                message: Text(faceService.getFaceRecognitionTips().joined(separator: "\n• ")),
                buttons: [.cancel(Text("Got it!"))]
            )
        }
    }
    
    private func takeFacePhoto() {
        HapticFeedback.impact(.medium)
        isShowingCamera = true
    }
    
    private func retakePhoto() {
        HapticFeedback.selection()
        capturedImage = nil
        recognitionResult = nil
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        capturedImage = image
        analyzeFace(image)
    }
    
    private func analyzeFace(_ image: UIImage) {
        isProcessing = true
        
        Task {
            let result = await faceService.detectFace(in: image)
            
            await MainActor.run {
                recognitionResult = result
                isProcessing = false
                
                if result.isSuccessful {
                    HapticFeedback.notification(.success)
                } else {
                    HapticFeedback.notification(.warning)
                }
            }
        }
    }
    
    private func performFaceAttendance() {
        guard let image = capturedImage else { return }
        
        isProcessing = true
        
        Task {
            do {
                let success = try await faceService.recognizeFaceForAttendance(image: image)
                
                await MainActor.run {
                    isProcessing = false
                    showingResult = true
                    
                    if success {
                        HapticFeedback.notification(.success)
                    } else {
                        HapticFeedback.notification(.error)
                    }
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Handle error - could show an error result
                    print("Face recognition error: \(error)")
                    HapticFeedback.notification(.error)
                }
            }
        }
    }
}

// MARK: - Face Quality Indicator
struct FaceQualityIndicator: View {
    let result: FaceRecognitionResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(result.isSuccessful ? AppColors.success : AppColors.warning)
                
                Text("Quality: \(result.faceQuality.displayName)")
                    .font(AppTypography.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))%")
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Quality Progress Bar
            ProgressView(value: result.confidence, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: qualityColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(result.message)
                .font(AppTypography.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var qualityColor: Color {
        switch result.faceQuality {
        case .poor:
            return AppColors.error
        case .fair:
            return AppColors.warning
        case .good:
            return AppColors.success
        case .excellent:
            return AppColors.info
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Face Recognition Result View
struct FaceRecognitionResultView: View {
    let result: FaceRecognitionResult?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if let result = result {
                        VStack(spacing: 20) {
                            Image(systemName: result.isSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(result.isSuccessful ? AppColors.success : AppColors.error)
                            
                            Text(result.isSuccessful ? "Attendance Recorded!" : "Recognition Failed")
                                .font(AppTypography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(result.message)
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if result.isSuccessful {
                                VStack(spacing: 8) {
                                    Text("Confidence: \(Int(result.confidence * 100))%")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Quality: \(result.faceQuality.displayName)")
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Time: \(Date().formatted(date: .omitted, time: .shortened))")
                                        .font(AppTypography.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 80, weight: .light))
                                .foregroundColor(AppColors.warning)
                            
                            Text("Processing Error")
                                .font(AppTypography.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("There was an error processing your face recognition request.")
                                .font(AppTypography.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    AnimatedButton(
                        title: "Done",
                        icon: "checkmark",
                        backgroundColor: AppColors.primary
                    ) {
                        onDismiss()
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Close") {
                    onDismiss()
                }
            )
        }
    }
}

// MARK: - Preview
struct FaceRecognitionView_Previews: PreviewProvider {
    static var previews: some View {
        FaceRecognitionView()
            .environmentObject(FaceRecognitionService.shared)
            .environmentObject(AttendanceService.shared)
    }
} 