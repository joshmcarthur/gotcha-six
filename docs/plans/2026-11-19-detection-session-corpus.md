# Detection session corpus

**Goal:** Committed LLM sessions with expected windows; `cargo test` checks `RadarEngine`.

**Architecture:** Extend `fixture_engine.rs`. Each case is `generated/*.txt` plus `*.expect.json`. No compiler. No new detector.

**Tech stack:** `gotcha-six-core` tests, `serde_json` dev-dependency.

**Thermo-nuclear plan review: Approve** — already the judo; glob fixtures, do not build a story language.

## Files

| File | Change |
| --- | --- |
| `core/Cargo.toml` | `serde` + `serde_json` dev-deps |
| `core/tests/fixture_engine.rs` | Load generated cases, assert windows |
| `core/tests/fixtures/generated/*.txt` | Sessions |
| `core/tests/fixtures/generated/*.expect.json` | Expected windows |
| `core/tests/fixtures/generated/PROMPT.md` | Authoring prompt for more cases |

## Tests

Each generated session: first Approaching in the given window (or never), Lost in the given window when set.
