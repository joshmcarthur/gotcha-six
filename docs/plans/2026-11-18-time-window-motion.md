# Time-window motion

**Goal:** 3 s lookback, 1 s min span, 15 cm band, slope as closing speed.

**Architecture:** Extend `DetectionEngine`. Pass `now_ms` from RadarEngine, UniFFI, WASM, lab replay, and iOS ingest. Fixtures keep their `t_ms` column.

**Tech stack:** `gotcha-six-core`, UniFFI, wasm-bindgen.

**Thermo-nuclear plan review: Approve** — already the judo; one ring in `DetectionEngine`.

## Files

| File | Change |
| --- | --- |
| `core/src/detection.rs` | Time ring, tests |
| `core/src/lib.rs` | `push_bytes_at`, 100 ms fallback |
| `core/src/uniffi_api.rs` | `push_bytes_at` |
| `core/src/wasm.rs` | `pushBytesAt` |
| `core/tests/fixture_engine.rs` | Per-line `t_ms` |
| `core/tests/fixtures/*.txt` | Stretch approach spans to ≥ 1 s |
| `lab/src/main.ts` | Pass `t` into the engine |
| `ios/.../RadarLink.swift` | `pushBytesAt` with session clock |
| `ios/.../FixturePlayer.swift` | Pass fixture `tMs` |

## Tests

- 20 cm close in 200 ms is Unknown.
- 20 cm close over 1 s is Approaching; closing speed is the slope.
- 20 cm close over 3 s is Approaching even if the last samples are flat.
- 10 cm over 1 s is Stationary.
- Hop that returns inside 15 cm of the start is not Approaching.
- Four empty frames still Lost.
