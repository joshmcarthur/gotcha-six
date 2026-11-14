import CoreBluetooth
import Foundation

/// One link from phone to a Gotcha Six unit: scan, NUS I/O, UniFFI engine, preset.
@MainActor
final class RadarLink: NSObject, ObservableObject {
    enum Phase: Equatable {
        case unknown
        case poweredOff
        case unauthorized
        case idle
        case scanning
        case connecting
        case connected
        case failed(String)
    }

    struct DiscoveredDevice: Identifiable, Equatable {
        let id: UUID
        let name: String
        let rssi: Int
    }

    private static let peripheralKey = "gotchaSix.peripheralId"
    private static let restoreId = "nz.mcarthur.GotchaSix.central"
    private static let deviceName = "Gotcha Six"
    private static let writeChunk = 20
    private static let presetInitialWaitNs: UInt64 = 1_000_000_000
    private static let noTargetRepresetSeconds: TimeInterval = 4

    static let nusService = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let nusRX = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let nusTX = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")

    @Published private(set) var phase: Phase = .unknown
    @Published private(set) var discovered: [DiscoveredDevice] = []
    @Published private(set) var storedPeripheralId: UUID?
    @Published private(set) var lastMotion = "none"
    @Published private(set) var lastDistanceM: Double?
    @Published private(set) var lastKind = ""
    @Published private(set) var hasTarget = false
    @Published private(set) var isSendingPreset = false
    @Published private(set) var lastError: String?
    /// Bumps when AlertGate says fire while a session is armed.
    @Published private(set) var alertSequence: UInt64 = 0
    @Published private(set) var lastAlertDistanceM: Double?

    private let engine = UniffiRadarEngine()
    private let alertGate = UniffiAlertGate()
    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var rxCharacteristic: CBCharacteristic?
    private var peripheralsById: [UUID: CBPeripheral] = [:]
    private var sawTargetSinceConnect = false
    private var sessionArmed = false
    private var sessionStartedAt = Date()
    private var reconnectWatch: Task<Void, Never>?
    private var presetTask: Task<Void, Never>?

