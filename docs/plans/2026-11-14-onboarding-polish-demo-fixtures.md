# Onboarding polish + demo fixtures — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish first-run teaching (illustrations, teal accent, copy/motion) and add UniFFI-driven demo calibration + Home “Play demo” using a shared three-scenario fixture pack — no real BLE.

**Architecture:** Keep fixtures as lab-format text under `core/tests/fixtures/`. Swift `FixturePlayer` loads bundle copies, schedules lines by `t_ms`, and calls `UniffiRadarEngine.pushBytes`. OnboardingStore gains demo/skip calibration routes. Illustrations are asset catalog / SVG resources on the existing screens.

**Tech Stack:** SwiftUI iOS 17, UniFFI `UniffiRadarEngine`, existing core fixture format, xcodegen `project.yml`.

## Global Constraints

- No real BLE / NUS / radio preset.
- Swift does not parse `$DFDMD`; only `UniffiRadarEngine.pushBytes`.
- Accent `#3d9b6e`; one drawing on Welcome, How-to A, How-to C, Calibration only.
- Continue without device **and** Demo Gotcha Six; Home Play demo for `wall_pass` | `wall_fail` | `alert_approach`.
- Do not check in UniFFI-generated Swift.
- Spec: `docs/specs/2026-11-14-onboarding-polish-demo-fixtures-design.md`.

**Thermo-nuclear plan review:** Approve — already the judo; reuse `core/tests/fixtures/` + one Swift player; no fixture service bus, no Swift motion fake, no top-level `fixtures/` tree unless copy proves painful.

---

## File map

| Path | Role |
| --- | --- |
| `core/tests/fixtures/wall_pass.txt` | Named alias/content for pass (from `session_approach` shape) |
| `core/tests/fixtures/wall_fail.txt` | No approaching within timeout window |
| `core/tests/fixtures/alert_approach.txt` | Short approaching clip |
| `core/tests/fixture_engine.rs` | Extend tests for the three named files |
| `ios/GotchaSix/Demo/FixtureScenario.swift` | Enum + bundle resource names |
| `ios/GotchaSix/Demo/FixturePlayer.swift` | Load, schedule, push into engine |
| `ios/GotchaSix/Demo/DemoCalibrationModel.swift` | Pass/fail/skip against engine outputs |
| `ios/GotchaSix/Screens/DemoSetupView.swift` | Brief non-radio setup |
| `ios/GotchaSix/Screens/CalibrationView.swift` | Demo calibration UI |
| `ios/GotchaSix/Screens/DemoScenarioPicker.swift` | Home Play demo picker |
| `ios/GotchaSix/OnboardingStore.swift` | Routes + calibration flags |
| `ios/GotchaSix/Screens/FindDeviceView.swift` | Demo row + continue without device |
| `ios/GotchaSix/Screens/*` + `Assets` | Illustrations, teal, copy/motion |
| `ios/GotchaSix/Resources/Fixtures/` or xcodegen file refs | Bundle the three `.txt` files |
| `ios/project.yml` | Resource membership + new sources |
| `ios/GotchaSix/Assets/...` | AccentColor → `#3d9b6e`; images / SVG |

---

### Task 1: Named fixture pack + core tests

**Files:**
- Create: `core/tests/fixtures/wall_pass.txt`, `wall_fail.txt`, `alert_approach.txt`
- Modify: `core/tests/fixture_engine.rs`
- Keep: `session_approach.txt` (may remain as-is; `wall_pass` can duplicate or thin-wrap the same lines — prefer one clear `wall_pass` file tests assert on)

**Interfaces:**
- Produces: three lab-format files loadable by name; tests prove approaching on pass/alert and absence of approaching on fail within the file’s timeline

- [ ] **Step 1:** Add `wall_pass.txt` (approach then lost/none; timed prefixes). Add `wall_fail.txt` (targets/presence that never qualify as approaching for ≥20 s of fixture time, or stationary/receding only). Add `alert_approach.txt` (short closing distances).

- [ ] **Step 2:** Extend `fixture_engine.rs` with three tests: pass sees `Motion::Approaching`; fail never sees it; alert sees approaching. Run `cargo test -p gotcha-six-core --test fixture_engine`.

- [ ] **Step 3:** Commit `test(core): add wall_pass, wall_fail, alert_approach fixtures`

---

### Task 2: FixturePlayer + scenario enum (Swift)

**Files:**
- Create: `ios/GotchaSix/Demo/FixtureScenario.swift`, `FixturePlayer.swift`
- Modify: `ios/project.yml` (sources + copy `core/tests/fixtures/wall_*.txt` and `alert_approach.txt` into app resources)

