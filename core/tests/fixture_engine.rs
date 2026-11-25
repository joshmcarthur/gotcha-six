use std::fs;
use std::path::Path;

use gotcha_six_core::{Motion, RadarEngine, RadarEvent};
use serde::Deserialize;

fn push_fixture(engine: &mut RadarEngine, name: &str) -> Vec<gotcha_six_core::RadarOutput> {
    let path = format!("tests/fixtures/{name}");
    let text = std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {path}: {e}"));
    let mut outs = Vec::new();
    for line in text.lines() {
        if line.is_empty() {
            continue;
        }
        let (t_ms, raw) = split_time_prefix(line);
        let mut bytes = raw.as_bytes().to_vec();
        bytes.push(b'\n');
        outs.extend(engine.push_bytes_at(t_ms, &bytes));
    }
    outs
}

/// The lab text export writes `<t_ms>\t<raw line>`. Plain lines use t=0.
fn split_time_prefix(line: &str) -> (u64, &str) {
    match line.split_once('\t') {
        Some((t, rest)) => match t.parse::<f64>() {
            Ok(ms) if ms >= 0.0 => (ms as u64, rest),
            _ => (0, line),
        },
        None => (0, line),
    }
}

#[test]
fn fixture_presence_and_target() {
    let mut engine = RadarEngine::new();
    let outs = push_fixture(&mut engine, "target_example.txt");
    assert_eq!(outs.len(), 1);
    match &outs[0].event {
        RadarEvent::Target(t) => assert_eq!(t.energy, Some(15304)),
        other => panic!("{other:?}"),
    }
}

#[test]
fn fixture_approach_session_detects_approaching_then_lost() {
    let mut engine = RadarEngine::new();
    let outs = push_fixture(&mut engine, "session_approach.txt");
    assert!(outs.iter().any(|o| o.motion == Motion::Approaching));
    assert!(outs.iter().any(|o| matches!(o.event, RadarEvent::Imu(_))));
    assert!(outs.iter().any(|o| o.motion == Motion::Lost));
}

#[test]
fn fixture_wall_pass_detects_approaching_then_lost() {
    let mut engine = RadarEngine::new();
    let outs = push_fixture(&mut engine, "wall_pass.txt");
    assert!(outs.iter().any(|o| o.motion == Motion::Approaching));
    assert!(outs.iter().any(|o| o.motion == Motion::Lost));
}

#[test]
fn fixture_wall_fail_never_approaching() {
    let mut engine = RadarEngine::new();
    let outs = push_fixture(&mut engine, "wall_fail.txt");
    assert!(!outs.is_empty());
    assert!(outs.iter().all(|o| o.motion != Motion::Approaching));
}

#[test]
fn fixture_alert_approach_detects_approaching() {
    let mut engine = RadarEngine::new();
    let outs = push_fixture(&mut engine, "alert_approach.txt");
    assert!(outs.iter().any(|o| o.motion == Motion::Approaching));
}

#[derive(Debug, Deserialize)]
struct Expect {
    #[serde(default)]
    approaching_between_ms: Option<[u64; 2]>,
    #[serde(default)]
    never_approaching_before_ms: Option<u64>,
    #[serde(default)]
    never_approaching: bool,
    #[serde(default)]
    receding_between_ms: Option<[u64; 2]>,
    #[serde(default)]
    lost_between_ms: Option<[u64; 2]>,
}

fn push_timed(path: &Path) -> Vec<(u64, Motion)> {
    let text = fs::read_to_string(path).unwrap_or_else(|e| panic!("read {}: {e}", path.display()));
    let mut engine = RadarEngine::new();
    let mut timed = Vec::new();
    for line in text.lines() {
        if line.is_empty() {
            continue;
        }
        let (t_ms, raw) = split_time_prefix(line);
        let mut bytes = raw.as_bytes().to_vec();
        bytes.push(b'\n');
        for out in engine.push_bytes_at(t_ms, &bytes) {
            timed.push((t_ms, out.motion));
        }
    }
    timed
}

fn first_at(timed: &[(u64, Motion)], want: Motion) -> Option<u64> {
    timed
        .iter()
        .find(|(_, m)| *m == want)
        .map(|(t, _)| *t)
}

fn in_window(t: u64, window: [u64; 2]) -> bool {
    t >= window[0] && t <= window[1]
}

#[test]
fn generated_sessions_match_expected_windows() {
    let dir = Path::new("tests/fixtures/generated");
    let mut cases = 0_u32;
    for entry in fs::read_dir(dir).unwrap_or_else(|e| panic!("read {}: {e}", dir.display())) {
        let path = entry.unwrap().path();
        if path.extension().and_then(|e| e.to_str()) != Some("txt") {
            continue;
        }
        cases += 1;
        let expect_path = path.with_extension("expect.json");
        let raw = fs::read_to_string(&expect_path)
            .unwrap_or_else(|e| panic!("{}: missing expect sidecar: {e}", path.display()));
        let expect: Expect = serde_json::from_str(&raw)
            .unwrap_or_else(|e| panic!("{}: {e}", expect_path.display()));
        let timed = push_timed(&path);
        assert!(
            !timed.is_empty(),
            "{}: session produced no engine output",
            path.display()
        );

        if expect.never_approaching {
            assert!(
                timed.iter().all(|(_, m)| *m != Motion::Approaching),
                "{}: expected no Approaching",
                path.display()
            );
        }

        if let Some(before) = expect.never_approaching_before_ms {
            assert!(
                timed
                    .iter()
                    .filter(|(t, _)| *t < before)
                    .all(|(_, m)| *m != Motion::Approaching),
                "{}: Approaching before {before} ms",
                path.display()
            );
        }

        if let Some(window) = expect.approaching_between_ms {
            let t = first_at(&timed, Motion::Approaching)
                .unwrap_or_else(|| panic!("{}: no Approaching", path.display()));
            assert!(
                in_window(t, window),
                "{}: first Approaching at {t} ms, want {}–{} ms",
                path.display(),
                window[0],
                window[1]
            );
        }

        if let Some(window) = expect.receding_between_ms {
            let t = first_at(&timed, Motion::Receding)
                .unwrap_or_else(|| panic!("{}: no Receding", path.display()));
            assert!(
                in_window(t, window),
                "{}: first Receding at {t} ms, want {}–{} ms",
                path.display(),
                window[0],
                window[1]
            );
        }

        if let Some(window) = expect.lost_between_ms {
            let t = first_at(&timed, Motion::Lost)
                .unwrap_or_else(|| panic!("{}: no Lost", path.display()));
            assert!(
                in_window(t, window),
                "{}: first Lost at {t} ms, want {}–{} ms",
                path.display(),
                window[0],
                window[1]
            );
        }
    }
    assert!(cases > 0, "no generated/*.txt sessions");
}
