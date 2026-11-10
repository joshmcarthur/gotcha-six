import { describe, expect, it } from "vitest";
import { SessionRecorder, parseRecording } from "./session";

describe("SessionRecorder", () => {
  it("exports csv with raw column", () => {
    const r = new SessionRecorder();
    r.start();
    r.recordSample({
      raw: "$DFDMD,1,1,1.0,0.1,10, , *",
      kind: "target",
      distance_m: 1,
      speed_m_s: 0.1,
      energy: 10,
      motion: "unknown",
    });
    r.stop();
    const csv = r.toCsv();
    expect(csv.startsWith("t_ms,kind")).toBe(true);
    expect(csv).toContain("target");
    expect(csv).toContain("$DFDMD");
    expect(r.timedLines().map((l) => l.line)).toEqual(["$DFDMD,1,1,1.0,0.1,10, , *"]);
  });

  it("imports its own text export", () => {
    const r = new SessionRecorder();
    r.start();
    r.recordSample({ raw: "$DFDMD,1,1,1.0,0.1,10, , *", kind: "target" });
    r.recordSample({ raw: "$GSIMU,0,0,9.8,0,0,0*", kind: "imu" });
    r.stop();
    const lines = parseRecording(r.toText());
    expect(lines.map((l) => l.line)).toEqual(r.timedLines().map((l) => l.line));
    expect(lines.map((l) => l.t.toFixed(1))).toEqual(r.timedLines().map((l) => l.t.toFixed(1)));
  });

  it("imports lines without times at a fixed step", () => {
    const lines = parseRecording("$DFDMD,1,1,20.0,1.0,1000, , *\r\n\n$DFDMD,0, , , , , , *\n");
    expect(lines).toEqual([
      { t: 0, line: "$DFDMD,1,1,20.0,1.0,1000, , *" },
      { t: 100, line: "$DFDMD,0, , , , , , *" },
    ]);
  });
});
