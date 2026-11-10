use gotcha_six_core::{Motion, RadarEngine, RadarEvent};

fn push_fixture(engine: &mut RadarEngine, name: &str) -> Vec<gotcha_six_core::RadarOutput> {
    let path = format!("tests/fixtures/{name}");
    let text = std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {path}: {e}"));
    let mut bytes = text.into_bytes();
    if !bytes.ends_with(b"\n") {
        bytes.push(b'\n');
    }
    // Normalize lone newlines already present; ensure each non-empty line ends with \n.
    engine.push_bytes(&bytes)
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
