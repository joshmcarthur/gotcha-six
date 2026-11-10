//! Incremental ASCII line parser for C4001 and `$GSIMU` streams.

use crate::protocol::{ImuSample, Presence, RadarEvent, Target};

/// Accumulates bytes and emits complete lines as [`RadarEvent`]s.
#[derive(Debug, Default)]
pub struct RadarParser {
    buf: Vec<u8>,
}

impl RadarParser {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn reset(&mut self) {
        self.buf.clear();
    }

    pub fn push_bytes(&mut self, data: &[u8]) -> Vec<RadarEvent> {
        let mut events = Vec::new();
        for &b in data {
            if b == b'\n' {
                let mut line = std::mem::take(&mut self.buf);
                while line.last() == Some(&b'\r') {
                    line.pop();
                }
                if !line.is_empty() {
                    events.push(parse_line(&line));
                }
            } else if self.buf.len() < 512 {
                self.buf.push(b);
            } else {
                // Pathological line: reset and emit unknown of truncated content.
                let mut line = std::mem::take(&mut self.buf);
                while line.last() == Some(&b'\r') {
                    line.pop();
                }
                if !line.is_empty() {
                    events.push(RadarEvent::Unknown {
                        raw: String::from_utf8_lossy(&line).into_owned(),
                    });
                }
                if b != b'\r' {
                    self.buf.push(b);
                }
            }
        }
        events
    }
}

fn parse_line(line: &[u8]) -> RadarEvent {
    let raw = String::from_utf8_lossy(line).into_owned();
    let trimmed = raw.trim();

    if let Some(rest) = trimmed.strip_prefix("$DFHPD,") {
        return parse_dfhpd(rest, trimmed.to_string());
    }
    if let Some(rest) = trimmed.strip_prefix("$DFDMD,") {
        return parse_dfdmd(rest, trimmed.to_string());
    }
    if let Some(rest) = trimmed.strip_prefix("$GSIMU,") {
        return parse_gsimu(rest, trimmed.to_string());
    }

    RadarEvent::Unknown {
        raw: trimmed.to_string(),
    }
}

fn strip_star_suffix(s: &str) -> &str {
    s.strip_suffix('*').unwrap_or(s).trim_end()
}

fn split_csv(s: &str) -> Vec<&str> {
    strip_star_suffix(s)
        .split(',')
        .map(|p| p.trim())
        .collect()
}

fn parse_optional_u8(s: &str) -> Option<u8> {
    if s.is_empty() {
        return None;
    }
    s.parse().ok()
}

fn parse_optional_f32(s: &str) -> Option<f32> {
    if s.is_empty() {
        return None;
    }
    s.parse().ok()
}

fn parse_optional_u32(s: &str) -> Option<u32> {
    if s.is_empty() {
        return None;
    }
    // Energy may arrive as float in some firmware dumps; accept both.
    if let Ok(v) = s.parse::<u32>() {
        return Some(v);
    }
    s.parse::<f32>().ok().map(|v| v as u32)
}

fn parse_dfhpd(rest: &str, raw: String) -> RadarEvent {
    let fields = split_csv(rest);
    let detected = match fields.first().copied() {
        Some("0") => false,
        Some("1") => true,
        _ => {
            return RadarEvent::Unknown { raw };
        }
    };
    RadarEvent::Presence(Presence { detected, raw })
}

fn parse_dfdmd(rest: &str, raw: String) -> RadarEvent {
    let fields = split_csv(rest);
    // Expected: count, id, distance, speed, energy, placeholder, placeholder
    if fields.len() < 5 {
        return RadarEvent::Unknown { raw };
    }

    let Some(count) = parse_optional_u8(fields[0]) else {
        return RadarEvent::Unknown { raw };
    };

    if count == 0 {
        return RadarEvent::Target(Target {
            count: 0,
            id: None,
            distance_m: None,
            speed_m_s: None,
            energy: None,
            raw,
        });
    }

    let id = parse_optional_u8(fields[1]);
    let distance_m = parse_optional_f32(fields[2]);
    let speed_m_s = parse_optional_f32(fields[3]);
    let energy = parse_optional_u32(fields[4]);

    if distance_m.is_none() || speed_m_s.is_none() || energy.is_none() {
        return RadarEvent::Unknown { raw };
    }

    RadarEvent::Target(Target {
        count,
        id,
        distance_m,
        speed_m_s,
        energy,
        raw,
    })
}