**Interfaces:**
- Consumes: bundle `.txt` resources; `UniffiRadarEngine`
- Produces:
  - `enum FixtureScenario: String { case wallPass, wallFail, alertApproach }` with `resourceName: String`
  - `final class FixturePlayer: ObservableObject` with `func load(_ scenario:) throws`, `func start(engine: UniffiRadarEngine, speed: Double = 1.0)`, `func stop()`, `@Published var lastMotion`, `@Published var lastDistanceM`, `@Published var isFinished`

- [ ] **Step 1:** Parse lines; strip time prefix (mirror Rust `strip_time_prefix`); store `[(deadlineMs: UInt64, line: String)]`.

- [ ] **Step 2:** On `start`, `engine.reset()`, then timer/Task sleeps to next deadline (scaled by `speed`), append `\n`, `pushBytes`, publish latest target motion/distance from outputs.

- [ ] **Step 3:** Manual smoke: DEBUG launch + unit test in app target optional — prefer a small XCTest that loads `wall_pass` and asserts at least one approaching after playing at high `speed` (e.g. 100×) if an app test target is cheap; else CoreSmoke-style call from a DEBUG screen once Task 4 exists. State in commit notes which evidence was used.

- [ ] **Step 4:** Commit `feat(ios): FixturePlayer feeds UniFFI from bundled scenarios`

---

### Task 3: Find device exits + demo calibration flow

**Files:**
- Modify: `OnboardingStore.swift`, `FindDeviceView.swift`, `RootView.swift`
- Create: `DemoSetupView.swift`, `CalibrationView.swift`, `DemoCalibrationModel.swift`

**Interfaces:**
- Consumes: `FixturePlayer`, `FixtureScenario.wallPass` / `.wallFail`
- Produces: routes `demoSetup`, `calibration`; `calibrationStatus: enum { incomplete, demoPassed, skipped }`; `continueWithoutDevice()`, `startDemoDevice()`, pass/fail/skip handlers → Home

- [ ] **Step 1:** Find device UI: empty real list copy; row **Demo Gotcha Six**; button **Continue without device**.

- [ ] **Step 2:** Demo setup → Calibration: Start plays `wall_pass` by default; show distance/motion from player; pass when approaching + distance fallen; fail path via timeout or explicit “Play fail scenario”/replay with `wall_fail`; Skip for now → Home skipped.

- [ ] **Step 3:** Simulator walkthrough screenshots: continue-without-device; demo pass. Commit `feat(ios): demo device and continue-without-device calibration`

---

### Task 4: Home Play demo

**Files:**
- Modify: `HomeView.swift`
- Create: `DemoScenarioPicker.swift` (sheet or navigation)

**Interfaces:**
- Consumes: `FixturePlayer`, three scenarios
- Produces: overflow **Play demo** → picker → playback UI (reuse calibration readout for wall_*; alert_approach shows motion/distance + optional sample card)

- [ ] **Step 1:** Wire menu; label **Demo · no hardware**.

- [ ] **Step 2:** Screenshot picker + one playback. Commit `feat(ios): Home Play demo scenarios`

---

### Task 5: Visual polish (illustrations, accent, motion, copy)

**Files:**
- Modify: `Assets.xcassets/AccentColor`, Welcome/HowToA/B/C/Calibration views, Permissions copy
- Create: illustration assets under `ios/GotchaSix/Assets.xcassets` or `Resources/Illustrations/` with unDraw licence text file beside downloads; custom SVGs for How-to A + Calibration

**Interfaces:**
- Consumes: existing screen structure
- Produces: teal `#3d9b6e`; replace grey placeholders; light enter transitions; tighter copy per spec

- [ ] **Step 1:** Set accent; drop unDraw + SVGs (or interim SF-symbol composition only if asset acquisition blocks — prefer real assets; do not ship empty grey boxes).

- [ ] **Step 2:** Copy pass on each teaching screen. Simulator screenshots of Welcome, How-to A/B/C, Calibration.

- [ ] **Step 3:** Commit `feat(ios): onboarding illustrations and teal accent`

---

### Task 6: Spec status + PR

**Files:**
- Modify: design spec status → Accepted (same PR)
- Evidence: `artifacts/onboarding-polish/` screenshots

- [ ] **Step 1:** PR closes the tracking issue if one exists; otherwise reference the design spec. Note Slice 7 illustrations pulled forward; Slice 5 BLE still separate. Body: What / Why / How / Evidence.

- [ ] **Step 2:** Stack or single PR from `main` as appropriate (prefer one PR unless diff is huge).

---

## Out of scope

Real BLE, Live Activity session, How-to B wired to `alert_approach` (optional later), duplicate top-level `fixtures/` tree.
