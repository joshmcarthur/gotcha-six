use gotcha_six_core::{Motion, RadarEngine, RadarEvent};

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
