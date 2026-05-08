import Foundation

// Pure-Foundation sun & moon calculations. Suncalc-derived algorithms;
// accuracy is ~0.01° for sun, ~0.1° for moon — fine for a compass.
// No UIKit / SwiftUI / CoreLocation imports — portable to watchOS.

struct SunPosition: Equatable {
    let azimuth: Double   // degrees from N, clockwise
    let altitude: Double  // degrees above horizon
}

struct MoonPosition: Equatable {
    let azimuth: Double
    let altitude: Double
    let phase: Double     // 0=new, 0.25=first qtr, 0.5=full, 0.75=last qtr
    let illumination: Double  // 0..1 fraction of disk illuminated
}

struct RiseSet: Equatable {
    let rise: Date?
    let set: Date?
}

private let rad = Double.pi / 180
private let e = rad * 23.4397
private let J1970 = 2440588.0
private let J2000 = 2451545.0
private let J0 = 0.0009

private func toDays(_ date: Date) -> Double {
    date.timeIntervalSince1970 / 86400 - 0.5 + J1970 - J2000
}

private func fromJulian(_ j: Double) -> Date? {
    guard j.isFinite else { return nil }
    return Date(timeIntervalSince1970: (j + 0.5 - J1970) * 86400)
}

private func solarMeanAnomaly(_ d: Double) -> Double {
    rad * (357.5291 + 0.98560028 * d)
}

private func eclipticLongitude(_ M: Double) -> Double {
    let C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M))
    let P = rad * 102.9372
    return M + C + P + .pi
}

private func declination(_ l: Double, _ b: Double) -> Double {
    asin(sin(b) * cos(e) + cos(b) * sin(e) * sin(l))
}

private func rightAscension(_ l: Double, _ b: Double) -> Double {
    atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l))
}

private func siderealTime(_ d: Double, _ lw: Double) -> Double {
    rad * (280.16 + 360.9856235 * d) - lw
}

private func azimuthMeeus(_ H: Double, _ phi: Double, _ dec: Double) -> Double {
    atan2(sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi))
}

private func altitudeRad(_ H: Double, _ phi: Double, _ dec: Double) -> Double {
    asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H))
}

private func azimuthFromNorth(_ rad: Double) -> Double {
    let a = rad + .pi
    let twoPi = 2 * Double.pi
    let m = a.truncatingRemainder(dividingBy: twoPi)
    return (m < 0 ? m + twoPi : m) * 180 / .pi
}

// MARK: - Sun

func sunPosition(at date: Date, latitude: Double, longitude: Double) -> SunPosition {
    let lw = rad * -longitude
    let phi = rad * latitude
    let d = toDays(date)
    let M = solarMeanAnomaly(d)
    let L = eclipticLongitude(M)
    let dec = declination(L, 0)
    let ra = rightAscension(L, 0)
    let H = siderealTime(d, lw) - ra
    return SunPosition(
        azimuth: azimuthFromNorth(azimuthMeeus(H, phi, dec)),
        altitude: altitudeRad(H, phi, dec) * 180 / .pi
    )
}

// MARK: - Moon

private struct MoonCoords {
    let longitude: Double
    let latitude: Double
    let distance: Double
}

private func moonCoords(_ d: Double) -> MoonCoords {
    let L = rad * (218.316 + 13.176396 * d)
    let M = rad * (134.963 + 13.064993 * d)
    let F = rad * (93.272 + 13.229350 * d)
    let l = L + rad * 6.289 * sin(M)
    let b = rad * 5.128 * sin(F)
    let dt = 385001 - 20905 * cos(M)
    return MoonCoords(longitude: l, latitude: b, distance: dt)
}

func moonPosition(at date: Date, latitude: Double, longitude: Double) -> MoonPosition {
    let lw = rad * -longitude
    let phi = rad * latitude
    let d = toDays(date)
    let c = moonCoords(d)
    let H = siderealTime(d, lw) - rightAscension(c.longitude, c.latitude)
    let dec = declination(c.longitude, c.latitude)
    var altRad = altitudeRad(H, phi, dec)
    // atmospheric refraction (Sæmundsson) — only meaningful very near the horizon
    altRad += rad * 0.017 / tan(altRad + rad * 10.26 / (altRad / rad + 5.10))
    let illum = moonIllumination(at: date)
    return MoonPosition(
        azimuth: azimuthFromNorth(azimuthMeeus(H, phi, dec)),
        altitude: altRad * 180 / .pi,
        phase: illum.phase,
        illumination: illum.fraction
    )
}

private func moonIllumination(at date: Date) -> (phase: Double, fraction: Double, angle: Double) {
    let d = toDays(date)
    // Sun (geocentric)
    let M = solarMeanAnomaly(d)
    let L = eclipticLongitude(M)
    let sunDec = declination(L, 0)
    let sunRA = rightAscension(L, 0)
    let sunDist = 149598000.0 // km, mean

    let m = moonCoords(d)
    let moonDec = declination(m.longitude, m.latitude)
    let moonRA = rightAscension(m.longitude, m.latitude)

    let sdist = sunDist
    let phi = acos(sin(sunDec) * sin(moonDec) + cos(sunDec) * cos(moonDec) * cos(sunRA - moonRA))
    let inc = atan2(sdist * sin(phi), m.distance - sdist * cos(phi))
    let angle = atan2(
        cos(sunDec) * sin(sunRA - moonRA),
        sin(sunDec) * cos(moonDec) - cos(sunDec) * sin(moonDec) * cos(sunRA - moonRA)
    )
    let fraction = (1 + cos(inc)) / 2
    let phase = 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / .pi
    return (phase, fraction, angle)
}

