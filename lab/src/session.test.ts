import { describe, expect, it } from "vitest";
import { SessionRecorder } from "./session";

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
  });
});
