# SmartCheck - Comprehensive Attendance Tracking App

A feature-rich iOS attendance tracking application built with SwiftUI and Firebase, supporting multiple attendance methods including QR codes, face recognition, location-based tracking, and biometric authentication.

## 🚀 Features

### Core Functionality
- **Multi-Method Attendance**: QR Code scanning, Face Recognition, Location-based, Biometric, and Manual entry
- **Real-time Synchronization**: Firebase Firestore for instant data updates
- **Role-Based Access**: Student, Employee, Manager, and Admin roles with different permissions
- **Beautiful UI**: Modern glassmorphism design with smooth animations
- **Comprehensive Analytics**: Real-time attendance statistics and reporting

### Advanced Features
- **Admin Dashboard**: User management, QR code generation, analytics, and data export
- **Profile Management**: Image upload, personal information, and attendance history
- **Data Export**: CSV, Excel, PDF, and JSON export formats
- **Settings & Themes**: Theme customization, language selection, and privacy settings
- **Push Notifications**: Attendance reminders and real-time updates
- **Offline Support**: Local data storage with sync when connection is restored

## 📋 Prerequisites

Before setting up the project, ensure you have:

- Xcode 15.0 or later
- iOS 16.0 or later
- Swift 5.9 or later
- Firebase account
- Apple Developer Account (for device testing)

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/SmartCheck.git
cd SmartCheck
```

### 2. Install Dependencies

The project uses Swift Package Manager. Dependencies will be automatically resolved when you open the project in Xcode.

### 3. Firebase Setup

#### A. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enable Google Analytics (optional but recommended)

#### B. Add iOS App to Firebase
1. Click "Add app" and select iOS
2. Register your app with bundle ID: `com.yourcompany.SmartCheck`
3. Download `GoogleService-Info.plist`
4. Add the file to your Xcode project root

#### C. Enable Firebase Services

**Authentication:**
```bash
# Enable Email/Password authentication
1. Go to Authentication > Sign-in method
2. Enable "Email/Password"
3. Configure authorized domains if needed
```

**Firestore Database:**
```bash
# Create Firestore database
1. Go to Firestore Database
2. Click "Create database"
3. Start in test mode (we'll add security rules later)
4. Choose your preferred location
```

**Storage:**
```bash
# Enable Cloud Storage
1. Go to Storage
2. Click "Get started"
3. Start in test mode
4. Choose your preferred location
```

**Cloud Functions (Optional):**
```bash
# For advanced features like notifications
1. Go to Functions
2. Click "Get started"
3. Follow the setup instructions
```

### 4. Configure Firebase Security Rules

#### Firestore Security Rules
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Attendance records
    match /attendance/{attendanceId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager']);
    }
    
    // QR Sessions - only admins can create
    match /qr_sessions/{sessionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
    
    // Analytics - only admins can read
    match /analytics/{document=**} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
  }
}
```

#### Storage Security Rules
```javascript
// Storage Security Rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile images
    match /profile_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // QR codes - readable by authenticated users
    match /qr_codes/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'manager'];
    }
  }
}
```

### 5. Environment Configuration

#### A. Update Firebase Configuration
Replace the placeholder `GoogleService-Info.plist` with your actual Firebase configuration file.

#### B. Configure App Transport Security
Add to `Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 6. API Keys and External Services

#### A. Google Places API (for location services)
```swift
// Add to AppDelegate or SceneDelegate
import GooglePlaces

// In application(_:didFinishLaunchingWithOptions:)
GMSPlacesClient.provideAPIKey("YOUR_GOOGLE_PLACES_API_KEY")
```

#### B. Push Notifications Setup
```swift
// Add to App delegate
import UserNotifications

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Configure Firebase
    FirebaseApp.configure()
    
    // Configure notifications
    UNUserNotificationCenter.current().delegate = self
    
    return true
}
```

### 7. Xcode Project Configuration

#### A. Add Capabilities
1. Open project settings
2. Select your target
3. Go to "Signing & Capabilities"
4. Add the following capabilities:
   - Push Notifications
   - Background Modes (Background fetch)
   - Keychain Sharing (for biometric auth)

#### B. Configure Bundle Identifier
Ensure your bundle identifier matches your Firebase configuration.

#### C. Add Privacy Descriptions
Add these to `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes and capture face recognition photos.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to verify attendance at specific locations.</string>

<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure biometric authentication.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app may use microphone for enhanced security features.</string>
```

## 🔍 Debugging Guide

### Common Issues and Solutions

#### 1. Firebase Connection Issues
```bash
# Check if GoogleService-Info.plist is properly added
# Verify bundle identifier matches Firebase configuration
# Check internet connectivity
# Ensure Firebase services are enabled in console
```

**Debug Steps:**
1. Check Xcode console for Firebase initialization messages
2. Verify `GoogleService-Info.plist` is in project bundle
3. Test with Firebase console debug view
4. Check network connectivity

#### 2. QR Code Scanning Issues
```swift
// Common issues:
// - Camera permission not granted
// - QR code format not supported
// - Poor lighting conditions
// - Camera not working in simulator

