//! Derive approaching / receding from distance change over a short window.
//!
//! Closing speed is the UART speed magnitude with the direction of the windowed
//! distance change. Does not use UART speed sign. Does not fuse IMU.

use std::collections::VecDeque;

use crate::tracking::TrackedTarget;

#[cfg(feature = "wasm")]
use serde::{Deserialize, Serialize};

/// Samples required before emitting Approaching or Receding.
const MOTION_WINDOW: usize = 3;

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

/// Motion and closing-speed estimator from a short distance window.
#[derive(Debug)]
pub struct DetectionEngine {
    distances_m: VecDeque<f32>,
    prev_present: bool,
    /// Meters of windowed distance change below which we call Stationary.
    stationary_eps_m: f32,
}

impl Default for DetectionEngine {
    fn default() -> Self {
        Self {
            distances_m: VecDeque::with_capacity(MOTION_WINDOW),
            prev_present: false,
            stationary_eps_m: 0.05,
        }
    }
}

impl DetectionEngine {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn reset(&mut self) {
        self.distances_m.clear();
        self.prev_present = false;
    }

    /// Observe a tracked target update.
    ///
    /// Returns (motion, closing_speed_m_s). Closing speed is in metres per
    /// second: the radar speed magnitude, positive when approaching, negative
    /// when receding, and zero when stationary. Direction is newest minus
    /// oldest in a 3-sample window, so a single dip does not count as
    /// approaching. It is `None` before the window fills, when the target is
    /// lost, or when the radar gave no speed.
    pub fn observe(&mut self, tracked: &TrackedTarget) -> (Motion, Option<f32>) {
        if !tracked.present {
            let was = self.prev_present;
            self.prev_present = false;
            self.distances_m.clear();
            return if was {
                (Motion::Lost, None)
            } else {
                (Motion::Unknown, None)
            };
        }

        let Some(dist) = tracked.distance_m else {
            self.prev_present = true;
            return (Motion::Unknown, None);
        };

        self.distances_m.push_back(dist);
        while self.distances_m.len() > MOTION_WINDOW {
            self.distances_m.pop_front();
        }
        self.prev_present = true;
        self.classify(tracked.speed_m_s)
    }

    fn classify(&self, speed_m_s: Option<f32>) -> (Motion, Option<f32>) {
        let speed = speed_m_s.map(f32::abs);
        if self.distances_m.len() < 2 {
            return (Motion::Unknown, None);
        }
        let Some((&oldest, &newest)) = self.distances_m.front().zip(self.distances_m.back()) else {
            return (Motion::Unknown, None);
        };
        let delta = newest - oldest; // positive => farther
        if delta.abs() <= self.stationary_eps_m {
            return (Motion::Stationary, speed.and(Some(0.0)));
        }
        if self.distances_m.len() < MOTION_WINDOW {
            return (Motion::Unknown, None);
        }
        if delta < 0.0 {
            (Motion::Approaching, speed)
        } else {
            (Motion::Receding, speed.map(|s| -s))
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
        det.observe(&tracker.update(&target(distance)))
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
    fn approaching_on_third_sample_when_window_falls() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        assert_eq!(
            observe_dist(&mut det, &mut tracker, 12.0).0,
            Motion::Unknown
        );
        assert_eq!(
            observe_dist(&mut det, &mut tracker, 11.0).0,
            Motion::Unknown
        );
        let (m, closing) = observe_dist(&mut det, &mut tracker, 10.0);
        assert_eq!(m, Motion::Approaching);
        assert_eq!(closing, Some(0.5));
    }

    #[test]
    fn receding_on_third_sample_when_window_rises() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        assert_eq!(observe_dist(&mut det, &mut tracker, 5.0).0, Motion::Unknown);
        assert_eq!(observe_dist(&mut det, &mut tracker, 7.0).0, Motion::Unknown);
        let (m, closing) = observe_dist(&mut det, &mut tracker, 9.0);
        assert_eq!(m, Motion::Receding);
        assert_eq!(closing, Some(-0.5));
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
        let _ = observe_dist(&mut det, &mut tracker, 5.0);
        let (m, closing) = observe_dist(&mut det, &mut tracker, 5.02);
        assert_eq!(m, Motion::Stationary);
        assert_eq!(closing, Some(0.0));
    }

    #[test]
    fn lost_after_target_gone() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = det.observe(&tracker.update(&target(5.0)));
        let (m, _) = det.observe(&tracker.update(&empty()));
        assert_eq!(m, Motion::Lost);
    }

    #[test]
    fn imu_does_not_affect_motion_path() {
        // DetectionEngine only sees TrackedTarget; IMU never reaches it.
        let mut det = DetectionEngine::new();
        assert_eq!(det.observe(&TrackedTarget::default()).0, Motion::Unknown);
    }

    #[test]
    fn standstill_jitter_is_never_approaching() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        for distance in [12.0, 11.5, 12.0, 11.5, 12.0, 11.5, 12.0] {
            assert_ne!(
                observe_dist(&mut det, &mut tracker, distance).0,
                Motion::Approaching
            );
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
            let (motion, _) = observe_dist(&mut det, &mut tracker, distance);
            if gate.observe(OutputKind::Target, motion, Some(distance), now_ms) {
                fires += 1;
            }
            now_ms += 100;
        }
        assert_eq!(fires, 1);
    }
}
