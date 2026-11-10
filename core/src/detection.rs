//! Derive approaching / receding from distance change over successive updates.
//!
//! Closing speed is the UART speed magnitude with the direction of the distance
//! change. Does not use UART speed sign. Does not fuse IMU.

use crate::tracking::TrackedTarget;

#[cfg(feature = "wasm")]
use serde::{Deserialize, Serialize};

/// Motion relative to the wearer (rear target).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg_attr(feature = "wasm", derive(Serialize, Deserialize))]
pub enum Motion {
    Approaching,
    Receding,
    Stationary,
    Lost,
    Unknown,
}

/// Motion and closing-speed estimator from distance deltas and radar speed.
#[derive(Debug)]
pub struct DetectionEngine {
    prev_distance_m: Option<f32>,
    prev_present: bool,
    /// Meters of distance change below which we call Stationary.
    stationary_eps_m: f32,
}

impl Default for DetectionEngine {
    fn default() -> Self {
        Self {
            prev_distance_m: None,
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
        self.prev_distance_m = None;
        self.prev_present = false;
    }

    /// Observe a tracked target update.
    ///
    /// Returns (motion, closing_speed_m_s). Closing speed is in metres per
    /// second: the radar speed magnitude, positive when approaching, negative
    /// when receding, and zero when stationary. The direction comes from the
    /// distance change since the last update. It is `None` on the first
    /// reading, when the target is lost, or when the radar gave no speed.
    pub fn observe(&mut self, tracked: &TrackedTarget) -> (Motion, Option<f32>) {
        if !tracked.present {
            let was = self.prev_present;
            self.prev_present = false;
            self.prev_distance_m = None;
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

        let result = if let Some(prev) = self.prev_distance_m {
            let delta = dist - prev; // positive => farther
            let speed = tracked.speed_m_s.map(f32::abs);
            if delta.abs() <= self.stationary_eps_m {
                (Motion::Stationary, speed.and(Some(0.0)))
            } else if delta < 0.0 {
                (Motion::Approaching, speed)
            } else {
                (Motion::Receding, speed.map(|s| -s))
            }
        } else {
            (Motion::Unknown, None)
        };

        self.prev_distance_m = Some(dist);
        self.prev_present = true;
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
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

    #[test]
    fn approaching_when_distance_falls() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let t1 = tracker.update(&target(10.0));
        assert_eq!(det.observe(&t1).0, Motion::Unknown);
        let t2 = tracker.update(&target(8.0));
        let (m, closing) = det.observe(&t2);
        assert_eq!(m, Motion::Approaching);
        assert_eq!(closing, Some(0.5));
    }

    #[test]
    fn receding_when_distance_rises() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = det.observe(&tracker.update(&target(5.0)));
        let (m, closing) = det.observe(&tracker.update(&target(7.0)));
        assert_eq!(m, Motion::Receding);
        assert_eq!(closing, Some(-0.5));
    }

    #[test]
    fn stationary_within_epsilon() {
        let mut tracker = Tracker::new();
        let mut det = DetectionEngine::new();
        let _ = det.observe(&tracker.update(&target(5.0)));
        let (m, closing) = det.observe(&tracker.update(&target(5.02)));
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
}
