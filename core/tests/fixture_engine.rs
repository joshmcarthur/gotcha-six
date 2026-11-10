use gotcha_six_core::{Motion, RadarEngine, RadarEvent};

fn push_fixture(engine: &mut RadarEngine, name: &str) -> Vec<gotcha_six_core::RadarOutput> {
    let path = format!("tests/fixtures/{name}");
    let text = std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {path}: {e}"));
    let mut bytes = Vec::with_capacity(text.len());
    for line in text.lines() {
        bytes.extend_from_slice(strip_time_prefix(line).as_bytes());
        bytes.push(b'\n');
    }
    engine.push_bytes(&bytes)
}

/// The lab text export writes `<t_ms>\t<raw line>`. Remove the time so an
/// export works as a fixture with no edits. Plain lines pass through.
fn strip_time_prefix(line: &str) -> &str {
    match line.split_once('\t') {
        Some((t, rest)) if t.parse::<f64>().is_ok() => rest,
        _ => line,
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
