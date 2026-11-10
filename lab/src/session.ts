export interface SessionSample {
  t: number;
  raw: string;
  kind: string;
  distance_m?: number | null;
  speed_m_s?: number | null;
  energy?: number | null;
  motion?: string;
}

export class SessionRecorder {
  private active = false;
  private samples: SessionSample[] = [];
  private rawChunks: { t: number; bytes: Uint8Array }[] = [];
  private startedAt = 0;

  get isRecording(): boolean {
    return this.active;
  }

  get hasData(): boolean {
    return this.samples.length > 0 || this.rawChunks.length > 0;
  }

  start(): void {
    this.active = true;
    this.samples = [];
    this.rawChunks = [];
    this.startedAt = performance.now();
  }

  stop(): void {
    this.active = false;
  }

  recordBytes(data: Uint8Array): void {
    if (!this.active) {
      return;
    }
    this.rawChunks.push({ t: performance.now() - this.startedAt, bytes: data.slice() });
  }

  recordSample(sample: Omit<SessionSample, "t">): void {
    if (!this.active) {
      return;
    }
    this.samples.push({ ...sample, t: performance.now() - this.startedAt });
  }

  toText(): string {
    return this.samples.map((s) => `${s.t.toFixed(1)}\t${s.raw}`).join("\n") + "\n";
  }

  toCsv(): string {
    const header = "t_ms,kind,distance_m,speed_m_s,energy,motion,raw\n";
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
    return header + rows.join("\n") + "\n";
  }

  /** Flatten recorded raw chunks for replay through the engine. */
  rawReplayBytes(): Uint8Array {
    const total = this.rawChunks.reduce((n, c) => n + c.bytes.length, 0);
    const out = new Uint8Array(total);
    let off = 0;
    for (const c of this.rawChunks) {
      out.set(c.bytes, off);
      off += c.bytes.length;
    }
    return out;
  }

  clear(): void {
    this.samples = [];
    this.rawChunks = [];
  }
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
