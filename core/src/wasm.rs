//! wasm-bindgen surface for the browser lab.

use wasm_bindgen::prelude::*;

use crate::{Motion, RadarEngine, RadarEvent, RadarOutput};

#[wasm_bindgen]
pub struct WasmRadarEngine {
    inner: RadarEngine,
}

#[wasm_bindgen]
impl WasmRadarEngine {
    #[wasm_bindgen(constructor)]
    pub fn new() -> WasmRadarEngine {
        WasmRadarEngine {
            inner: RadarEngine::new(),
        }
    }

    /// Push raw bytes; returns a JS array of output objects.
    #[wasm_bindgen(js_name = pushBytes)]
    pub fn push_bytes(&mut self, data: &[u8]) -> Result<JsValue, JsValue> {
        let outputs = self.inner.push_bytes(data);
        let mapped: Vec<JsOutput> = outputs.into_iter().map(JsOutput::from).collect();
        serde_wasm_bindgen::to_value(&mapped).map_err(|e| JsValue::from_str(&e.to_string()))
    }

    pub fn reset(&mut self) {
        self.inner.reset();
    }
}

impl Default for WasmRadarEngine {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct JsOutput {
    kind: String,
    raw: String,
    motion: String,
    closing_speed_m_s: Option<f32>,
    detected: Option<bool>,
    count: Option<u8>,
    id: Option<u8>,
    distance_m: Option<f32>,
    speed_m_s: Option<f32>,
    energy: Option<u32>,
    accel_m_s2: Option<[f32; 3]>,
    gyro_rad_s: Option<[f32; 3]>,
}

impl From<RadarOutput> for JsOutput {
    fn from(o: RadarOutput) -> Self {
        let motion = motion_str(o.motion).to_string();
        let closing = o.closing_speed_m_s;
        match o.event {
            RadarEvent::Presence(p) => JsOutput {
                kind: "presence".into(),
                raw: p.raw,
                motion,
                closing_speed_m_s: closing,
                detected: Some(p.detected),
                count: None,
                id: None,
                distance_m: None,
                speed_m_s: None,
                energy: None,
                accel_m_s2: None,
                gyro_rad_s: None,
            },
            RadarEvent::Target(t) => JsOutput {
                kind: "target".into(),
                raw: t.raw,
                motion,
                closing_speed_m_s: closing,
                detected: None,
                count: Some(t.count),
                id: t.id,
                distance_m: t.distance_m,
                speed_m_s: t.speed_m_s,
                energy: t.energy,
                accel_m_s2: None,
                gyro_rad_s: None,
            },
            RadarEvent::Imu(i) => JsOutput {
                kind: "imu".into(),
                raw: i.raw,
                motion,
                closing_speed_m_s: closing,
                detected: None,
                count: None,
                id: None,
                distance_m: None,
                speed_m_s: None,
                energy: None,
                accel_m_s2: Some(i.accel_m_s2),
                gyro_rad_s: Some(i.gyro_rad_s),
            },
            RadarEvent::Unknown { raw } => JsOutput {
                kind: "unknown".into(),
                raw,
                motion,
                closing_speed_m_s: closing,
                detected: None,
                count: None,
                id: None,
                distance_m: None,
                speed_m_s: None,
                energy: None,
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
