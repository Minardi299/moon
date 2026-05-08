import SwiftUI
import CoreLocation

// Brooklyn fallback when the user hasn't granted location yet — keeps the
// design's reference frame (40.69, -73.99) until real coords arrive.
private let fallbackLat = 40.69
private let fallbackLon = -73.99
private let fallbackPlace = "Brooklyn, NY"

struct MainView: View {
    @EnvironmentObject var location: LocationManager
    @AppStorage("compassStyle") private var compassStyleRaw: String = CompassStyle.rose.rawValue

    @State private var scrubMinutes: Int? = nil
    @State private var nowDate: Date = Date()
    @State private var selected: SkyTarget? = nil
    @State private var showSettings: Bool = false

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        let coord = location.coordinate
        let lat = coord?.latitude ?? fallbackLat
        let lon = coord?.longitude ?? fallbackLon
        let placeLabel = location.placeName ?? fallbackPlace
        let displayDate = effectiveDate
        let sun = sunPosition(at: displayDate, latitude: lat, longitude: lon)
        let moon = moonPosition(at: displayDate, latitude: lat, longitude: lon)
        let m = mode(forSunAltitude: sun.altitude)
        let style = CompassStyle(rawValue: compassStyleRaw) ?? .rose
        let rs = sunRiseSet(on: displayDate, latitude: lat, longitude: lon)
        let mrs = moonRiseSet(on: displayDate, latitude: lat, longitude: lon)
        let gh = goldenHour(on: displayDate, latitude: lat, longitude: lon)

        ZStack {
            FrontPanel(mode: m) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    TopStatus(mode: m, location: placeLabel, heading: location.heading,
                              onSettings: { showSettings = true })
                        .padding(.horizontal, 20)
                    Spacer()
                    // The .frame here pins the layout slot for the compass.
                    // Tweak `size` on CompassView freely — only the dial scales;
                    // the surrounding UI stays exactly where it is.
                    CompassView(
                        size: 420, style: style,
                        heading: location.heading,
                        sun: sun, moon: moon, mode: m,
                        selected: selected,
                        onSunTap: { selected = .sun },
                        onMoonTap: { selected = .moon }
                    )
                    .frame(width: 340, height: 380)
                    Spacer()
                    QuickInfo(mode: m, sun: sun, moon: moon, sunRS: rs, moonRS: mrs,
                              onSunTap: { selected = .sun },
                              onMoonTap: { selected = .moon })
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    TimeScrubberView(
                        minutes: Binding(
                            get: { scrubMinutes ?? minutesOf(nowDate) },
                            set: { newValue in scrubMinutes = newValue }
                        ),
                        isLive: scrubMinutes == nil,
                        onLiveTap: { scrubMinutes = nil },
                        mode: m,
                        displayDate: displayDate
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            if selected != nil {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { selected = nil }
                    .zIndex(1)
            }
            if let target = selected {
                VStack(spacing: 0) {
                    Spacer()
                    DetailSheetView(
                        target: target, mode: m,
                        sun: sun, moon: moon,
                        sunRS: rs, moonRS: mrs,
                        goldenHour: gh,
                        onClose: { selected = nil }
                    )
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .transition(.move(edge: .bottom))
                .zIndex(2)
            }
        }
        .animation(.easeOut(duration: 0.28), value: selected)
        .onReceive(timer) { _ in nowDate = Date() }
        .onAppear { location.start() }
        .sheet(isPresented: $showSettings) {
            SettingsView(mode: m).environmentObject(location)
        }
    }

    private var effectiveDate: Date {
        guard let m = scrubMinutes else { return nowDate }
        let cal = Calendar.current
        var c = cal.dateComponents([.year, .month, .day], from: nowDate)
        c.hour = m / 60
        c.minute = m % 60
        c.second = 0
        return cal.date(from: c) ?? nowDate
    }

    private func minutesOf(_ d: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

// MARK: - Top status bar

struct TopStatus: View {
    let mode: Mode
    let location: String
    let heading: Double
    var onSettings: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            DisplayBox(mode: mode, dark: false, cornerRadius: 6,
                       horizontalPadding: 12, verticalPadding: 8) {
                HStack(spacing: 6) {
                    pinIcon
                    Text(location)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.3)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            DisplayBox(mode: mode, dark: true, cornerRadius: 6,
                       horizontalPadding: 10, verticalPadding: 8) {
                VStack(alignment: .center, spacing: 1) {
                    Text("HDG")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(Color(hex: 0xF5EFDC).opacity(0.55))
                    Text(String(format: "%03d°", Int(heading.rounded())))
                        .displayText(size: 14, tracking: 0.5)
                }
                .frame(minWidth: 56)
            }
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(mode.palette.ink.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(mode.palette.inset)
                    )
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.3), lineWidth: 1)
                            .blur(radius: 0.6)
                            .offset(y: 0.6)
                            .mask(Circle().fill(LinearGradient(colors: [.black, .clear],
                                                               startPoint: .top, endPoint: .bottom)))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var pinIcon: some View {
        Image(systemName: "location.fill")
            .font(.system(size: 10, weight: .semibold))
    }
}

// MARK: - Quick info gauges

struct QuickInfo: View {
    let mode: Mode
    let sun: SunPosition
    let moon: MoonPosition
    let sunRS: RiseSet
    let moonRS: RiseSet
    var onSunTap: () -> Void = {}
    var onMoonTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 10) {
            gauge(tag: "SUN",
                  accent: Color(hex: 0xF4A040),
                  alt: sun.altitude,
                  isUp: sun.altitude > 0,
                  rise: sunRS.rise, set: sunRS.set,
                  dim: sun.altitude < -6,
                  onTap: onSunTap)
            gauge(tag: "MOON",
                  accent: mode.isDay ? Color(hex: 0x7A7A86) : Color(hex: 0xCFD8E8),
                  alt: moon.altitude,
                  isUp: moon.altitude > 0,
                  rise: moonRS.rise, set: moonRS.set,
                  dim: moon.altitude < -6,
                  onTap: onMoonTap)
        }
    }

    @ViewBuilder
    private func gauge(tag: String, accent: Color, alt: Double, isUp: Bool,
                       rise: Date?, set: Date?, dim: Bool,
                       onTap: @escaping () -> Void) -> some View {
        let p = mode.palette
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(tag)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.8)
                    .foregroundStyle(p.ink.opacity(0.65))
                Spacer()
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                    .shadow(color: accent.opacity(0.8), radius: 3)
            }
            DisplayBox(mode: mode, dark: true, cornerRadius: 4,
                       horizontalPadding: 8, verticalPadding: 6) {
                Text(alt > -6 ? String(format: "%02d° ALT", Int(alt.rounded())) : "BELOW")
                    .displayText(size: 16, tracking: 0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 4) {
                Text(isUp ? "↓" : "↑")
                    .font(.system(size: 11, weight: .medium))
                Text(formatted(isUp ? set : rise))
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(p.ink.opacity(0.55))
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(p.inset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.35), lineWidth: 1)
                .blur(radius: 1)
                .offset(y: 1)
                .mask(RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.black, .clear],
                                         startPoint: .top, endPoint: .center)))
        )
        .opacity(dim ? 0.55 : 1)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private func formatted(_ d: Date?) -> String {
        guard let d else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        return f.string(from: d)
    }
}
