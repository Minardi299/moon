import Testing
import Foundation
@testable import moon

struct AstronomyTests {
    // Brooklyn, NY
    let lat = 40.69
    let lon = -73.99

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, tz: TimeZone = TimeZone(identifier: "America/New_York")!) -> Date {
        var c = DateComponents()
        c.year = y; c.month = mo; c.day = d
        c.hour = h; c.minute = mi; c.second = 0
        c.timeZone = tz
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    @Test func sunNearSouthAtSolarNoonInSummer() {
        // Summer solstice in Brooklyn — sun should be high and roughly south.
        let t = date(2026, 6, 21, 12, 56) // ~solar noon EDT
        let s = sunPosition(at: t, latitude: lat, longitude: lon)
        #expect(abs(s.azimuth - 180) < 6)        // close to due south
        #expect(s.altitude > 70 && s.altitude < 75)  // very high
    }

    @Test func sunBelowHorizonAtMidnight() {
        let t = date(2026, 6, 21, 0, 0)
        let s = sunPosition(at: t, latitude: lat, longitude: lon)
        #expect(s.altitude < -10)  // well below horizon
    }

    @Test func sunriseSunsetWithinTwoMinutesOfNOAA() {
        // NOAA published values for Brooklyn 2026-06-21:
        // sunrise 5:24 AM EDT, sunset 8:31 PM EDT (approx; longest day).
        let day = date(2026, 6, 21, 12, 0)
        let rs = sunRiseSet(on: day, latitude: lat, longitude: lon)
        let cal = Calendar(identifier: .gregorian)
        guard let rise = rs.rise, let set = rs.set else {
            Issue.record("rise/set returned nil")
            return
        }
        let riseMin = cal.component(.hour, from: rise) * 60 + cal.component(.minute, from: rise)
        let setMin = cal.component(.hour, from: set) * 60 + cal.component(.minute, from: set)
        // Convert to EDT minutes (UTC-4) — NOAA values:
        // sunrise ~ 9:24 UTC = 540+24 = 564
        // sunset  ~ 0:31 UTC next day = 1471 (mod 1440 -> 31)
        // Be lenient: compare via Date directly
        let expectedRiseHourEDT = 5
        let expectedRiseMinEDT = 24
        let expectedSetHourEDT = 20
        let expectedSetMinEDT = 31
        var edt = cal
        edt.timeZone = TimeZone(identifier: "America/New_York")!
        let rH = edt.component(.hour, from: rise)
        let rM = edt.component(.minute, from: rise)
        let sH = edt.component(.hour, from: set)
        let sM = edt.component(.minute, from: set)
        let riseDelta = abs((rH * 60 + rM) - (expectedRiseHourEDT * 60 + expectedRiseMinEDT))
        let setDelta = abs((sH * 60 + sM) - (expectedSetHourEDT * 60 + expectedSetMinEDT))
        #expect(riseDelta <= 2, "rise off by \(riseDelta) minutes (got \(rH):\(rM))")
        #expect(setDelta <= 2, "set off by \(setDelta) minutes (got \(sH):\(sM))")
        _ = (riseMin, setMin)
    }

    @Test func moonPhaseNearNewAtKnownEpoch() {
        // 2024-01-11 ~11:57 UTC was a new moon
        var c = DateComponents()
        c.year = 2024; c.month = 1; c.day = 11
        c.hour = 12; c.minute = 0
        c.timeZone = TimeZone(identifier: "UTC")
        let t = Calendar(identifier: .gregorian).date(from: c)!
        let m = moonPosition(at: t, latitude: lat, longitude: lon)
        // Phase 0 (new) or 1 — both wrap to "new". Illumination should be tiny.
        #expect(m.illumination < 0.05)
    }

    @Test func cardinalLabelMatchesDesignTable() {
        #expect(cardinalLabel(0) == "N")
        #expect(cardinalLabel(90) == "E")
        #expect(cardinalLabel(180) == "S")
        #expect(cardinalLabel(270) == "W")
        #expect(cardinalLabel(45) == "NE")
        #expect(cardinalLabel(225) == "SW")
        #expect(cardinalLabel(359) == "N")
    }

    @Test func phaseNameMatchesDesign() {
        #expect(phaseName(0.0) == "New Moon")
        #expect(phaseName(0.5) == "Full Moon")
        #expect(phaseName(0.25) == "First Quarter")
        #expect(phaseName(0.75) == "Last Quarter")
    }
}
