# Slice 5: BLE, setup, live calibration

**Goal:** Pair a real Gotcha Six over NUS, send the core preset, and pass wall step-back calibration — keep demo / continue-without-device paths.

**Architecture:** One `RadarLink` (`ObservableObject`) owns Core Bluetooth scan/connect, NUS I/O, UniFFI engine + AlertGate reset, and preset send. Screens consume published connection/scan/output state. No transport protocol tree. Session / Live Activity / alerts stay in Slice 6.

**Tech stack:** SwiftUI iOS 17, Core Bluetooth, UniFFI (`UniffiRadarEngine`, `UniffiAlertGate`, `radarPresetCommands`, `encodeCommandLine`, `presetGapMs`), existing onboarding routes.

**Thermo-nuclear:** Approve — mirror lab `WebBluetoothTransport` + UniFFI preset helpers; extend calibration observer and screens.

## Constraints

- NUS service `6e400001-…`, RX `6e400002-…`, TX `6e400003-…`. Name `Gotcha Six`.
- Write 20-byte chunks. Feed every notify into `pushBytes`. Do not parse lines in Swift.
- Store peripheral UUID; Forget clears it. Reset engine and AlertGate on disconnect/reconnect.
- After connect: wait 1 s, send preset with 150 ms gaps. If no target for 4 s after reconnect, send preset again.
- Live calibration: 20 s timeout; pass = approaching and distance falls ≥ 1 m.
- Keep Demo row and Continue without device on Find device.

## Out of scope

Session start/end, Live Activity updates, time-sensitive alerts, bonding, preset wait settings toggle, Undraw, new XCTest target.

## Commits

1. `RadarLink` + inject at app root (scan/connect/notify/write/preset/reset/persist).
2. Find device live list + setup screen sends preset → calibration.
3. Live calibration + Home Connect / Forget / Recalibrate.
4. Evidence + PR closes #10.

## Files

| Action | Path |
|--------|------|
| Create | `ios/GotchaSix/BLE/RadarLink.swift` |
| Rename/extend | `DemoCalibrationModel` → `CalibrationModel` |
| Modify | Find device, setup, calibration, Home, OnboardingStore, app root |

Closes tracking issue #10 when done.