fn parse_gsimu(rest: &str, raw: String) -> RadarEvent {
    let fields = split_csv(rest);
    if fields.len() < 6 {
        return RadarEvent::Unknown { raw };
    }
    let mut vals = [0.0_f32; 6];
    for (i, f) in fields.iter().take(6).enumerate() {
        match f.parse::<f32>() {
            Ok(v) => vals[i] = v,
            Err(_) => return RadarEvent::Unknown { raw },
        }
    }
    RadarEvent::Imu(ImuSample {
        accel_m_s2: [vals[0], vals[1], vals[2]],
        gyro_rad_s: [vals[3], vals[4], vals[5]],
        raw,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_presence_present() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"$DFHPD,1, , , *\r\n");
        assert_eq!(ev.len(), 1);
        match &ev[0] {
            RadarEvent::Presence(pr) => assert!(pr.detected),
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn parses_presence_absent() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"$DFHPD,0, , , *\n");
        match &ev[0] {
            RadarEvent::Presence(pr) => assert!(!pr.detected),
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn parses_target_datasheet_example() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"$DFDMD,1,1,1.817,0.129,15304, , *\r\n");
        match &ev[0] {
            RadarEvent::Target(t) => {
                assert_eq!(t.count, 1);
                assert_eq!(t.id, Some(1));
                assert!((t.distance_m.unwrap() - 1.817).abs() < 0.001);
                assert!((t.speed_m_s.unwrap() - 0.129).abs() < 0.001);
                assert_eq!(t.energy, Some(15304));
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn parses_no_target() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"$DFDMD,0, , , , , , *\n");
        match &ev[0] {
            RadarEvent::Target(t) => {
                assert_eq!(t.count, 0);
                assert!(t.distance_m.is_none());
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn parses_negative_speed_if_present() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"$DFDMD,1,1,5.0,-0.5,100, , *\n");
        match &ev[0] {
            RadarEvent::Target(t) => assert!((t.speed_m_s.unwrap() + 0.5).abs() < 0.001),
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn parses_gsimu() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"$GSIMU,0.1,-0.2,9.8,0.01,0.02,-0.03*\r\n");
        match &ev[0] {
            RadarEvent::Imu(i) => {
                assert!((i.accel_m_s2[2] - 9.8).abs() < 0.001);
                assert!((i.gyro_rad_s[2] + 0.03).abs() < 0.001);
            }
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn unknown_done_and_response() {
        let mut p = RadarParser::new();
        let ev = p.push_bytes(b"Done\r\nResponse 1 2\nDFRobot:/>\n");
        assert_eq!(ev.len(), 3);
        for e in ev {
            assert!(matches!(e, RadarEvent::Unknown { .. }));
        }
    }

    #[test]
    fn split_writes_across_chunks() {
        let mut p = RadarParser::new();
        assert!(p.push_bytes(b"$DFDMD,1,1,2.").is_empty());
        assert!(p.push_bytes(b"5,0.1,10, , *").is_empty());
        let ev = p.push_bytes(b"\n");
        match &ev[0] {
            RadarEvent::Target(t) => assert!((t.distance_m.unwrap() - 2.5).abs() < 0.001),
            other => panic!("unexpected {other:?}"),
        }
    }

    #[test]
    fn cr_only_does_not_emit_until_lf() {
        let mut p = RadarParser::new();
        assert!(p.push_bytes(b"$DFHPD,1, , , *\r").is_empty());
        let ev = p.push_bytes(b"\n");
        assert_eq!(ev.len(), 1);
    }
}
