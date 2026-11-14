# Onboarding polish and demo fixtures

**Path:** `docs/specs/2026-11-14-onboarding-polish-demo-fixtures-design.md`  
**Author:** Josh McArthur (joshua.mcarthur@gmail.com)  
**Created:** 2026-11-14  
**Status:** Accepted  
**Parent:** [Pocket session](./2026-11-14-companion-app-design.md)  
**Repo:** [joshmcarthur/gotcha-six](https://github.com/joshmcarthur/gotcha-six)

## Objective

Make first-run teaching excellent for people with or without a Gotcha Six unit — including App Store review — by polishing onboarding visuals/copy and driving demo calibration (and Home demos) through the real Rust parser on canned fixture scenarios. No real BLE in this slice.

## Background

Slice 4 shipped a wireframe first-run (Welcome → Home) with grey illustration slots, an empty Find device list, and a simulated How-to B haptic/card. Everyday use after onboarding is thin: open app, start session, pocket the phone. Trust is won on the teaching path.

App Store review and “bought the app before the unit” must complete onboarding without hardware. The lab already uses timed fixture lines (`<t_ms>\t$DFDMD…`). Core tests already feed that format into `RadarEngine` (`core/tests/fixtures/`, e.g. `session_approach.txt`).

## Goals

- Teaching screens look intentional: one drawing where the parent spec calls for it, one accent, light motion, tighter copy.
- No-unit users can finish first run via **Continue without device** or a **Demo Gotcha Six** path that runs UniFFI on fixture bytes.
- A small named fixture pack (pass / fail / approaching alert) is shared with core tests and playable from Home for development and review.
- Swift still does not parse `$DFDMD`.

## Non-goals

- Real BLE scan/connect, NUS I/O, or preset-over-radio.
- Live Activity / session runtime / time-sensitive alerts on real or demo streams (demo may show in-app distance/motion and the existing sample alert card patterns only).
- Android or a second parser.
- Checking in UniFFI-generated Swift.

## Scenarios

**Scenario: First run with no unit (review / browse)**

1. Welcome → Permissions → How-to A/B/C as today, with real illustrations and polished copy.
2. How-to B Play alert: haptic + sample `Approaching · 12 m` card (unchanged intent).
3. Find device: copy explains the unit advertises as Gotcha Six; real list empty until BLE ships.
4. User taps **Continue without device** → Home with calibration incomplete / skipped.

**Scenario: First run with demo unit**

1. Same teaching path through How-to C.
2. Find device: user taps **Demo Gotcha Six** (clearly labeled demo, not a real peripheral).
3. Short “setting up” beat (no radio); then Calibration UI with the wall step-back illustration and copy.
4. `FixturePlayer` plays `wall_pass` into `UniffiRadarEngine` on the fixture clock; UI shows live distance/motion from engine outputs.
5. Pass confirmation when motion is approaching and distance has fallen; Continue → Home (calibration demo complete).

**Scenario: Demo failure path**

From demo calibration (or Home Play demo), `wall_fail` runs long enough to hit the same fail copy as live calibration will use later (no approaching). Try again / Skip for now / back to Home.

**Scenario: Return visit — play simulated data**

Home overflow **Play demo** → pick `wall_pass` | `wall_fail` | `alert_approach`. Player feeds UniFFI; UI matches the scenario (calibration-style readout or alert-style sample). Labeled **Demo · no hardware**.

**Scenario: Return visit — replay how-to**

Unchanged: overflow Replay how-to; no hardware required.

## Fixture pack

Canonical lab-format files, shared by core tests and the iOS bundle:

| ID | Purpose |
| --- | --- |
| `wall_pass` | Distance falls; motion becomes `approaching`; then a clear end (e.g. lost/none). Prefer extending/reusing `session_approach.txt` shape. |
| `wall_fail` | Target/presence without a qualifying approaching close for the calibration timeout window. |
| `alert_approach` | Short approaching clip for Home demo / optional How-to B enrichment later. |

**Player rules**

- Strip `<t_ms>\t` the same way core tests do; schedule line delivery by `t_ms` (or documented acceleration for UI tests).
- `push_bytes` only through `UniffiRadarEngine`; reset engine at scenario start.
- Do not invent a parallel Swift motion detector.

**Layout (recommended)**

- Keep editable sources under `core/tests/fixtures/` (or a promoted `fixtures/` tree if the implementation plan prefers one folder for app + tests).
- Xcode copies the three named files into the app bundle; core tests keep reading from disk.

## Screens and chrome

| Screen | Change in this slice |
| --- | --- |
| Welcome | unDraw running-from-behind; teal accent; tighten purpose + safety lines. |
| Permissions | Copy polish only; still no illustration. |
| How-to A | Custom SVG: person, rear radar, cone. |
| How-to B | Motion on sample card; no hero art. |
| How-to C | unDraw phone-put-away. |
| Find device | Demo row + **Continue without device**; honest empty real list. |
| Setting up (demo) | Brief non-radio setup copy before calibration. |
| Calibration (demo) | Custom step-back SVG; fixture-driven distance/motion; pass/fail/skip. |
| Home | Overflow: Replay how-to, **Play demo** (scenario picker). Connection stays “not connected” until BLE. |

**Accent:** `#3d9b6e` (lab teal), shared with approaching emphasis and primary CTAs.

**Motion:** Screen enter fade/slide; alert card appear; calibration values update with the fixture clock. No looping decorative animation.

**Assets:** Keep unDraw licence text next to downloaded files. Custom SVGs match the same flat style and single accent. No IMU art. No runner vs cyclist variants.

## Constraints

- iPhone / iOS 17 app already in tree; Mac for visual check.
- `wasm` and `uniffi` remain mutually exclusive at build time.
- Find device “no skip” in the parent spec applies to **real** hardware pairing; this slice explicitly allows continue-without-device and demo for no-unit users. Real BLE slice must not remove the demo/continue exits without a replacement review path.

## Dependencies

- Existing UniFFI surface (`UniffiRadarEngine`, preset helpers).
- Existing lab/core fixture line format.
- unDraw + custom SVGs (Slice 7 intent pulled forward into this work).

## Open issues

**Fixture home directory**

- Options: leave files in `core/tests/fixtures/` with Xcode folder references, or add top-level `fixtures/` and point both consumers there.
- **Next step:** pick in the implementation plan; prefer the smaller path that avoids duplicate files.

**How-to B vs `alert_approach`**

- Play alert may stay purely UI haptic/card; `alert_approach` is required for Home Play demo. Wiring How-to B to the fixture is optional later if it improves fidelity without slowing the teach beat.

## Resolved issues

**Decision:** Polish onboarding before real BLE; support no-unit users.  
App Store review and pre-hardware buyers must not block on a missing peripheral.

**Decision:** Continue without device **and** Demo device.  
Quick exit to Home, plus a full simulated calibration for reviewers and self-test.

**Decision:** Demo and Home demos use UniFFI + canned fixtures, not Swift-fake motion.  
One parser; fixtures stay editable lab exports.

**Decision:** Fixture pack is pass, fail, and approaching alert; Home overflow Play demo.  
Supports onboarding and ongoing simulated testing.

**Decision:** Accent is lab teal `#3d9b6e`.  
Matches existing lab language; one brand colour for CTAs and approaching emphasis.
