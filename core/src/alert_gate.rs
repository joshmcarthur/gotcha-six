//! Session alert debounce: when to interrupt for an approaching target.

use crate::detection::Motion;

/// Kind of engine output, for alert policy (IMU/presence never fire).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OutputKind {
    Presence,
    Target,
    Imu,
    Unknown,
}

const MIN_ALERT_INTERVAL_MS: u64 = 2000;
const MIN_CLOSER_M: f32 = 1.0;

/// Decides whether a session observation should fire an approaching alert.
///
/// Callers inject `now_ms` so the gate is deterministic on Linux CI.
#[derive(Debug, Default)]
pub struct AlertGate {
    session_on: bool,
    in_close: bool,
    last_alert_at_ms: Option<u64>,
    last_alert_distance_m: Option<f32>,
}

impl AlertGate {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn set_session_on(&mut self, on: bool) {
        self.session_on = on;
        if !on {
            self.clear_close();
        }
    }

    pub fn reset(&mut self) {
        self.session_on = false;
        self.clear_close();
    }

    /// Returns true when an alert should fire for this observation.
    pub fn observe(
        &mut self,
        kind: OutputKind,
        motion: Motion,
        distance_m: Option<f32>,
        now_ms: u64,
    ) -> bool {
        if !self.session_on {
            return false;
        }

        if kind != OutputKind::Target || motion != Motion::Approaching {
            self.clear_close();
            return false;
        }

        let Some(distance_m) = distance_m else {
            self.clear_close();
            return false;
        };

        if !self.in_close {
            self.in_close = true;
            self.last_alert_at_ms = Some(now_ms);
            self.last_alert_distance_m = Some(distance_m);
            return true;
        }

        let Some(last_at) = self.last_alert_at_ms else {
            self.last_alert_at_ms = Some(now_ms);
            self.last_alert_distance_m = Some(distance_m);
            return true;
        };
        let Some(last_dist) = self.last_alert_distance_m else {
            self.last_alert_at_ms = Some(now_ms);
            self.last_alert_distance_m = Some(distance_m);
            return true;
        };

        let elapsed = now_ms.saturating_sub(last_at);
        let closer = last_dist - distance_m;
        if elapsed >= MIN_ALERT_INTERVAL_MS && closer >= MIN_CLOSER_M {
            self.last_alert_at_ms = Some(now_ms);
            self.last_alert_distance_m = Some(distance_m);
            return true;
        }

        false
    }

    fn clear_close(&mut self) {
        self.in_close = false;
        self.last_alert_at_ms = None;
        self.last_alert_distance_m = None;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn session_off_never_fires() {
        let mut gate = AlertGate::new();
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
    }

    #[test]
    fn first_approaching_fires() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 100));
    }

    #[test]
    fn second_within_window_does_not_fire() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(11.5), 500));
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(10.5), 1500));
    }

    #[test]
    fn fires_again_after_2s_and_1m_closer() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(10.5), 2000));
    }

    #[test]
    fn two_seconds_but_not_1m_closer_does_not_fire() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(11.2), 2500));
    }

    #[test]
    fn receding_then_approaching_is_new_first_close() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        assert!(!gate.observe(OutputKind::Target, Motion::Receding, Some(13.0), 100));
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.5), 200));
    }

    #[test]
    fn imu_and_presence_never_fire() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(!gate.observe(OutputKind::Imu, Motion::Approaching, Some(5.0), 0));
        assert!(!gate.observe(OutputKind::Presence, Motion::Approaching, Some(5.0), 1));
        assert!(!gate.observe(OutputKind::Unknown, Motion::Approaching, Some(5.0), 2));
    }

    #[test]
    fn session_end_clears_and_stops_firing() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        gate.set_session_on(false);
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(10.0), 5000));
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(10.0), 6000));
    }

    #[test]
    fn reset_clears_session() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        gate.reset();
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(8.0), 5000));
    }

    #[test]
    fn approaching_without_distance_ends_close() {
        let mut gate = AlertGate::new();
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(12.0), 0));
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, None, 100));
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(11.0), 200));
    }
}
