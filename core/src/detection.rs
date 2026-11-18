//! Derive approaching / receding from distance change over a time window.
//!
//! Closing speed is the slope of distance over that window. Positive means
//! approaching. Does not use UART speed. Does not fuse IMU. A target must be
//! absent for four frames before motion is Lost.

use std::collections::VecDeque;

use crate::tracking::TrackedTarget;

#[cfg(feature = "wasm")]
use serde::{Deserialize, Serialize};

/// Consecutive absent `$DFDMD` frames before motion becomes Lost.
const LOST_HOLD_SAMPLES: usize = 4;
/// Metres of windowed distance change below which we call Stationary.
const STATIONARY_EPS_M: f32 = 0.15;
/// Lookback used to compare newest vs oldest distance.
const WINDOW_MS: u64 = 3000;
/// Minimum span before Approaching or Receding.
const MIN_SPAN_MS: u64 = 1000;
/// Cap so observe never grows without bound.
const RING_CAP: usize = 128;

/// Motion relative to the wearer (rear target).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "wasm", derive(Serialize, Deserialize))]
#[cfg_attr(feature = "uniffi", derive(uniffi::Enum))]
pub enum Motion {
    Approaching,
    Receding,
    Stationary,
    Lost,
    Unknown,
}

/// Motion and closing-speed estimator from a timed distance window.
#[derive(Debug)]
pub struct DetectionEngine {
    samples: VecDeque<(u64, f32)>,
    prev_present: bool,
    absent_count: usize,
}

impl Default for DetectionEngine {
    fn default() -> Self {
        Self {
            samples: VecDeque::with_capacity(RING_CAP),
            prev_present: false,
            absent_count: 0,
        }
    }
}

impl DetectionEngine {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn reset(&mut self) {
        self.samples.clear();
        self.prev_present = false;
        self.absent_count = 0;
    }

    /// Observe a tracked target update at `now_ms`.
    ///
    /// Returns (motion, closing_speed_m_s). Closing speed is the slope of
    /// distance over the lookback: positive when approaching, negative when
    /// receding, zero when stationary. It is `None` before the min span
    /// fills, when the target is lost, or when fewer than two samples exist.
    pub fn observe(&mut self, tracked: &TrackedTarget, now_ms: u64) -> (Motion, Option<f32>) {
        if !tracked.present {
            return self.observe_absent(now_ms);
        }

        let Some(dist) = tracked.distance_m else {
            self.prev_present = true;
            self.absent_count = 0;
            return (Motion::Unknown, None);
        };

        self.absent_count = 0;
        self.samples.push_back((now_ms, dist));
        self.prune(now_ms);
        self.prev_present = true;
        self.classify()
    }

    /// Keep the distance window until Lost so a return mid-coast still
    /// classifies against the last present samples.
    fn observe_absent(&mut self, now_ms: u64) -> (Motion, Option<f32>) {
        if !self.prev_present {
            return (Motion::Unknown, None);
        }
        self.absent_count = self.absent_count.saturating_add(1);
        if self.absent_count < LOST_HOLD_SAMPLES {
            self.prune(now_ms);
            return (Motion::Stationary, Some(0.0));
        }
        self.prev_present = false;
        self.absent_count = 0;
        self.samples.clear();
        (Motion::Lost, None)
    }

    fn prune(&mut self, now_ms: u64) {
        let oldest_keep = now_ms.saturating_sub(WINDOW_MS);
        while self.samples.front().is_some_and(|(t, _)| *t < oldest_keep) {
            self.samples.pop_front();
        }
        while self.samples.len() > RING_CAP {
            self.samples.pop_front();
        }
    }

