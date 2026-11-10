export interface SessionSample {
  t: number;
  raw: string;
  kind: string;
  distance_m?: number | null;
  speed_m_s?: number | null;
  energy?: number | null;
  motion?: string;
}

/** One line of a recording, with its time in ms from the start. */
export interface TimedLine {
  t: number;
  line: string;
}

export class SessionRecorder {
  private active = false;
  private samples: SessionSample[] = [];
  private startedAt = 0;

  get isRecording(): boolean {
    return this.active;
  }

  get hasData(): boolean {
    return this.samples.length > 0;
  }

  start(): void {
    this.active = true;
    this.samples = [];
    this.startedAt = performance.now();
  }

  stop(): void {
    this.active = false;
  }

  recordSample(sample: Omit<SessionSample, "t">): void {
    if (!this.active) {
      return;
    }
    this.samples.push({ ...sample, t: performance.now() - this.startedAt });
  }

  toText(): string {
    const body = this.samples.map((s) => `${s.t.toFixed(1)}\t${s.raw}`).join("\n");
    return `${body}\n`;
  }

  toCsv(): string {
    const header = "t_ms,kind,distance_m,speed_m_s,energy,motion,raw";
    const rows = this.samples.map((s) => {
      const raw = JSON.stringify(s.raw);
      return [
        s.t.toFixed(1),
        s.kind,
        s.distance_m ?? "",
        s.speed_m_s ?? "",
        s.energy ?? "",
        s.motion ?? "",
        raw,
      ].join(",");
    });
    return `${[header, ...rows].join("\n")}\n`;
  }

  /** Recorded lines with their times, for replay through the engine. */
  timedLines(): TimedLine[] {
    return this.samples.map((s) => ({ t: s.t, line: s.raw }));
  }

  clear(): void {
    this.samples = [];
  }
}

/**
 * Parse a text recording. Each line is `<t_ms>\t<raw line>`, as `toText()`
 * writes it. A line with no time prefix gets a time `stepMs` after the line
 * before it, so plain protocol dumps and core fixtures also load.
 */
export function parseRecording(text: string, stepMs = 100): TimedLine[] {
  const lines: TimedLine[] = [];
  let nextT = 0;
  for (const row of text.split(/\r?\n/)) {
    if (row.trim() === "") {
      continue;
    }
    const timed = /^(\d+(?:\.\d+)?)\t(.*)$/.exec(row);
    const t = timed ? Number(timed[1]) : nextT;
    lines.push({ t, line: timed ? (timed[2] ?? "") : row });
    nextT = t + stepMs;
  }
  return lines;
}

export function downloadBlob(filename: string, content: string, type: string): void {
  const blob = new Blob([content], { type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
