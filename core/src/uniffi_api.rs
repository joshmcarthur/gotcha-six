//! UniFFI surface for the iOS companion. Thin wrappers only — no engine behaviour change.

use std::sync::Mutex;

use crate::alert_gate::{AlertGate, OutputKind};
use crate::detection::Motion;
use crate::preset::{self, GOTCHA_SIX_PRESET, PRESET_GAP_MS};
use crate::{RadarEngine, RadarEvent, RadarOutput};

/// Flat engine output for Swift (mirrors the lab WASM DTO field set).
#[derive(Debug, Clone, PartialEq, uniffi::Record)]
pub struct EngineOutput {
    pub kind: String,
    pub motion: String,
    pub distance_m: Option<f32>,
    pub closing_speed_m_s: Option<f32>,
    pub speed_m_s: Option<f32>,
    pub energy: Option<u32>,
    pub count: Option<u8>,
    pub id: Option<u8>,
    pub accel_m_s2: Option<Vec<f32>>,
    pub gyro_rad_s: Option<Vec<f32>>,
}

/// UniFFI facade over [`RadarEngine`].
#[derive(uniffi::Object)]
pub struct UniffiRadarEngine {
    inner: Mutex<RadarEngine>,
}

#[uniffi::export]
impl UniffiRadarEngine {
    #[uniffi::constructor]
    pub fn new() -> Self {
        Self {
            inner: Mutex::new(RadarEngine::new()),
        }
    }

    pub fn push_bytes(&self, data: Vec<u8>) -> Vec<EngineOutput> {
        let mut engine = self.inner.lock().unwrap_or_else(|e| e.into_inner());
        engine
            .push_bytes(&data)
            .into_iter()
            .map(EngineOutput::from)
            .collect()
    }

    pub fn reset(&self) {
        let mut engine = self.inner.lock().unwrap_or_else(|e| e.into_inner());
        engine.reset();
    }
}

/// UniFFI facade over [`AlertGate`].
#[derive(uniffi::Object)]
pub struct UniffiAlertGate {
    inner: Mutex<AlertGate>,
}

#[uniffi::export]
impl UniffiAlertGate {
    #[uniffi::constructor]
    pub fn new() -> Self {
        Self {
            inner: Mutex::new(AlertGate::new()),
        }
    }

    pub fn set_session_on(&self, on: bool) {
        let mut gate = self.inner.lock().unwrap_or_else(|e| e.into_inner());
        gate.set_session_on(on);
    }

    pub fn reset(&self) {
        let mut gate = self.inner.lock().unwrap_or_else(|e| e.into_inner());
        gate.reset();
    }

    pub fn observe(
        &self,
        kind: OutputKind,
        motion: Motion,
        distance_m: Option<f32>,
        now_ms: u64,
    ) -> bool {
        let mut gate = self.inner.lock().unwrap_or_else(|e| e.into_inner());
        gate.observe(kind, motion, distance_m, now_ms)
    }
}

#[uniffi::export]
pub fn radar_preset_commands() -> Vec<String> {
    GOTCHA_SIX_PRESET.iter().map(|s| (*s).to_string()).collect()
}

#[uniffi::export]
pub fn preset_gap_ms() -> u64 {
    PRESET_GAP_MS
}

#[uniffi::export]
pub fn encode_command_line(cmd: String) -> Vec<u8> {
    preset::encode_command_line(&cmd)
}

impl From<RadarOutput> for EngineOutput {
    fn from(o: RadarOutput) -> Self {
        let motion = motion_str(o.motion).to_string();
        let closing = o.closing_speed_m_s;
        match o.event {
            RadarEvent::Presence(_) => EngineOutput {
                kind: "presence".into(),
                motion,
                distance_m: None,
                closing_speed_m_s: closing,
                speed_m_s: None,
                energy: None,
                count: None,
                id: None,
                accel_m_s2: None,
                gyro_rad_s: None,
            },
            RadarEvent::Target(t) => EngineOutput {
                kind: "target".into(),
                motion,
                distance_m: t.distance_m,
                closing_speed_m_s: closing,
                speed_m_s: t.speed_m_s,
                energy: t.energy,
                count: Some(t.count),
                id: t.id,
                accel_m_s2: None,
                gyro_rad_s: None,
            },
            RadarEvent::Imu(i) => EngineOutput {
                kind: "imu".into(),
                motion,
                distance_m: None,
                closing_speed_m_s: closing,
                speed_m_s: None,
                energy: None,
                count: None,
                id: None,
                accel_m_s2: Some(i.accel_m_s2.to_vec()),
                gyro_rad_s: Some(i.gyro_rad_s.to_vec()),
            },
            RadarEvent::Unknown { .. } => EngineOutput {
                kind: "unknown".into(),
                motion,
                distance_m: None,
                closing_speed_m_s: closing,
                speed_m_s: None,
                energy: None,
                count: None,
                id: None,
                accel_m_s2: None,
                gyro_rad_s: None,
            },
        }
    }
}

fn motion_str(m: Motion) -> &'static str {
    match m {
        Motion::Approaching => "approaching",
        Motion::Receding => "receding",
        Motion::Stationary => "stationary",
        Motion::Lost => "lost",
        Motion::Unknown => "unknown",
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wrapper_parses_target_line() {
        let engine = UniffiRadarEngine::new();
        let line = b"$DFDMD,1,1,12.0,0.5,100, , *\n";
        let outs = engine.push_bytes(line.to_vec());
        assert_eq!(outs.len(), 1);
        assert_eq!(outs[0].kind, "target");
        assert_eq!(outs[0].distance_m, Some(12.0));
        assert_eq!(outs[0].speed_m_s, Some(0.5));
        assert_eq!(outs[0].energy, Some(100));
        assert_eq!(outs[0].count, Some(1));
        assert_eq!(outs[0].id, Some(1));
    }

    #[test]
    fn preset_helpers_match_core_constants() {
        assert_eq!(radar_preset_commands().len(), GOTCHA_SIX_PRESET.len());
        assert!(radar_preset_commands().iter().any(|c| c == "setRunApp 1"));
        assert_eq!(preset_gap_ms(), 150);
        assert_eq!(encode_command_line("sensorStop".into()), b"sensorStop\r\n");
    }

    #[test]
    fn alert_gate_wrapper_respects_session() {
        let gate = UniffiAlertGate::new();
        assert!(!gate.observe(OutputKind::Target, Motion::Approaching, Some(10.0), 0));
        gate.set_session_on(true);
        assert!(gate.observe(OutputKind::Target, Motion::Approaching, Some(10.0), 1));
    }
}
