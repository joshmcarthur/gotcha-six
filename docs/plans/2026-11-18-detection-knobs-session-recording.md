# Detection knobs and session recording

**Goal:** 15 cm hold band, 4-frame Lost coast, `hasTarget` clear on count 0, and automatic lab-format session recording with Share on Home.

**Architecture:** Change `DetectionEngine` in the shared core. Add `raw` to UniFFI `EngineOutput`. One small `SessionLog` type writes `last-session.txt`; `RadarLink` appends during an armed session; Home shares the file. No new BLE stack. No preset change.

**Tech stack:** `gotcha-six-core`, UniFFI, SwiftUI `ShareLink`.

**Thermo-nuclear plan review: Approve** — extend `DetectionEngine` and the existing lab text format; one new `SessionLog` file. No recorder port from TypeScript, no time-window detector, no preset retune.

## Constraints

- 3-sample window stays. `AlertGate` 2 s / 1 m stays.
- Lab import format: `<t_ms>\t<raw line>`.
- Session on → record. Session off → share. Next start replaces the file.
- 8 MB cap: stop appending.

## Files

| File | Change |
| --- | --- |
| `core/src/detection.rs` | 0.15 m band, 4-sample Lost coast, tests |
| `core/tests/fixtures/session_approach.txt` | Four trailing empty `$DFDMD` so Lost still appears |
| `core/tests/fixtures/wall_pass.txt` | Same |
| `core/src/uniffi_api.rs` | `EngineOutput.raw` |
| `ios/GotchaSix/Session/SessionLog.swift` | Create. File append + cap |
| `ios/GotchaSix/BLE/RadarLink.swift` | Start/stop log; append `raw`; `hasTarget` from count/distance |
| `ios/GotchaSix/Screens/HomeView.swift` | Share last recording |

## Commits

1. Core knobs + fixture tails + tests.
2. UniFFI `raw` + `SessionLog` + RadarLink/Home share + `hasTarget` fix.

## Tests

- 5.0 → 5.10 is `Stationary` (was Unknown/approaching under 5 cm).
- One empty frame after a target is `Stationary`, not `Lost`.
- Fourth consecutive empty is `Lost`.
- AlertGate: first approach, one empty, approach again → still one fire (close kept).
- Fixtures that expect `Lost` have four empty lines.
- UniFFI target line exposes `raw`.

Skip an iOS XCTest target (project has none). `SessionLog` is a file append of a known format.

## Out of scope

Time-based window, hop reject, `setThrFactor`, in-app replay, CSV.
