import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    @Published var currentLocation: CLLocation?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var geofenceRegions: [CLCircularRegion] = []
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
        loadGeofenceRegions()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // 10 meters
    }
    
    // MARK: - Location Permission
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Show alert to go to settings
            errorMessage = "Location access is denied. Please enable it in Settings."
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    // MARK: - Geofencing
    func setupGeofenceRegions() {
        // Define office locations - in a real app, these would come from a server
        let officeRegions = [
            GeofenceRegion(
                identifier: "main_office",
                name: "Main Office",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 100.0, // 100 meters
                allowedMethods: [.location, .qr, .face]
            ),
            GeofenceRegion(
                identifier: "branch_office",
                name: "Branch Office",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
                radius: 150.0, // 150 meters
                allowedMethods: [.location, .qr]
            )
        ]
        
        // Clear existing regions
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Add new regions
        for officeRegion in officeRegions {
            let region = CLCircularRegion(
                center: officeRegion.coordinate,
                radius: officeRegion.radius,
                identifier: officeRegion.identifier
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            
            locationManager.startMonitoring(for: region)
            geofenceRegions.append(region)
        }
    }
    
    func isLocationValidForAttendance(location: CLLocation) -> Bool {
        for region in geofenceRegions {
            if region.contains(location.coordinate) {
                return true
            }
        }
        return false
    }
    
    func getNearestOfficeLocation(from location: CLLocation) -> GeofenceRegion? {
        let officeRegions = getOfficeRegions()
        
        var nearestRegion: GeofenceRegion?
        var shortestDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        for region in officeRegions {
            let regionLocation = CLLocation(latitude: region.coordinate.latitude, longitude: region.coordinate.longitude)
            let distance = location.distance(from: regionLocation)
            
            if distance < shortestDistance {
                shortestDistance = distance
                nearestRegion = region
            }
        }
        
        return nearestRegion
    }
    
    func getOfficeRegions() -> [GeofenceRegion] {
        return [
            GeofenceRegion(
                identifier: "main_office",
                name: "Main Office",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                radius: 100.0,
                allowedMethods: [.location, .qr, .face]
            ),
            GeofenceRegion(
                identifier: "branch_office",
                name: "Branch Office",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294),
                radius: 150.0,
                allowedMethods: [.location, .qr]
            )
        ]
    }
    
    // MARK: - Location-based Attendance
    func checkInWithLocation() async throws {
        guard let location = currentLocation else {
            throw LocationError.locationNotAvailable
        }
        
        guard isLocationValidForAttendance(location: location) else {
            throw LocationError.outsideAllowedArea
        }
        
        let attendanceLocation = AttendanceLocation(
            coordinate: location.coordinate,
            address: await getAddress(from: location),
            accuracy: location.horizontalAccuracy
        )
        
        try await AttendanceService.shared.checkIn(
            method: .location,
            location: attendanceLocation
        )
    }
    
    func checkOutWithLocation() async throws {
        guard let location = currentLocation else {
            throw LocationError.locationNotAvailable
        }
        
        let attendanceLocation = AttendanceLocation(
            coordinate: location.coordinate,
            address: await getAddress(from: location),
            accuracy: location.horizontalAccuracy
        )
        
        try await AttendanceService.shared.checkOut(
            method: .location,
            location: attendanceLocation
        )
    }
    
    // MARK: - Geocoding
    func getAddress(from location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                var addressComponents: [String] = []
                
                if let streetNumber = placemark.subThoroughfare {
                    addressComponents.append(streetNumber)
                }
                
                if let streetName = placemark.thoroughfare {
                    addressComponents.append(streetName)
                }
                
                if let city = placemark.locality {
                    addressComponents.append(city)
                }
                
                if let state = placemark.administrativeArea {
                    addressComponents.append(state)
                }
                
                return addressComponents.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        return nil
    }
    
    func getCoordinates(from address: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch {
            print("Geocoding error: \(error)")
            return nil
        }
    }
    
    // MARK: - Distance Calculations
    func calculateDistance(from startLocation: CLLocation, to endLocation: CLLocation) -> CLLocationDistance {
        return startLocation.distance(from: endLocation)
    }
    
    func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        
        if distance < 1000 {
            return "\(formatter.string(from: NSNumber(value: distance)) ?? "0") m"
        } else {
            let kilometers = distance / 1000
            return "\(formatter.string(from: NSNumber(value: kilometers)) ?? "0") km"
        }
    }
    
    // MARK: - Utility Functions
    private func loadGeofenceRegions() {
        // Load saved geofence regions from UserDefaults or server
        // For now, we'll set up default regions
        setupGeofenceRegions()
    }
    
    func getCurrentLocationString() -> String {
        guard let location = currentLocation else {
            return "Location not available"
        }
        
        return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
    
    func getLocationAccuracyString() -> String {
        guard let location = currentLocation else {
            return "Unknown"
        }
        
        let accuracy = location.horizontalAccuracy
        
        if accuracy < 0 {
            return "Invalid"
        } else if accuracy < 5 {
            return "Excellent"
        } else if accuracy < 10 {
            return "Good"
        } else if accuracy < 20 {
            return "Fair"
        } else {
                    return "Poor"
    }
    
    func initialize() {
        // Initialize the service
        print("LocationService initialized")
    }
}
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Check if user is entering or exiting geofence
        for region in geofenceRegions {
            if region.contains(location.coordinate) {
                handleGeofenceEntry(region: region)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = error.localizedDescription
        print("Location manager error: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationPermissionStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            errorMessage = "Location access is required for location-based attendance"
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        // Send notification about entering office area
        Task {
            await NotificationService.shared.sendLocationNotification(
                title: "Office Area Detected",
                message: "You're near the office. Would you like to check in?"
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        
        // Send notification about leaving office area
        Task {
            await NotificationService.shared.sendLocationNotification(
                title: "Left Office Area",
                message: "Don't forget to check out if you haven't already."
            )
        }
    }
    
    private func handleGeofenceEntry(region: CLCircularRegion) {
        // Handle logic when user enters a geofence
        print("User entered geofence: \(region.identifier)")
    }
}

// MARK: - Supporting Models
struct GeofenceRegion {
    let identifier: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let allowedMethods: [AttendanceMethod]
    
    var region: CLCircularRegion {
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case locationNotAvailable
    case permissionDenied
    case outsideAllowedArea
    case accuracyTooLow
    case geofenceNotSetup
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "Location is not available"
        case .permissionDenied:
            return "Location permission is denied"
        case .outsideAllowedArea:
            return "You are outside the allowed area for check-in"
        case .accuracyTooLow:
            return "Location accuracy is too low"
        case .geofenceNotSetup:
            return "Geofence is not properly configured"
        case .networkError:
            return "Network error occurred while processing location"
        }
    }
} 