    fn classify(&self) -> (Motion, Option<f32>) {
        let Some(&(oldest_t, oldest_d)) = self.samples.front() else {
            return (Motion::Unknown, None);
        };
        let Some(&(newest_t, newest_d)) = self.samples.back() else {
            return (Motion::Unknown, None);
        };
        if newest_t <= oldest_t {
            return (Motion::Unknown, None);
        }
        let span_ms = newest_t - oldest_t;
        let delta = newest_d - oldest_d; // positive => farther
        if delta.abs() <= STATIONARY_EPS_M {
            return (Motion::Stationary, Some(0.0));
        }
        if span_ms < MIN_SPAN_MS {
            return (Motion::Unknown, None);
        }
        let dt_s = span_ms as f32 / 1000.0;
        let slope = -delta / dt_s; // positive when approaching
        if delta < 0.0 {
            (Motion::Approaching, Some(slope))
        } else {
            (Motion::Receding, Some(slope))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::alert_gate::{AlertGate, OutputKind};
    use crate::protocol::Target;
    use crate::tracking::Tracker;

    fn target(distance: f32) -> Target {
        Target {
            count: 1,
            id: Some(1),
            distance_m: Some(distance),
            speed_m_s: Some(0.5),
            energy: Some(100),
            raw: String::new(),
        }
    }

    fn empty() -> Target {
        Target {
            count: 0,
            id: None,
            distance_m: None,
            speed_m_s: None,
            energy: None,
            raw: String::new(),
        }
    }

    fn observe_dist(
        det: &mut DetectionEngine,
        tracker: &mut Tracker,
        distance: f32,
    ) -> (Motion, Option<f32>) {
        observe_at(det, tracker, distance, 0)
    }

    fn observe_at(
        det: &mut DetectionEngine,
        tracker: &mut Tracker,
        distance: f32,
        now_ms: u64,
    ) -> (Motion, Option<f32>) {
        det.observe(&tracker.update(&target(distance)), now_ms)
    }

    fn observe_empty(det: &mut DetectionEngine, tracker: &mut Tracker) -> (Motion, Option<f32>) {
        det.observe(&tracker.update(&empty()), 0)
    }

    #[test]
    fn two_samples_stay_unknown_until_a_third() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        assert_eq!(
            observe_dist(&mut det, &mut tracker, 10.0).0,
            Motion::Unknown
        );
        assert_eq!(observe_dist(&mut det, &mut tracker, 8.0).0, Motion::Unknown);
    }

    #[test]
    fn approaching_after_one_second_when_range_falls() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        assert_eq!(
            observe_at(&mut det, &mut tracker, 12.0, 0).0,
            Motion::Unknown
        );
        assert_eq!(
            observe_at(&mut det, &mut tracker, 11.0, 500).0,
            Motion::Unknown
        );
        let (m, closing) = observe_at(&mut det, &mut tracker, 10.0, 1000);
        assert_eq!(m, Motion::Approaching);
        assert_eq!(closing, Some(2.0));
    }

