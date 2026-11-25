# Detection session corpus

**Path:** `docs/specs/2026-11-19-detection-story-corpus-design.md`  
**Author:** Josh McArthur (joshua.mcarthur@gmail.com)  
**Created:** 2026-11-19  
**Status:** Accepted  
**Parent:** [Time-window motion](./2026-11-18-time-window-motion-design.md)

## Objective

Fill the test suite with many realistic radar sessions, including ones nobody listed, and assert when motion should change.

## Background

Hand fixtures and `simulateApproach` are a few linear closes. Tests only check that Approaching appears somewhere. A hop and a real close both pass.

## Goals

- A good LLM writes lab-format sessions and the expected behaviour for each one.
- `cargo test` plays every committed session through `RadarEngine` and checks those expectations.
- The prompt includes the 3 s lookback, 1 s min span, 15 cm band, and four-empty-frame Lost rule.

## Non-goals

- A story compiler or second oracle. Live CI fuzz. Calling an LLM from tests. Replacing the hand fixtures.

## Files

Under `core/tests/fixtures/generated/`:

- `*.txt` — `<t_ms>\t<raw line>` (same as lab export).
- `*.expect.json` — expected windows, for example first Approaching in `[t0, t1]`, none before `t0`, Lost after `t_lost` when the session ends empty.

## Authoring

An agent prompt asks for many realistic cases (slow jogger, fast bike, hop then close, dropout mid-close, just over / just under 15 cm, standstill jitter). The model outputs the two files per case. A person or agent skims a few, then commits. Tests do not call a network.

If the engine and the file disagree, the test fails. Inspect: the session may be unrealistic, or the expected window may be wrong, or the detector may be wrong.

## Constraints

- Line format stays `<t_ms>\t<raw line>`.
- `AlertGate` is out of scope for v1.
- Do not fill expected windows by copying current engine output.
