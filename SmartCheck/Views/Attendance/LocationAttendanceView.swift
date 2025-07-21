import SwiftUI
import MapKit
import CoreLocation

struct LocationAttendanceView: View {
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var attendanceService: AttendanceService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showingCheckInConfirmation = false
    @State private var showingCheckOutConfirmation = false
    @State private var isProcessing = false
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var isSuccess = false
    @State private var nearestOffice: GeofenceRegion?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white)
                        
                        Text("Location Attendance")
                            .font(AppTypography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Check in/out using your location")
                            .font(AppTypography.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // Location Status
                    LocationStatusCard()
                        .padding()
                    
                    // Map View
                    GlassCard {
                        VStack(spacing: 16) {
                            Text("Office Locations")
                                .font(AppTypography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Map(coordinateRegion: $region, annotationItems: locationService.getOfficeRegions()) { office in
                                MapAnnotation(coordinate: office.coordinate) {
                                    OfficeMapMarker(office: office)
                                }
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        if locationService.isLocationEnabled {
                            HStack(spacing: 16) {
                                AnimatedButton(
                                    title: "Check In",
                                    icon: "location.north.circle",
                                    backgroundColor: AppColors.success
                                ) {
                                    checkLocationAndShowConfirmation(isCheckIn: true)
                                }
                                .disabled(isProcessing)
                                
                                AnimatedButton(
                                    title: "Check Out",
                                    icon: "location.south.circle",
                                    backgroundColor: AppColors.error
                                ) {
                                    checkLocationAndShowConfirmation(isCheckIn: false)
                                }
                                .disabled(isProcessing)
                            }
                        } else {
                            AnimatedButton(
                                title: "Enable Location",
                                icon: "location",
                                backgroundColor: AppColors.primary
                            ) {
                                locationService.requestLocationPermission()
                            }
                        }
                        
                        if isProcessing {
                            HStack(spacing: 12) {
                                LoadingIndicator()
                                Text("Processing location...")
                                    .font(AppTypography.body)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Check In Confirmation", isPresented: $showingCheckInConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Check In") {
                performLocationCheckIn()
            }
        } message: {
            if let office = nearestOffice {
                Text("Check in at \(office.name)?")
            } else {
                Text("Check in at current location?")
            }
        }
        .alert("Check Out Confirmation", isPresented: $showingCheckOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Check Out") {
                performLocationCheckOut()
            }
        } message: {
            Text("Check out from current location?")
        }
        .sheet(isPresented: $showingResult) {
            LocationResultView(
                message: resultMessage,
                isSuccess: isSuccess
            )
        }
        .onAppear {
            updateMapRegion()
        }
        .onReceive(locationService.$currentLocation) { location in
            if let location = location {
                updateMapRegion(for: location)
                updateNearestOffice(for: location)
            }
        }
    }
    
    private func updateMapRegion() {
        if let location = locationService.currentLocation {
            updateMapRegion(for: location)
        }
    }
    
    private func updateMapRegion(for location: CLLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    private func updateNearestOffice(for location: CLLocation) {
        nearestOffice = locationService.getNearestOfficeLocation(from: location)
    }
    
    private func checkLocationAndShowConfirmation(isCheckIn: Bool) {
        guard let location = locationService.currentLocation else {
            resultMessage = "Location not available. Please enable location services."
            isSuccess = false
            showingResult = true
            return
        }
        
        updateNearestOffice(for: location)
        
        if isCheckIn {
            showingCheckInConfirmation = true
        } else {
            showingCheckOutConfirmation = true
        }
    }
    
    private func performLocationCheckIn() {
        isProcessing = true
        
        Task {
            do {
                try await locationService.checkInWithLocation()
                
                await MainActor.run {
                    resultMessage = "Successfully checked in using location!"
                    isSuccess = true
                    showingResult = true
                    isProcessing = false
                }
                
                HapticFeedback.notification(.success)
                
            } catch {
                await MainActor.run {
                    resultMessage = error.localizedDescription
                    isSuccess = false
                    showingResult = true
                    isProcessing = false
                }
                
                HapticFeedback.notification(.error)
            }
        }
    }
    
    private func performLocationCheckOut() {
        isProcessing = true
        
        Task {
            do {
                try await locationService.checkOutWithLocation()
                
                await MainActor.run {
                    resultMessage = "Successfully checked out using location!"
                    isSuccess = true
                    showingResult = true
                    isProcessing = false
                }
                
                HapticFeedback.notification(.success)
                
            } catch {
                await MainActor.run {
                    resultMessage = error.localizedDescription
                    isSuccess = false
                    showingResult = true
                    isProcessing = false
                }
                
                HapticFeedback.notification(.error)
            }
        }
    }
}

// MARK: - Location Status Card
struct LocationStatusCard: View {
    @EnvironmentObject var locationService: LocationService
    
    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Location Status")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: locationService.isLocationEnabled ? "location.fill" : "location.slash")
                        .foregroundColor(locationService.isLocationEnabled ? AppColors.success : AppColors.error)
                }
                
                VStack(spacing: 12) {
                    LocationInfoRow(
                        title: "Status",
                        value: locationService.isLocationEnabled ? "Enabled" : "Disabled",
                        color: locationService.isLocationEnabled ? AppColors.success : AppColors.error
                    )
                    
                    if locationService.isLocationEnabled {
                        LocationInfoRow(
                            title: "Accuracy",
                            value: locationService.getLocationAccuracyString(),
                            color: .white.opacity(0.8)
                        )
                        
                        LocationInfoRow(
                            title: "Coordinates",
                            value: locationService.getCurrentLocationString(),
                            color: .white.opacity(0.8)
                        )
                        
                        if let nearestOffice = locationService.getNearestOfficeLocation(from: locationService.currentLocation ?? CLLocation()) {
                            LocationInfoRow(
                                title: "Nearest Office",
                                value: nearestOffice.name,
                                color: AppColors.info
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Location Info Row
struct LocationInfoRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(AppTypography.body)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Office Map Marker
struct OfficeMapMarker: View {
    let office: GeofenceRegion
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 30, height: 30)
                
                Image(systemName: "building.2.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(office.name)
                .font(AppTypography.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.black.opacity(0.7))
                )
        }
    }
}

// MARK: - Location Result View
struct LocationResultView: View {
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
                    
                    if isSuccess {
                        VStack(spacing: 8) {
                            Text("Time: \(Date().formatted(date: .omitted, time: .shortened))")
                                .font(AppTypography.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("Method: Location-based")
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    
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
struct LocationAttendanceView_Previews: PreviewProvider {
    static var previews: some View {
        LocationAttendanceView()
            .environmentObject(LocationService.shared)
            .environmentObject(AttendanceService.shared)
    }
} 