    override init() {
        if let raw = UserDefaults.standard.string(forKey: Self.peripheralKey) {
            storedPeripheralId = UUID(uuidString: raw)
        }
        super.init()
        central = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Self.restoreId]
        )
    }

    var isConnected: Bool {
        if case .connected = phase { return true }
        return false
    }

    func startScan() {
        lastError = nil
        discovered = []
        peripheralsById = [:]
        guard central.state == .poweredOn else {
            updatePhaseForCentralState()
            return
        }
        phase = .scanning
        central.scanForPeripherals(
            withServices: [Self.nusService],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    func stopScan() {
        central.stopScan()
        if case .scanning = phase {
            phase = .idle
        }
    }

    func connect(to id: UUID) {
        lastError = nil
        stopScan()
        guard let peripheral = peripheralsById[id] ?? central.retrievePeripherals(withIdentifiers: [id]).first else {
            phase = .failed("Device not found. Scan again.")
            lastError = "Device not found. Scan again."
            return
        }
        connect(peripheral: peripheral)
    }

    func reconnectStored() {
        guard let id = storedPeripheralId else {
            phase = .failed("No saved device.")
            lastError = "No saved device."
            return
        }
        lastError = nil
        stopScan()
        let known = central.retrievePeripherals(withIdentifiers: [id])
        if let peripheral = known.first {
            peripheralsById[id] = peripheral
            connect(peripheral: peripheral)
            return
        }
        // Not cached — scan until we see the stored id.
        startScan()
    }

    func disconnect() {
        reconnectWatch?.cancel()
        presetTask?.cancel()
        if let peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        clearLinkState(keepStoredId: true)
        phase = .idle
    }

    func forgetDevice() {
        disconnect()
        storedPeripheralId = nil
        UserDefaults.standard.removeObject(forKey: Self.peripheralKey)
    }

    /// Send the core radar preset (1 s wait, then commands with UniFFI gap).
    func sendPreset() {
        presetTask?.cancel()
        presetTask = Task { [weak self] in
            await self?.runPreset(isRepreset: false)
        }
    }

    /// Reset parser + gate and arm AlertGate for a ride session.
    func beginSessionParsing() {
        resetEngines()
        sessionArmed = true
        sessionStartedAt = Date()
        alertGate.setSessionOn(on: true)
    }

    /// Disarm alerts; leave BLE and NUS as they are.
    func endSessionParsing() {
        sessionArmed = false
        alertGate.setSessionOn(on: false)
    }

    /// After reconnect during an active session, re-arm the gate (reset cleared it).
    func rearmSessionParsing() {
        guard sessionArmed else { return }
        alertGate.setSessionOn(on: true)
    }

    var isSessionArmed: Bool { sessionArmed }

    private func connect(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        phase = .connecting
        let keepSession = sessionArmed
        resetEngines()
        sessionArmed = keepSession
        sawTargetSinceConnect = false
        central.connect(peripheral, options: nil)
    }

    private func clearLinkState(keepStoredId: Bool) {
        rxCharacteristic = nil
        peripheral = nil
        lastMotion = "none"
        lastDistanceM = nil
        lastKind = ""
        hasTarget = false
        isSendingPreset = false
        if !keepStoredId {
            storedPeripheralId = nil
        }
    }

    private func resetEngines() {
        engine.reset()
        alertGate.reset()
        lastMotion = "none"
        lastDistanceM = nil
        lastKind = ""
        hasTarget = false
        lastAlertDistanceM = nil
    }

    private func persistPeripheralId(_ id: UUID) {
        storedPeripheralId = id
        UserDefaults.standard.set(id.uuidString, forKey: Self.peripheralKey)
    }

    private func updatePhaseForCentralState() {
        switch central.state {
        case .poweredOn:
            if !isConnected, phase != .scanning, phase != .connecting {
                phase = .idle
            }
        case .poweredOff:
            phase = .poweredOff
        case .unauthorized:
            phase = .unauthorized
        case .unsupported:
            phase = .failed("Bluetooth is not supported on this device.")
            lastError = "Bluetooth is not supported on this device."
        case .resetting, .unknown:
            phase = .unknown
        @unknown default:
            phase = .unknown
        }
    }

    private func runPreset(isRepreset: Bool) async {
        guard rxCharacteristic != nil, let peripheral, peripheral.state == .connected else {
            lastError = "Not connected."
            return
        }
        isSendingPreset = true
        lastError = nil
        defer { isSendingPreset = false }

        if !isRepreset {
            try? await Task.sleep(nanoseconds: Self.presetInitialWaitNs)
        }
        guard !Task.isCancelled else { return }

        let commands = radarPresetCommands()
        let gapMs = presetGapMs()
        for cmd in commands {
            guard !Task.isCancelled else { return }
            let line = encodeCommandLine(cmd: cmd)
            do {
                try writeChunks(line)
            } catch {
                lastError = error.localizedDescription
                return
            }
            if gapMs > 0 {
                try? await Task.sleep(nanoseconds: gapMs * 1_000_000)
            }
        }
    }

    private func writeChunks(_ data: Data) throws {
        guard let peripheral, let rxCharacteristic else {
            throw RadarLinkError.notConnected
        }
        var offset = 0
        while offset < data.count {
            let end = min(offset + Self.writeChunk, data.count)
            let chunk = data.subdata(in: offset..<end)
            peripheral.writeValue(chunk, for: rxCharacteristic, type: .withoutResponse)
            offset = end
        }
    }

    private func ingest(_ data: Data) {
        let outputs = engine.pushBytes(data: data)
        let nowMs = UInt64(max(0, Date().timeIntervalSince(sessionStartedAt) * 1000))
        for out in outputs {
            lastKind = out.kind
            if !out.motion.isEmpty {
                lastMotion = out.motion
            }
            if out.kind == "target" {
                hasTarget = true
                if let d = out.distanceM {
                    lastDistanceM = Double(d)
                }
                sawTargetSinceConnect = true
            } else if out.kind == "presence" {
                hasTarget = false
                lastDistanceM = out.distanceM.map(Double.init)
                sawTargetSinceConnect = true
            }

            if sessionArmed, shouldObserve(out),
               alertGate.observe(
                   kind: outputKind(out.kind),
                   motion: motionValue(out.motion),
                   distanceM: out.distanceM,
                   nowMs: nowMs
               )
            {
                alertSequence += 1
                lastAlertDistanceM = out.distanceM.map(Double.init)
            }
        }
    }

    private func shouldObserve(_ out: EngineOutput) -> Bool {
        out.kind == "target" || out.kind == "presence" || out.kind == "unknown"
    }

    private func outputKind(_ raw: String) -> OutputKind {
        switch raw {
        case "presence": return .presence
        case "target": return .target
        case "imu": return .imu
        default: return .unknown
        }
    }

    private func motionValue(_ raw: String) -> Motion {
        switch raw {
        case "approaching": return .approaching
        case "receding": return .receding
        case "stationary": return .stationary
        case "lost": return .lost
        default: return .unknown
        }
    }

    private func startNoTargetWatch() {
        reconnectWatch?.cancel()
        reconnectWatch = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.noTargetRepresetSeconds * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            if !self.sawTargetSinceConnect, self.isConnected {
                await self.runPreset(isRepreset: true)
            }
        }
    }

    private func nameMatches(_ peripheral: CBPeripheral, advertisementName: String?) -> Bool {
        let names = [peripheral.name, advertisementName].compactMap { $0 }
        return names.contains { $0 == Self.deviceName || $0.hasPrefix(Self.deviceName) }
    }
}