// Debug code:
func debugQRScanning() {
    print("Camera permission: \(AVCaptureDevice.authorizationStatus(for: .video))")
    print("QR session active: \(qrSession?.isRunning ?? false)")
}
```

#### 3. Face Recognition Problems
```swift
// Common issues:
// - Vision framework not available
// - Poor image quality
// - Multiple faces detected
// - Insufficient lighting

// Debug code:
func debugFaceRecognition() {
    print("Vision available: \(VNDetectFaceRectanglesRequest.isSupported)")
    print("Face quality threshold: \(faceQualityThreshold)")
}
```

#### 4. Location Services Issues
```swift
// Common issues:
// - Location permission denied
// - GPS not accurate
// - Geofencing not working
// - Background location not updating

// Debug code:
func debugLocationServices() {
    print("Location permission: \(CLLocationManager.authorizationStatus())")
    print("Location accuracy: \(locationManager.location?.horizontalAccuracy ?? 0)")
}
```

#### 5. Push Notifications Not Working
```swift
// Common issues:
// - Notification permission not granted
// - APNs certificate issues
// - Firebase messaging not configured
// - App in background mode

// Debug code:
func debugNotifications() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification authorization: \(settings.authorizationStatus)")
    }
}
```

### Testing Checklist

#### Pre-Launch Testing
- [ ] Authentication flow (signup, login, logout)
- [ ] All attendance methods working
- [ ] QR code generation and scanning
- [ ] Face recognition accuracy
- [ ] Location-based attendance
- [ ] Biometric authentication
- [ ] Data synchronization
- [ ] Offline functionality
- [ ] Push notifications
- [ ] Admin panel features
- [ ] Data export functionality
- [ ] Profile management
- [ ] Settings and preferences

#### Device Testing
- [ ] Test on physical device (not simulator)
- [ ] Test different iOS versions
- [ ] Test on different screen sizes
- [ ] Test with poor network conditions
- [ ] Test battery optimization
- [ ] Test memory usage
- [ ] Test app backgrounding

### Performance Optimization

#### Firebase Optimization
```swift
// Optimize Firestore queries
func optimizeFirestoreQueries() {
    // Use compound indexes for complex queries
    // Implement pagination for large datasets
    // Cache frequently accessed data
    // Use offline persistence
}
```

#### Image Optimization
```swift
// Optimize image handling
func optimizeImages() {
    // Compress images before upload
    // Use appropriate image formats
    // Implement lazy loading
    // Cache images locally
}
```

#### Battery Optimization
```swift
// Optimize battery usage
func optimizeBattery() {
    // Minimize background location updates
    // Use efficient Core Data operations
    // Implement smart sync strategies
    // Optimize network calls
}
```

### Deployment Guide

#### 1. Pre-Deployment Checklist
- [ ] All features tested and working
- [ ] Firebase security rules implemented
- [ ] App icons and launch screens added
- [ ] Privacy policy and terms of service
- [ ] App Store Connect configured
- [ ] Certificates and provisioning profiles
- [ ] App Store metadata and screenshots

#### 2. App Store Submission
```bash
# Build for release
1. Set build configuration to Release
2. Archive the project
3. Validate the archive
4. Distribute to App Store Connect
5. Submit for review
```

#### 3. Post-Deployment Monitoring
- Monitor crash reports
- Track user analytics
- Monitor Firebase usage
- Check performance metrics
- Collect user feedback

## 📊 Analytics and Monitoring

### Firebase Analytics Events
```swift
// Track custom events
Analytics.logEvent("attendance_marked", parameters: [
    "method": "qr_code",
    "location": "office",
    "timestamp": Date().timeIntervalSince1970
])
```

### Crashlytics Setup
```swift
// Enable crashlytics
import FirebaseCrashlytics

// Log non-fatal errors
Crashlytics.crashlytics().record(error: error)
```

## 🔐 Security Best Practices

### Data Protection
- Enable App Transport Security
- Use Keychain for sensitive data
- Implement certificate pinning
- Encrypt local data storage
- Regular security audits

### Authentication Security
- Implement strong password policies
- Use biometric authentication
- Enable two-factor authentication
- Regular token refresh
- Session management

### Privacy Compliance
- Implement GDPR compliance
- Data minimization principles
- User consent management
- Data retention policies
- Regular privacy audits

## 🆘 Support and Troubleshooting

### Get Help
- Check GitHub issues
- Review Firebase documentation
- Apple Developer documentation
- Stack Overflow community
- Firebase support channels

### Reporting Issues
When reporting issues, include:
- iOS version and device model
- Xcode version
- Error messages and stack traces
- Steps to reproduce
- Expected vs actual behavior

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Firebase team for excellent backend services
- Apple for SwiftUI framework
- Vision framework for face recognition
- Core Location for location services
- Community contributors and testers

---

**Note**: This is a comprehensive attendance tracking solution. Make sure to comply with your organization's privacy policies and local data protection regulations when implementing attendance tracking features. 