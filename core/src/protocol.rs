//! Structured C4001 / Gotcha Six line types.

#[cfg(feature = "wasm")]
use serde::{Deserialize, Serialize};

/// Parsed presence report (`$DFHPD`).
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "wasm", derive(Serialize, Deserialize))]
pub struct Presence {
    pub detected: bool,
    pub raw: String,
}

/// Parsed target report (`$DFDMD`). At most one target.
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "wasm", derive(Serialize, Deserialize))]
pub struct Target {
    pub count: u8,
    pub id: Option<u8>,
    pub distance_m: Option<f32>,
    pub speed_m_s: Option<f32>,
    pub energy: Option<u32>,
    pub raw: String,
}

/// Parsed IMU sample (`$GSIMU`).
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "wasm", derive(Serialize, Deserialize))]
pub struct ImuSample {
    pub accel_m_s2: [f32; 3],
    pub gyro_rad_s: [f32; 3],
    pub raw: String,
}

/// Events emitted by the line parser.
#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "wasm", derive(Serialize, Deserialize))]
pub enum RadarEvent {
    Presence(Presence),
    Target(Target),
    Imu(ImuSample),
    Unknown { raw: String },
}
