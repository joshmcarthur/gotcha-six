export class DistanceChart {
  private canvas: HTMLCanvasElement;
  private ctx: CanvasRenderingContext2D;
  private points: { t: number; d: number }[] = [];
  private windowMs = 30_000;

  constructor(canvas: HTMLCanvasElement) {
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      throw new Error("canvas 2d unavailable");
    }
    this.canvas = canvas;
    this.ctx = ctx;
  }

  push(t: number, distance: number): void {
    this.points.push({ t, d: distance });
    const minT = t - this.windowMs;
    while (this.points.length > 0 && this.points[0]!.t < minT) {
      this.points.shift();
    }
    this.draw();
  }

  clear(): void {
    this.points = [];
    this.draw();
  }

  private draw(): void {
    const { width, height } = this.canvas;
    const ctx = this.ctx;
    ctx.clearRect(0, 0, width, height);
    ctx.fillStyle = "#0c1015";
    ctx.fillRect(0, 0, width, height);

    ctx.strokeStyle = "#2a3340";
    ctx.beginPath();
    for (let y = 0; y <= 25; y += 5) {
      const py = height - (y / 25) * (height - 20) - 10;
      ctx.moveTo(0, py);
      ctx.lineTo(width, py);
    }
    ctx.stroke();

    if (this.points.length < 2) {
      return;
    }
    const t1 = this.points[this.points.length - 1]!.t;
    const t0 = t1 - this.windowMs;

    ctx.strokeStyle = "#3d9b6e";
    ctx.lineWidth = 2;
    ctx.beginPath();
    this.points.forEach((p, i) => {
      const x = ((p.t - t0) / this.windowMs) * width;
      const y = height - (Math.min(25, Math.max(0, p.d)) / 25) * (height - 20) - 10;
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    });
    ctx.stroke();
  }
}