enum RadarLinkError: LocalizedError {
    case notConnected

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected."
        }
    }
}

extension RadarLink: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.updatePhaseForCentralState()
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        willRestoreState dict: [String: Any]
    ) {
        Task { @MainActor in
            if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
                for peripheral in peripherals {
                    self.peripheralsById[peripheral.identifier] = peripheral
                    if peripheral.state == .connected {
                        self.peripheral = peripheral
                        peripheral.delegate = self
                        self.phase = .connecting
                        peripheral.discoverServices([Self.nusService])
                    }
                }
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            guard self.nameMatches(peripheral, advertisementName: advName) else { return }

            self.peripheralsById[peripheral.identifier] = peripheral
            let name = peripheral.name ?? advName ?? Self.deviceName
            let device = DiscoveredDevice(
                id: peripheral.identifier,
                name: name,
                rssi: RSSI.intValue
            )
            if let idx = self.discovered.firstIndex(where: { $0.id == device.id }) {
                self.discovered[idx] = device
            } else {
                self.discovered.append(device)
            }

            if let stored = self.storedPeripheralId,
               peripheral.identifier == stored,
               self.phase == .scanning
            {
                self.connect(peripheral: peripheral)
            }
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.persistPeripheralId(peripheral.identifier)
            peripheral.discoverServices([Self.nusService])
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            let message = error?.localizedDescription ?? "Connection failed."
            self.phase = .failed(message)
            self.lastError = message
            self.clearLinkState(keepStoredId: true)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            self.reconnectWatch?.cancel()
            self.presetTask?.cancel()
            self.resetEngines()
            self.clearLinkState(keepStoredId: true)
            if let error {
                self.phase = .failed(error.localizedDescription)
                self.lastError = error.localizedDescription
            } else {
                self.phase = .idle
            }
        }
    }
}

extension RadarLink: CBPeripheralDelegate {
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            if let error {
                self.phase = .failed(error.localizedDescription)
                self.lastError = error.localizedDescription
                return
            }
            guard let service = peripheral.services?.first(where: { $0.uuid == Self.nusService }) else {
                self.phase = .failed("NUS service missing.")
                self.lastError = "NUS service missing."
                return
            }
            peripheral.discoverCharacteristics([Self.nusRX, Self.nusTX], for: service)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.phase = .failed(error.localizedDescription)
                self.lastError = error.localizedDescription
                return
            }
            guard let characteristics = service.characteristics else {
                self.phase = .failed("NUS characteristics missing.")
                self.lastError = "NUS characteristics missing."
                return
            }
            self.rxCharacteristic = characteristics.first(where: { $0.uuid == Self.nusRX })
            guard let tx = characteristics.first(where: { $0.uuid == Self.nusTX }) else {
                self.phase = .failed("NUS TX characteristic missing.")
                self.lastError = "NUS TX characteristic missing."
                return
            }
            guard self.rxCharacteristic != nil else {
                self.phase = .failed("NUS RX characteristic missing.")
                self.lastError = "NUS RX characteristic missing."
                return
            }
            peripheral.setNotifyValue(true, for: tx)
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.phase = .failed(error.localizedDescription)
                self.lastError = error.localizedDescription
                return
            }
            guard characteristic.uuid == Self.nusTX, characteristic.isNotifying else { return }
            self.phase = .connected
            self.sawTargetSinceConnect = false
            self.startNoTargetWatch()
            self.sendPreset()
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.lastError = error.localizedDescription
                return
            }
            guard characteristic.uuid == Self.nusTX, let data = characteristic.value, !data.isEmpty else {
                return
            }
            self.ingest(data)
        }
    }
}
