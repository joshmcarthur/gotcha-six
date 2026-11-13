//! Gotcha Six core: C4001 / IMU line parsing, tracking, and motion interpretation.
//!
//! This crate does not know about USB, BLE, browsers, or mobile OS APIs.
//! Feed it bytes; it emits structured events.

#![cfg_attr(not(test), deny(clippy::unwrap_used))]

#[cfg(all(feature = "wasm", feature = "uniffi"))]
compile_error!("features `wasm` and `uniffi` cannot be enabled together");

#[cfg(feature = "uniffi")]
uniffi::setup_scaffolding!();

mod alert_gate;
mod detection;
mod parser;
mod preset;
mod protocol;
mod tracking;

pub use alert_gate::{AlertGate, OutputKind, DEFAULT_MIN_ALERT_INTERVAL_MS, DEFAULT_MIN_CLOSER_M};
pub use detection::{DetectionEngine, Motion};
pub use parser::RadarParser;
pub use preset::{encode_command_line, GOTCHA_SIX_PRESET, PRESET_GAP_MS};
pub use protocol::{ImuSample, Presence, RadarEvent, Target};
pub use tracking::{TrackedTarget, Tracker};

#[cfg(feature = "wasm")]
mod wasm;

#[cfg(feature = "uniffi")]
mod uniffi_api;

/// Combined parser + tracker + detector.
#[derive(Debug, Default)]
pub struct RadarEngine {
    parser: RadarParser,
    tracker: Tracker,
    detector: DetectionEngine,
}

/// One parsed event plus derived motion fields.
#[derive(Debug, Clone, PartialEq)]
pub struct RadarOutput {
    pub event: RadarEvent,
    pub motion: Motion,
    /// Metres per second. Positive when the target approaches, negative when
    /// it recedes, zero when stationary. `None` when not known.
    pub closing_speed_m_s: Option<f32>,
}

impl RadarEngine {
    pub fn new() -> Self {
        Self::default()
    }

    /// Push raw transport bytes. Returns zero or more outputs.
    pub fn push_bytes(&mut self, data: &[u8]) -> Vec<RadarOutput> {
        let events = self.parser.push_bytes(data);
        let mut out = Vec::with_capacity(events.len());
        for event in events {
            out.push(self.handle_event(event));
        }
        out
    }

    pub fn reset(&mut self) {
        self.parser.reset();
        self.tracker.reset();
        self.detector.reset();
    }

    fn handle_event(&mut self, event: RadarEvent) -> RadarOutput {
        match &event {
            RadarEvent::Target(target) => {
                let tracked = self.tracker.update(target);
                let (motion, closing) = self.detector.observe(&tracked);
                RadarOutput {
                    event,
                    motion,
                    closing_speed_m_s: closing,
                }
            }
            RadarEvent::Presence(_) | RadarEvent::Imu(_) | RadarEvent::Unknown { .. } => {
                RadarOutput {
                    event,
                    motion: Motion::Unknown,
                    closing_speed_m_s: None,
                }
            }
        }
    }
}
