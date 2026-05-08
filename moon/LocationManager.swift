import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var heading: Double = 0          // smoothed, true heading degrees [0, 360)
    @Published var rawHeading: Double = 0
    @Published var authorization: CLAuthorizationStatus = .notDetermined
    @Published var placeName: String?

    private let manager = CLLocationManager()
    private var smoothedSin: Double = 0
    private var smoothedCos: Double = 1
    private var hasSeed = false
    private let geocoder = CLGeocoder()
    private var lastGeocodedAt: Date?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
        manager.headingFilter = 1
        manager.headingOrientation = .portrait
        authorization = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
        manager.startUpdatingLocation()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorization = manager.authorizationStatus
        if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
            start()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        coordinate = last.coordinate
        reverseGeocodeIfNeeded(last)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let h = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        rawHeading = h
        // Low-pass via running average on the unit circle so 359°→1° wraps cleanly.
        let r = h * .pi / 180
        let s = sin(r), c = cos(r)
        if !hasSeed {
            smoothedSin = s
            smoothedCos = c
            hasSeed = true
        } else {
            let alpha = 0.18
            smoothedSin = smoothedSin * (1 - alpha) + s * alpha
            smoothedCos = smoothedCos * (1 - alpha) + c * alpha
        }
        var deg = atan2(smoothedSin, smoothedCos) * 180 / .pi
        if deg < 0 { deg += 360 }
        heading = deg
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Quiet failure — UI shows last-known location or fallback.
    }

    private func reverseGeocodeIfNeeded(_ loc: CLLocation) {
        let now = Date()
        if let last = lastGeocodedAt, now.timeIntervalSince(last) < 300 { return }
        lastGeocodedAt = now
        geocoder.reverseGeocodeLocation(loc) { [weak self] placemarks, _ in
            guard let pm = placemarks?.first else { return }
            let parts = [pm.locality, pm.administrativeArea].compactMap { $0 }
            DispatchQueue.main.async {
                self?.placeName = parts.joined(separator: ", ")
            }
        }
    }
}
