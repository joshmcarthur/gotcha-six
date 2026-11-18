# Detection knobs and session recording

**Path:** `docs/specs/2026-11-18-detection-knobs-session-recording-design.md`  
**Author:** Josh McArthur (joshua.mcarthur@gmail.com)  
**Created:** 2026-11-18  
**Status:** Accepted  
**Parent:** [Pocket session](./2026-11-14-companion-app-design.md)  
**Repo:** [joshmcarthur/gotcha-six](https://github.com/joshmcarthur/gotcha-six)

## Objective

Cut false approaching alerts from bounce and brief radar drop-outs, without retuning the C4001, and let a wearer record a run on the phone in the same text format the lab already imports.

## Background

Session alerts still fire on small distance dips and on a single empty `$DFDMD` (that `Lost` re-arms `AlertGate` as a new first close). Smoothing (#31) uses a 3-sample window and a 5 cm band. A later dual-threshold, time-based detector needs real run files. The lab can record those files. A pocket run cannot use the lab. The companion spec previously left recording out of v1.

## Goals

- A 15 cm hold band: smaller windowed change is `Stationary`.
- Four consecutive absent `$DFDMD` frames before `Lost`. Fewer absences coast as `Stationary` and keep the current close.
- Live Activity shows `None` when count is 0, not the last distance.
- Every session writes a lab-format recording on the phone. Home can share the last file.

## Non-goals

- Time-based motion window, hop reject, urgent/sustained dual threshold.
- IMU fusion. Preset changes (`setThrFactor`, range).
- In-app replay, CSV, cloud upload, GPS.
- Watch app. Classifying runner vs cyclist vs vehicle.

## Scenarios

**Scenario: Stand still during a session**

Distance jitters by 8–12 cm, or the module drops one or two frames. Motion stays `Stationary`. No new approaching interrupt.

**Scenario: Real close**

Distance falls by more than 15 cm across the 3-sample window. Motion is `Approaching`. `AlertGate` fires on the first close, then on 2 s and 1 m closer as today.

**Scenario: Record a run**

Start session. Phone stays locked. End session. Home shows Share last recording. The file opens in the lab Import path with no edits.

## Constraints

- Detection stays in `gotcha-six-core`. Lab and phone stay in lockstep.
- Recording format is the lab text export: `<t_ms>\t<raw line>`.
- `t_ms` is milliseconds from session start (the same clock `AlertGate` uses).
- Record complete parsed lines only (`$DFDMD`, `$GSIMU`, `$GSPWR`, unknown). Not BLE byte chunks.
- Write the file during the run so a jetsam does not wipe it. Cap about 8 MB; stop appending if the cap is hit.
- Next Start session replaces the file.
- Share is user-initiated. No automatic upload.

## Interfaces

**Core `DetectionEngine`**

- `stationary_eps_m` default `0.15`.
- `LOST_HOLD_SAMPLES = 4`.
- 3-sample window unchanged.

**UniFFI `EngineOutput`**

- Add `raw: String` (WASM already has `raw`).

**iOS**

- `SessionLog` owns `last-session.txt` under Application Support.
- `RadarLink` starts/stops the log with the session and appends each `EngineOutput.raw`.
- Home: Share last recording when a file exists and the session is off.

## Privacy

The file is local radar/IMU lines. No location. The wearer chooses Share.

## Resolved issues

**Decision:** Raise hold band and Lost coast only. Do not add timestamps or a dual-threshold detector in this slice.  
A dual-threshold design needs a real run file. Recording is the way to get that file.

**Decision:** Recording is automatic with Start/End. No extra toggle.

**Decision:** Leave `setThrFactor 5` and range 25 m until a capture exists.

This supersedes “No recording of sessions to disk in v1” in the companion spec.