// MARK: - Rise / set

private func julianCycle(_ d: Double, _ lw: Double) -> Double {
    (d - J0 - lw / (2 * .pi)).rounded()
}

private func approxTransit(_ Ht: Double, _ lw: Double, _ n: Double) -> Double {
    J0 + (Ht + lw) / (2 * .pi) + n
}

private func solarTransitJ(_ ds: Double, _ M: Double, _ L: Double) -> Double {
    J2000 + ds + 0.0053 * sin(M) - 0.0069 * sin(2 * L)
}

private func hourAngle(_ h: Double, _ phi: Double, _ d: Double) -> Double {
    let cosw = (sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d))
    if cosw > 1 || cosw < -1 { return .nan } // doesn't rise or set
    return acos(cosw)
}

func sunRiseSet(on date: Date, latitude: Double, longitude: Double) -> RiseSet {
    let lw = rad * -longitude
    let phi = rad * latitude
    let d = toDays(date)
    let n = julianCycle(d, lw)
    let ds = approxTransit(0, lw, n)
    let M = solarMeanAnomaly(ds)
    let L = eclipticLongitude(M)
    let dec = declination(L, 0)
    let Jnoon = solarTransitJ(ds, M, L)
    let h0 = -0.833 * rad
    let w = hourAngle(h0, phi, dec)
    if w.isNaN { return RiseSet(rise: nil, set: nil) }
    let a = approxTransit(w, lw, n)
    let Jset = solarTransitJ(a, M, L)
    let Jrise = Jnoon - (Jset - Jnoon)
    return RiseSet(rise: fromJulian(Jrise), set: fromJulian(Jset))
}

func goldenHour(on date: Date, latitude: Double, longitude: Double) -> (start: Date, end: Date)? {
    let lw = rad * -longitude
    let phi = rad * latitude
    let d = toDays(date)
    let n = julianCycle(d, lw)
    let ds = approxTransit(0, lw, n)
    let M = solarMeanAnomaly(ds)
    let L = eclipticLongitude(M)
    let dec = declination(L, 0)
    let hStart = 6 * rad     // start of golden hour: sun at 6° altitude
    let hEnd = -0.833 * rad  // end at sunset
    let wStart = hourAngle(hStart, phi, dec)
    let wEnd = hourAngle(hEnd, phi, dec)
    if wStart.isNaN || wEnd.isNaN { return nil }
    let Jset1 = solarTransitJ(approxTransit(wStart, lw, n), M, L)
    let Jset2 = solarTransitJ(approxTransit(wEnd, lw, n), M, L)
    guard let s = fromJulian(Jset1), let e2 = fromJulian(Jset2) else { return nil }
    return (start: s, end: e2)
}

// Moon rise/set: numeric search across 24h centered on the date.
// Uses 10-min sampling + linear interpolation across sign changes.
func moonRiseSet(on date: Date, latitude: Double, longitude: Double) -> RiseSet {
    let cal = Calendar(identifier: .gregorian)
    var c = cal.dateComponents(in: TimeZone.current, from: date)
    c.hour = 0; c.minute = 0; c.second = 0; c.nanosecond = 0
    guard let start = cal.date(from: c) else { return RiseSet(rise: nil, set: nil) }
    let h0 = 0.125 // moon's standard altitude in degrees (parallax + refraction)

    var prevAlt: Double? = nil
    var prevT: Date? = nil
    var rise: Date? = nil
    var set: Date? = nil
    let step: TimeInterval = 600 // 10 minutes
    var t = start
    let end = start.addingTimeInterval(86400)
    while t <= end {
        let alt = moonPosition(at: t, latitude: latitude, longitude: longitude).altitude
        if let pa = prevAlt, let pt = prevT {
            if pa < h0 && alt >= h0 && rise == nil {
                let frac = (h0 - pa) / (alt - pa)
                rise = pt.addingTimeInterval(step * frac)
            }
            if pa >= h0 && alt < h0 && set == nil {
                let frac = (pa - h0) / (pa - alt)
                set = pt.addingTimeInterval(step * frac)
            }
        }
        prevAlt = alt
        prevT = t
        t = t.addingTimeInterval(step)
    }
    return RiseSet(rise: rise, set: set)
}

// MARK: - Helpers

func cardinalLabel(_ degrees: Double) -> String {
    let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
    var d = degrees.truncatingRemainder(dividingBy: 360)
    if d < 0 { d += 360 }
    return dirs[Int(((d / 22.5).rounded())) % 16]
}

func phaseName(_ p: Double) -> String {
    if p < 0.03 || p > 0.97 { return "New Moon" }
    if p < 0.22 { return "Waxing Crescent" }
    if p < 0.28 { return "First Quarter" }
    if p < 0.47 { return "Waxing Gibbous" }
    if p < 0.53 { return "Full Moon" }
    if p < 0.72 { return "Waning Gibbous" }
    if p < 0.78 { return "Last Quarter" }
    return "Waning Crescent"
}
