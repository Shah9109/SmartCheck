import SwiftUI
import AVFoundation
import Vision

struct QRCodeScannerView: View {
    @EnvironmentObject var qrService: QRService
    @EnvironmentObject var attendanceService: AttendanceService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingScanner = false
    @State private var scannedCode: String?
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var isSuccess = false
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("QR Code Scanner")
                            .font(AppTypography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Scan a QR code to check in or check out")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Scanner Area
                    GlassCard {
                        VStack(spacing: 20) {
                            if isShowingScanner {
                                QRScannerRepresentable { code in
                                    handleScannedCode(code)
                                }
                                .frame(height: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 60, weight: .light))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("Camera Preview")
                                        .font(AppTypography.headline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .frame(height: 300)
                            }
                            
                            if isProcessing {
                                HStack(spacing: 12) {
                                    LoadingIndicator()
                                    Text("Processing QR Code...")
                                        .font(AppTypography.body)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        AnimatedButton(
                            title: isShowingScanner ? "Stop Scanner" : "Start Scanner",
                            icon: isShowingScanner ? "stop.circle" : "play.circle",
                            backgroundColor: isShowingScanner ? AppColors.error : AppColors.success
                        ) {
                            toggleScanner()
                        }
                        .disabled(isProcessing)
                        
                        if !isShowingScanner {
                            AnimatedButton(
                                title: "Manual Code Entry",
                                icon: "keyboard",
                                backgroundColor: AppColors.secondary
                            ) {
                                showManualEntry()
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .sheet(isPresented: $showingResult) {
            QRResultView(
                message: resultMessage,
                isSuccess: isSuccess
            )
        }
        .onAppear {
            requestCameraPermission()
        }
    }
    
    private func toggleScanner() {
        withAnimation {
            isShowingScanner.toggle()
        }
        HapticFeedback.impact(.medium)
    }
    
    private func handleScannedCode(_ code: String) {
        guard !isProcessing else { return }
        
        isProcessing = true
        scannedCode = code
        HapticFeedback.notification(.success)
        
        Task {
            do {
                let qrData = qrService.parseQRCode(code)
                let session = try await qrService.validateQRCode(qrData?.code ?? code)
                
                // Use QR code for attendance
                let userId = AuthService.shared.getCurrentUserId() ?? ""
                let updatedSession = try await qrService.useQRCode(session.code, userId: userId)
                
                // Record attendance
                try await attendanceService.checkIn(
                    method: .qr,
                    sessionId: updatedSession.id
                )
                
                await MainActor.run {
                    resultMessage = "Successfully checked in using QR code!"
                    isSuccess = true
                    showingResult = true
                    isProcessing = false
                    isShowingScanner = false
                }
                
            } catch {
                await MainActor.run {
                    resultMessage = error.localizedDescription
                    isSuccess = false
                    showingResult = true
                    isProcessing = false
                }
            }
        }
    }
    
    private func showManualEntry() {
        // Show manual QR code entry sheet
        HapticFeedback.selection()
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Camera permission granted")
                } else {
                    print("Camera permission denied")
                }
            }
        }
    }
}

// MARK: - QR Scanner UIViewRepresentable
struct QRScannerRepresentable: UIViewRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIView(context: Context) -> QRScannerUIView {
        let view = QRScannerUIView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: QRScannerUIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func didScanQRCode(_ code: String) {
            onCodeScanned(code)
        }
    }
}

// MARK: - QR Scanner UIView
protocol QRScannerDelegate: AnyObject {
    func didScanQRCode(_ code: String)
}

class QRScannerUIView: UIView {
    weak var delegate: QRScannerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var lastScannedCode: String?
    private var lastScanTime: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get video capture device")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Failed to create video input: \(error)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Failed to add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            print("Failed to add metadata output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    func startScanning() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRScannerUIView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Prevent duplicate scans within 2 seconds
            let now = Date()
            if stringValue == lastScannedCode && now.timeIntervalSince(lastScanTime) < 2.0 {
                return
            }
            
            lastScannedCode = stringValue
            lastScanTime = now
            
            delegate?.didScanQRCode(stringValue)
        }
    }
}

// MARK: - QR Result View
struct QRResultView: View {
    let message: String
    let isSuccess: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(isSuccess ? AppColors.success : AppColors.error)
                    
                    Text(isSuccess ? "Success!" : "Error")
                        .font(AppTypography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(AppTypography.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    AnimatedButton(
                        title: "Done",
                        icon: "checkmark",
                        backgroundColor: AppColors.primary
                    ) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - Preview
struct QRCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerView()
            .environmentObject(QRService.shared)
            .environmentObject(AttendanceService.shared)
    }
} 