    #[test]
    fn receding_after_one_second_when_range_rises() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        assert_eq!(observe_at(&mut det, &mut tracker, 5.0, 0).0, Motion::Unknown);
        assert_eq!(
            observe_at(&mut det, &mut tracker, 7.0, 500).0,
            Motion::Unknown
        );
        let (m, closing) = observe_at(&mut det, &mut tracker, 9.0, 1000);
        assert_eq!(m, Motion::Receding);
        assert_eq!(closing, Some(-4.0));
    }

    #[test]
    fn single_dip_in_window_is_not_approaching() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        assert_eq!(
            observe_dist(&mut det, &mut tracker, 12.0).0,
            Motion::Unknown
        );
        assert_eq!(
            observe_dist(&mut det, &mut tracker, 11.5).0,
            Motion::Unknown
        );
        assert_ne!(
            observe_dist(&mut det, &mut tracker, 12.0).0,
            Motion::Approaching
        );
    }

    #[test]
    fn stationary_within_epsilon() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_at(&mut det, &mut tracker, 5.0, 0);
        let (m, closing) = observe_at(&mut det, &mut tracker, 5.02, 1000);
        assert_eq!(m, Motion::Stationary);
        assert_eq!(closing, Some(0.0));
    }

    #[test]
    fn ten_cm_over_one_second_is_stationary() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_at(&mut det, &mut tracker, 5.0, 0);
        let (m, closing) = observe_at(&mut det, &mut tracker, 5.10, 1000);
        assert_eq!(m, Motion::Stationary);
        assert_eq!(closing, Some(0.0));
    }

    #[test]
    fn lost_after_four_empty_frames() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_dist(&mut det, &mut tracker, 5.0);
        assert_eq!(observe_empty(&mut det, &mut tracker).0, Motion::Stationary);
        assert_eq!(observe_empty(&mut det, &mut tracker).0, Motion::Stationary);
        assert_eq!(observe_empty(&mut det, &mut tracker).0, Motion::Stationary);
        assert_eq!(observe_empty(&mut det, &mut tracker).0, Motion::Lost);
    }

    #[test]
    fn one_empty_then_target_does_not_emit_lost() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_dist(&mut det, &mut tracker, 5.0);
        assert_eq!(observe_empty(&mut det, &mut tracker).0, Motion::Stationary);
        assert_ne!(observe_dist(&mut det, &mut tracker, 5.0).0, Motion::Lost);
    }

    #[test]
    fn brief_drop_does_not_rearm_alert_gate() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let mut gate = AlertGate::new();
        gate.set_session_on(true);

        let (m1, _) = observe_at(&mut det, &mut tracker, 12.0, 0);
        let (m2, _) = observe_at(&mut det, &mut tracker, 11.0, 500);
        let (m3, _) = observe_at(&mut det, &mut tracker, 10.0, 1000);
        assert!(!gate.observe(OutputKind::Target, m1, Some(12.0), 0));
        assert!(!gate.observe(OutputKind::Target, m2, Some(11.0), 500));
        assert!(gate.observe(OutputKind::Target, m3, Some(10.0), 1000));

        let (empty_motion, _) = observe_empty(&mut det, &mut tracker);
        assert!(!gate.observe(OutputKind::Target, empty_motion, None, 1100));

        let (m4, _) = observe_at(&mut det, &mut tracker, 9.5, 1200);
        assert!(!gate.observe(OutputKind::Target, m4, Some(9.5), 1200));
    }

    #[test]
    fn imu_does_not_affect_motion_path() {
        // DetectionEngine only sees TrackedTarget; IMU never reaches it.
        let mut det = DetectionEngine::new();
        assert_eq!(det.observe(&TrackedTarget::default(), 0).0, Motion::Unknown);
    }

    #[test]
    fn standstill_jitter_is_never_approaching() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let samples = [12.00, 12.10, 12.00, 12.08, 11.95, 12.05, 12.00];
        let mut now_ms = 0_u64;
        for distance in samples {
            assert_ne!(
                observe_at(&mut det, &mut tracker, distance, now_ms).0,
                Motion::Approaching
            );
            now_ms += 200;
        }
    }

    #[test]
    fn jitter_then_real_approach_fires_one_alert() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let mut gate = AlertGate::new();
        gate.set_session_on(true);

        let mut fires = 0_u32;
        let mut now_ms = 0_u64;
        let samples = [
            12.0, 11.5, 12.0, 11.5, 12.0, 11.8, 12.2, 11.9, 11.0, 10.0, 9.0,
        ];
        for distance in samples {
            let (motion, _) = observe_at(&mut det, &mut tracker, distance, now_ms);
            if gate.observe(OutputKind::Target, motion, Some(distance), now_ms) {
                fires += 1;
            }
            now_ms += 100;
        }
        assert_eq!(fires, 1);
    }

    #[test]
    fn twenty_cm_in_200ms_stays_unknown() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_at(&mut det, &mut tracker, 12.0, 0);
        let _ = observe_at(&mut det, &mut tracker, 11.9, 100);
        let (m, _) = observe_at(&mut det, &mut tracker, 11.8, 200);
        assert_eq!(m, Motion::Unknown);
    }

    #[test]
    fn twenty_cm_over_three_seconds_is_approaching_when_last_samples_are_flat() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_at(&mut det, &mut tracker, 12.00, 0);
        let _ = observe_at(&mut det, &mut tracker, 11.85, 2800);
        let _ = observe_at(&mut det, &mut tracker, 11.82, 2900);
        let (m, closing) = observe_at(&mut det, &mut tracker, 11.80, 3000);
        assert_eq!(m, Motion::Approaching);
        let slope = closing.expect("slope");
        assert!((slope - (12.00 - 11.80) / 3.0).abs() < 1e-5);
    }

    #[test]
    fn twenty_cm_over_one_second_is_approaching() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_at(&mut det, &mut tracker, 12.0, 0);
        let (m, closing) = observe_at(&mut det, &mut tracker, 11.8, 1000);
        assert_eq!(m, Motion::Approaching);
        let slope = closing.expect("slope");
        assert!((slope - 0.2).abs() < 1e-5);
    }

    #[test]
    fn hop_returning_inside_band_is_not_approaching() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = observe_at(&mut det, &mut tracker, 12.0, 0);
        let _ = observe_at(&mut det, &mut tracker, 10.0, 500);
        let (m, _) = observe_at(&mut det, &mut tracker, 12.05, 1000);
        assert_ne!(m, Motion::Approaching);
        assert_eq!(m, Motion::Stationary);
    }
}
