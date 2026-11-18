import Foundation

/// Lab-format session recording: `<t_ms>\t<raw line>` per parsed engine output.
final class SessionLog {
    static let maxBytes = 8 * 1024 * 1024

    private let url: URL
    private var handle: FileHandle?
    private var byteCount = 0
    private(set) var isRecording = false

    var fileURL: URL { url }

    var hasData: Bool {
        let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return (size ?? 0) > 0
    }

    init(directory: URL? = nil) {
        let base = directory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("GotchaSix", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("last-session.txt")
    }

    func start() {
        stop()
        FileManager.default.createFile(atPath: url.path, contents: Data())
        handle = try? FileHandle(forWritingTo: url)
        byteCount = 0
        isRecording = handle != nil
    }

    func stop() {
        try? handle?.close()
        handle = nil
        isRecording = false
    }

    func append(tMs: UInt64, raw: String) {
        guard isRecording, let handle, byteCount < Self.maxBytes, !raw.isEmpty else { return }
        let line = String(format: "%.1f\t%@\n", Double(tMs), raw)
        guard let data = line.data(using: .utf8) else { return }
        guard byteCount + data.count <= Self.maxBytes else { return }
        do {
            try handle.write(contentsOf: data)
            byteCount += data.count
        } catch {
            return
        }
    }
}
