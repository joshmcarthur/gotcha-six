//! Single-target tracking across successive `$DFDMD` readings.

use crate::protocol::Target;

/// Last known target view used by detection.
#[derive(Debug, Clone, PartialEq)]
pub struct TrackedTarget {
    pub present: bool,
    pub distance_m: Option<f32>,
    pub speed_m_s: Option<f32>,
    pub energy: Option<u32>,
    pub id: Option<u8>,
}

impl Default for TrackedTarget {
    fn default() -> Self {
        Self {
            present: false,
            distance_m: None,
            speed_m_s: None,
            energy: None,
            id: None,
        }
    }
}

/// Maintains one target slot (C4001 reports at most one).
#[derive(Debug, Default)]
pub struct Tracker {
    current: TrackedTarget,
}

impl Tracker {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn reset(&mut self) {
        self.current = TrackedTarget::default();
    }

    pub fn current(&self) -> &TrackedTarget {
        &self.current
    }

    pub fn update(&mut self, target: &Target) -> TrackedTarget {
        if target.count == 0 || target.distance_m.is_none() {
            self.current = TrackedTarget {
                present: false,
                distance_m: None,
                speed_m_s: None,
                energy: None,
                id: None,
            };
        } else {
            self.current = TrackedTarget {
                present: true,
                distance_m: target.distance_m,
                speed_m_s: target.speed_m_s,
                energy: target.energy,
                id: target.id,
            };
        }
        self.current.clone()
    }
}
