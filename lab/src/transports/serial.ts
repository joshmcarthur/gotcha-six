import type { DataHandler, RadarTransport } from "./types";

declare global {
  interface Navigator {
    serial?: {
      requestPort(options?: {
        filters?: Array<{ usbVendorId?: number; usbProductId?: number }>;
      }): Promise<SerialPort>;
    };
  }

  interface SerialPort {
    open(options: { baudRate: number }): Promise<void>;
    close(): Promise<void>;
    readable: ReadableStream<Uint8Array> | null;
    writable: WritableStream<Uint8Array> | null;
  }
}

export class WebSerialTransport implements RadarTransport {
  readonly name = "usb";
  private port: SerialPort | null = null;
  private reader: ReadableStreamDefaultReader<Uint8Array> | null = null;
  private writer: WritableStreamDefaultWriter<Uint8Array> | null = null;
  private handler: DataHandler | null = null;
  private readLoopActive = false;

  onData(callback: DataHandler): void {
    this.handler = callback;
  }

  async connect(): Promise<void> {
    if (!navigator.serial) {
      throw new Error("Web Serial is not available in this browser");
    }
    this.port = await navigator.serial.requestPort();
    await this.port.open({ baudRate: 115200 });
    if (!this.port.readable || !this.port.writable) {
      throw new Error("Serial port missing streams");
    }
    this.reader = this.port.readable.getReader();
    this.writer = this.port.writable.getWriter();
    this.readLoopActive = true;
    void this.readLoop();
  }

  async disconnect(): Promise<void> {
    this.readLoopActive = false;
    try {
      await this.reader?.cancel();
    } catch {
      /* ignore */
    }
    this.reader?.releaseLock();
    this.reader = null;
    try {
      this.writer?.releaseLock();
    } catch {
      /* ignore */
    }
    this.writer = null;
    await this.port?.close();
    this.port = null;
  }

  async write(data: Uint8Array): Promise<void> {
    if (!this.writer) {
      throw new Error("USB not connected");
    }
    await this.writer.write(data);
  }

  private async readLoop(): Promise<void> {
    while (this.readLoopActive && this.reader) {
      try {
        const { value, done } = await this.reader.read();
        if (done) {
          break;
        }
        if (value && this.handler) {
          this.handler(value);
        }
      } catch {
        break;
      }
    }
  }
}
