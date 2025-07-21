import Foundation
import Vision
import UIKit
import CoreML

@MainActor
class FaceRecognitionService: ObservableObject {
    static let shared = FaceRecognitionService()
    
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var recognitionResult: FaceRecognitionResult?
    
    private var faceDetectionRequest: VNDetectFaceRectanglesRequest?
    private var faceRecognitionRequest: VNRecognizeAnimalsRequest?
    
    init() {
        setupFaceDetection()
    }
    
    private func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            if let error = error {
                print("Face detection error: \(error)")
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation] else {
                return
            }
            
            Task { @MainActor in
                self?.processFaceDetectionResults(observations)
            }
        }
    }
    
    // MARK: - Face Detection
    func detectFace(in image: UIImage) async -> FaceRecognitionResult {
        isProcessing = true
        errorMessage = nil
        
        guard let cgImage = image.cgImage else {
            let result = FaceRecognitionResult(
                isSuccessful: false,
                confidence: 0.0,
                message: "Invalid image format",
                detectedFaces: 0,
                faceQuality: .poor
            )
            isProcessing = false
            return result
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        
        do {
            guard let request = faceDetectionRequest else {
                throw FaceRecognitionError.detectionSetupFailed
            }
            
            try handler.perform([request])
            
            // Wait for processing to complete
            while isProcessing {
                await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            return recognitionResult ?? FaceRecognitionResult(
                isSuccessful: false,
                confidence: 0.0,
                message: "Face detection failed",
                detectedFaces: 0,
                faceQuality: .poor
            )
            
        } catch {
            let result = FaceRecognitionResult(
                isSuccessful: false,
                confidence: 0.0,
                message: error.localizedDescription,
                detectedFaces: 0,
                faceQuality: .poor
            )
            isProcessing = false
            return result
        }
    }
    
    private func processFaceDetectionResults(_ observations: [VNFaceObservation]) {
        let faceCount = observations.count
        
        if faceCount == 0 {
            recognitionResult = FaceRecognitionResult(
                isSuccessful: false,
                confidence: 0.0,
                message: "No face detected",
                detectedFaces: 0,
                faceQuality: .poor
            )
        } else if faceCount > 1 {
            recognitionResult = FaceRecognitionResult(
                isSuccessful: false,
                confidence: 0.0,
                message: "Multiple faces detected. Please ensure only one face is visible.",
                detectedFaces: faceCount,
                faceQuality: .poor
            )
        } else {
            // Single face detected
            let face = observations[0]
            let quality = evaluateFaceQuality(face)
            let confidence = Double(face.confidence)
            
            recognitionResult = FaceRecognitionResult(
                isSuccessful: confidence > 0.7 && quality != .poor,
                confidence: confidence,
                message: getFaceQualityMessage(quality),
                detectedFaces: 1,
                faceQuality: quality
            )
        }
        
        isProcessing = false
    }
    
    // MARK: - Face Quality Evaluation
    private func evaluateFaceQuality(_ face: VNFaceObservation) -> FaceQuality {
        let confidence = face.confidence
        let boundingBox = face.boundingBox
        
        // Check if face is too small
        let faceSize = boundingBox.width * boundingBox.height
        if faceSize < 0.05 { // Face is less than 5% of image
            return .poor
        }
        
        // Check if face is too large (too close)
        if faceSize > 0.8 { // Face is more than 80% of image
            return .poor
        }
        
        // Check confidence level
        if confidence < 0.5 {
            return .poor
        } else if confidence < 0.7 {
            return .fair
        } else if confidence < 0.85 {
            return .good
        } else {
            return .excellent
        }
    }
    
    private func getFaceQualityMessage(_ quality: FaceQuality) -> String {
        switch quality {
        case .poor:
            return "Poor image quality. Please improve lighting and ensure face is clearly visible."
        case .fair:
            return "Fair image quality. Consider improving lighting for better results."
        case .good:
            return "Good image quality. Face detected successfully."
        case .excellent:
            return "Excellent image quality. Face detected with high confidence."
        }
    }
    
    // MARK: - Face Recognition for Attendance
    func recognizeFaceForAttendance(image: UIImage) async throws -> Bool {
        let result = await detectFace(in: image)
        
        guard result.isSuccessful else {
            throw FaceRecognitionError.faceDetectionFailed(result.message)
        }
        
        // In a real app, you would:
        // 1. Extract face features/embeddings
        // 2. Compare with stored face templates
        // 3. Determine if it's a match
        
        // For demo purposes, we'll simulate face recognition
        let isRecognized = simulateFaceRecognition(result)
        
        if isRecognized {
            // Process attendance
            try await AttendanceService.shared.checkIn(
                method: .face,
                notes: "Face recognition - \(result.confidence) confidence"
            )
            
            return true
        } else {
            throw FaceRecognitionError.faceNotRecognized
        }
    }
    
    private func simulateFaceRecognition(_ result: FaceRecognitionResult) -> Bool {
        // Simulate face recognition process
        // In a real app, this would use machine learning models
        return result.confidence > 0.75 && result.faceQuality != .poor
    }
    
    // MARK: - Face Registration
    func registerFace(image: UIImage, userId: String) async throws -> FaceTemplate {
        let result = await detectFace(in: image)
        
        guard result.isSuccessful else {
            throw FaceRecognitionError.faceDetectionFailed(result.message)
        }
        
        guard result.faceQuality == .good || result.faceQuality == .excellent else {
            throw FaceRecognitionError.poorImageQuality
        }
        
        // In a real app, you would:
        // 1. Extract face features/embeddings
        // 2. Create a face template
        // 3. Store in secure database
        
        let template = FaceTemplate(
            id: UUID().uuidString,
            userId: userId,
            features: extractFaceFeatures(from: image),
            confidence: result.confidence,
            quality: result.faceQuality,
            createdAt: Date()
        )
        
        try await saveFaceTemplate(template)
        
        return template
    }
    
    private func extractFaceFeatures(from image: UIImage) -> [Double] {
        // Simulate face feature extraction
        // In a real app, this would use Core ML or Vision framework
        return Array(0..<128).map { _ in Double.random(in: 0...1) }
    }
    
    private func saveFaceTemplate(_ template: FaceTemplate) async throws {
        // In a real app, you would save this to Firebase or secure storage
        // For now, we'll just simulate the save
        print("Saving face template for user: \(template.userId)")
    }
    
    // MARK: - Utility Functions
    func getFaceRecognitionTips() -> [String] {
        return [
            "Ensure good lighting on your face",
            "Look directly at the camera",
            "Remove glasses if possible",
            "Keep your face within the frame",
            "Avoid extreme expressions",
            "Ensure background is not too busy"
        ]
    }
    
    func validateImageForFaceRecognition(_ image: UIImage) -> ValidationResult {
        guard let cgImage = image.cgImage else {
            return ValidationResult(isValid: false, message: "Invalid image format")
        }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let minSize: CGFloat = 200
        
        if imageSize.width < minSize || imageSize.height < minSize {
            return ValidationResult(isValid: false, message: "Image resolution too low. Minimum 200x200 pixels required.")
        }
        
        // Check if image is too large
        let maxSize: CGFloat = 4000
        if imageSize.width > maxSize || imageSize.height > maxSize {
            return ValidationResult(isValid: false, message: "Image resolution too high. Maximum 4000x4000 pixels supported.")
        }
        
        return ValidationResult(isValid: true, message: "Image is valid for face recognition")
    }
    
    func preprocessImage(_ image: UIImage) -> UIImage? {
        // Resize and optimize image for face recognition
        let targetSize = CGSize(width: 1024, height: 1024)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    
    func initialize() {
        // Initialize the service
        print("FaceRecognitionService initialized")
    }
}

// MARK: - Supporting Models
struct FaceRecognitionResult {
    let isSuccessful: Bool
    let confidence: Double
    let message: String
    let detectedFaces: Int
    let faceQuality: FaceQuality
}

struct FaceTemplate {
    let id: String
    let userId: String
    let features: [Double]
    let confidence: Double
    let quality: FaceQuality
    let createdAt: Date
}

struct ValidationResult {
    let isValid: Bool
    let message: String
}

enum FaceQuality {
    case poor
    case fair
    case good
    case excellent
    
    var displayName: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var color: String {
        switch self {
        case .poor: return "red"
        case .fair: return "orange"
        case .good: return "green"
        case .excellent: return "blue"
        }
    }
}

// MARK: - Face Recognition Errors
enum FaceRecognitionError: LocalizedError {
    case detectionSetupFailed
    case faceDetectionFailed(String)
    case faceNotRecognized
    case poorImageQuality
    case multipleFactesDetected
    case noFaceDetected
    case processingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .detectionSetupFailed:
            return "Failed to setup face detection"
        case .faceDetectionFailed(let message):
            return "Face detection failed: \(message)"
        case .faceNotRecognized:
            return "Face not recognized. Please try again or use alternative check-in method."
        case .poorImageQuality:
            return "Poor image quality. Please improve lighting and image clarity."
        case .multipleFactesDetected:
            return "Multiple faces detected. Please ensure only one face is visible."
        case .noFaceDetected:
            return "No face detected. Please ensure your face is visible in the image."
        case .processingError:
            return "Error processing face recognition"
        case .networkError:
            return "Network error during face recognition"
        }
    }
} 