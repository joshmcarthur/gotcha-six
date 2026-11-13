# Handoff: Pocket session companion app

Use this to start a **new Cursor conversation on `joshmcarthur/gotcha-six`**. Do not continue in `joshmcarthur/dotfiles`. The previous session was launched on the wrong repo.

**Date:** 2026-11-14 (Pacific/Auckland)  
**Previous PR:** https://github.com/joshmcarthur/gotcha-six/pull/1  
**Branch:** `agent/companion-app-design-b836`

## Paste this as the first message

```
Continue Pocket session, the Gotcha Six iPhone companion.

Repo: joshmcarthur/gotcha-six (this project). Ignore joshmcarthur/dotfiles and joshmcarthur/nudge except as background.

Read first:
- docs/specs/2026-11-14-companion-app-design.md
- docs/specs/2026-11-14-companion-app-handoff.md
- PR https://github.com/joshmcarthur/gotcha-six/pull/1

The design is Proposed, not implemented. Josh approved the design in chat. The spec PR may still be open.

Locked:
- Native iPhone / SwiftUI, minimal. No Android, Flutter, Expo in v1.
- Share gotcha-six-core via UniFFI. Do not parse $DFDMD in Swift.
- App lives in ios/ in this repo.
- BLE Nordic UART, device name "Gotcha Six". Same NUS UUIDs as lab/src/transports/bluetooth.ts.
- How-to is simulated (haptic + sample Live Activity card), no hardware.
- Calibration is live radar: stand back-to-wall, step backward. No helper. No IMU.
- Missing $GSIMU is not an error. Do not revive Nudge GATT.
- Session: Live Activity (glance) + time-sensitive local notification (interrupt). Phone may be locked.
- Illustrations: unDraw for Welcome and How-to C; two custom undraw-style SVGs for How-to A and Calibration. One accent colour. No art on Home, scan, setup, or the Live Activity.

Check in durable docs as PRs on this repo as we write them.

Next, in order:
1. If Josh has comments on PR 1, apply them on that PR.
2. If the spec looks right, write an implementation plan (UniFFI feature, preset in core, ios/ scaffold, screens, BLE session, Live Activity, alerts, illustrations). Open that plan as its own PR. Wait for approval before app code.
3. Do not start Xcode-only work unless a Mac is available. UniFFI crate changes and core tests can run on Linux CI.

Talk to Josh in short, active, consistent sentences (ASD-STE100). Do not commit unless asked, except when he has asked to check docs in via PRs.
```

## What is done

- Product design for v1 is written and proposed.
- Spec: `docs/specs/2026-11-14-companion-app-design.md`
- No `ios/` tree yet. No UniFFI feature yet. Preset still lives in `lab/src/preset.ts` only.
- Firmware, core, and lab on `main` already bridge C4001 over USB + BLE NUS and interpret approaching / receding in Rust.

## What is not done

- Josh’s written review of the spec (chat said the sections look right; the PR is the check-in).
- Implementation plan.
- UniFFI bindings, Swift app, Live Activity extension, illustrations.

## Pointers in this repo

| Thing | Where |
| --- | --- |
| Engine to bind | `core/` (`RadarEngine`, `gotcha-six-core`) |
| WASM sibling surface | `core/src/wasm.rs` |
| BLE NUS in the lab | `lab/src/transports/bluetooth.ts` |
| Radar preset to move into core | `lab/src/preset.ts` |
| Approach fixtures | `core/tests/fixtures/` |
| Hardware / protocol | `README.md` |

## Related but do not copy

- `joshmcarthur/nudge` — old Flutter app, custom GATT, on-device detection. Wrong protocol.

## Open issues in the spec

- Accent colour hex (pick when adding illustrations).
- Preset-after-reconnect wait: confirm on hardware; no settings toggle.
