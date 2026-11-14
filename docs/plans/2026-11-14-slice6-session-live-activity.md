# Slice 6: Session, Live Activity, alerts

**Goal:** With BLE connected, Start session → Live Activity + AlertGate interrupts on approaching (including locked); End session leaves BLE up.

**Architecture:** One `SessionController` on existing `RadarLink` + `UniffiAlertGate`. Replace the Activity stub with ActivityKit UI. No new BLE stack. No extra screens — Home only.

**Tech stack:** ActivityKit, UserNotifications (time-sensitive), UniFFI `UniffiAlertGate`, existing Core Bluetooth link.

**Thermo-nuclear:** Approve.

## Constraints

- Start requires BLE. Reset engine + gate. Keep NUS notify on.
- Live Activity: connection, motion, distance. No art/buttons. Update on connection/motion or ≥0.5 m, ≤ ~1 Hz. No target → `None`.
- Alerts: AlertGate + time-sensitive local notification; foreground haptic matches How-to B.
- Link drop: Disconnected on activity, one interrupt, reconnect + reset; 5 minutes down → end session.
- End session stops alerts/activity; BLE stays connected.

## Commits

1. Live Activity attributes + UI (drop placeholder widget).
2. `SessionController` + Home Start/End + throttled updates.
3. AlertGate → notify + haptic; disconnect interrupt + 5 min timeout.
4. Evidence + PR closes #11.

## Out of scope

Watch app, extra widgets, custom sounds, bonding, demo-fixture session alerts.
