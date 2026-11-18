# Time-window motion

**Path:** `docs/specs/2026-11-18-time-window-motion-design.md`  
**Author:** Josh McArthur (joshua.mcarthur@gmail.com)  
**Created:** 2026-11-18  
**Status:** Accepted  
**Parent:** Lore decision “Motion label uses a distance window”

## Objective

Label approaching only when rear range has fallen by more than 15 cm and that close has lasted about one second, using up to three seconds of history.

## Background

A 3-sample window is a few hundred milliseconds at 10 Hz. A 15 cm hop still looks like approaching. A slow real close can look stationary if the last three samples are flat. Lore already chose distance over time. That rule was not built.

## Goals

- Keep a 3 second lookback of `(t_ms, distance_m)`.
- Do not label approaching or receding until the span is at least 1 second.
- Hold band 15 cm on newest vs oldest in that lookback.
- Closing speed is the slope of that window. UART speed stays a display field.
- Four empty `$DFDMD` frames still coast as Stationary and keep the ring. Then Lost.

## Non-goals

- Dual distance/time thresholds. IMU fusion. Preset retune. Device-side alerts.

## Constraints

- Callers pass `now_ms` so replay uses the recording clock.
- Live streams with no clock use 100 ms per target line.
- `AlertGate` 2 s / 1 m stays.
- Ring cap 128. No extra allocation on the observe path beyond the deque.

## Interfaces

`DetectionEngine::observe(tracked, now_ms)`. `RadarEngine::push_bytes_at(now_ms, data)`. UniFFI and WASM expose the timed push. `push_bytes` keeps the 100 ms fallback.
