//! Shared C4001 host preset for rear awareness (lab + phone).

/// Ordered host commands for the Gotcha Six radar setup.
pub const GOTCHA_SIX_PRESET: &[&str] = &[
    "sensorStop",
    "setRunApp 1",
    "setRange 0.6 25",
    "setMicroMotion 0",
    "setThrFactor 5",
    "setUartOutput 2 1 1 1",
    "saveConfig",
    "sensorStart",
];

/// Gap between preset commands, in milliseconds (matches the lab default).
pub const PRESET_GAP_MS: u64 = 150;

/// Host line firmware intercepts to enter System OFF. Not a C4001 command.
pub const POWER_OFF_COMMAND: &str = "$GSOFF";

/// Encode a host command as bytes with a trailing CRLF.
///
/// Strips one existing trailing `\n` or `\r\n` before appending `\r\n`.
pub fn encode_command_line(cmd: &str) -> Vec<u8> {
    let trimmed = cmd
        .strip_suffix("\r\n")
        .or_else(|| cmd.strip_suffix('\n'))
        .unwrap_or(cmd);
    let mut out = Vec::with_capacity(trimmed.len() + 2);
    out.extend_from_slice(trimmed.as_bytes());
    out.extend_from_slice(b"\r\n");
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn includes_speed_mode_and_range_25() {
        assert!(GOTCHA_SIX_PRESET.contains(&"setRunApp 1"));
        assert!(GOTCHA_SIX_PRESET.contains(&"setRange 0.6 25"));
        assert!(GOTCHA_SIX_PRESET.contains(&"setUartOutput 2 1 1 1"));
    }

    #[test]
    fn disables_micro_motion() {
        assert!(GOTCHA_SIX_PRESET.contains(&"setMicroMotion 0"));
        assert!(!GOTCHA_SIX_PRESET.contains(&"setMicroMotion 1"));
    }

    #[test]
    fn encodes_crlf_command_lines() {
        assert_eq!(encode_command_line("sensorStop"), b"sensorStop\r\n");
        assert_eq!(encode_command_line("sensorStop\n"), b"sensorStop\r\n");
        assert_eq!(encode_command_line("sensorStop\r\n"), b"sensorStop\r\n");
    }

    #[test]
    fn preset_gap_is_150_ms() {
        assert_eq!(PRESET_GAP_MS, 150);
    }

    #[test]
    fn power_off_command_is_gsoff() {
        assert_eq!(POWER_OFF_COMMAND, "$GSOFF");
        assert_eq!(encode_command_line(POWER_OFF_COMMAND), b"$GSOFF\r\n");
        assert!(!GOTCHA_SIX_PRESET.contains(&POWER_OFF_COMMAND));
    }
}
