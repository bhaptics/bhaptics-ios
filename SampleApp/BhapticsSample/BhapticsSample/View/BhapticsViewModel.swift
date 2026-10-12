//
// Created by Choi Sangwon on 2022/12/26.
//

import Foundation
import BhapticsPlugin

class BhapticsViewModel: ObservableObject {
    static let shared = BhapticsViewModel()

    static let appId = "YOUR_APP_ID"
    static let apiKey = "YOUR_API_KEY"

    var sdk: BhapticsKit!
    var requestId: Int = 0

    @Published var isScanning = false
    @Published var deviceList: [BhapticsDevice] = []
    @Published var eventList: [String] = []
    @Published var isPlayingVal = false
    @Published var isPlayingRequestIdVal = false
    @Published var isPlayingEventIdVal = false
    @Published var status = "Not initialized"
    @Published var isConnected = false
    @Published var lastAction = ""

    public init() {
        sdk = BhapticsKit(delegate: self)
#if os(macOS)
        sdk.onPlayerConnectionChanged = { [weak self] _ in self?.refresh() }
#endif
        deviceList = sdk.getDevices()
        isScanning = sdk.isScanning()
    }

    @MainActor
    public func initialize() async {
        status = "Connecting…"
        let initialized = await sdk.initialize(appId: Self.appId, apiKey: Self.apiKey, defaultSetting: "")
        refresh()
        status = initialized ? platformReadyStatus : "Initialization failed"
    }

    public func refresh() {
        deviceList = sdk.getDevices()
        eventList = Array(Set(sdk.getEventList())).sorted()
#if os(macOS)
        isConnected = sdk.isPlayerConnected()
        status = isConnected ? platformReadyStatus : "Player disconnected"
#else
        isConnected = deviceList.contains(where: \.connected)
#endif
    }

    private var platformReadyStatus: String {
#if os(macOS)
        return "Connected to bHaptics Player"
#else
        return "SDK initialized"
#endif
    }

    public func ping(_ device: BhapticsDevice) {
        lastAction = sdk.ping(device: device.uuid) ? "Ping sent to \(device.name)" : "Ping failed for \(device.name)"
    }

    public func pingAll() {
        lastAction = sdk.pingAll() ? "Ping sent to all devices" : "Ping all failed"
    }

    public func pair(device: BhapticsDevice) {
        sdk.pair(device: device)
    }

    public func unpair(device: BhapticsDevice) {
        sdk.unpair(device: device)
    }

    public func refreshDevices() {
        deviceList = sdk.getDevices()
    }

    public func toggleScanning() -> Bool {
        isScanning = sdk.toggleScanning()
        return isScanning
    }

    public func play(_ eventId: String) -> Int{
        requestId = sdk.play(eventId: eventId)
        return requestId
    }

    public func pause(_ eventId: String) {
        sdk.pause(eventId)
    }

    public func resume(_ eventId: String) {
        sdk.resume(eventId)
    }

    public func getEvnetList() {
        eventList = Array(Set(sdk.getEventList())).sorted()
        print("getEvnetList eventList: \(eventList)")
    }

    public func stopAll() {
        sdk.stopAll()
    }

    public func stopEventId(eventId: String) {
        sdk.stopByEventId(eventId)
    }

    public func stopRequestId(requestId: String) {
        sdk.stopByRequestId(Int(requestId) ?? 0)
    }

    public func isPlaying() {
        isPlayingVal = sdk.isPlaying()
    }

    public func isPlayingByRequestedId(requestId: Int) {
        isPlayingRequestIdVal = sdk.isPlayingByRequestId(requestId)
    }

    public func isPlayingByEventId(eventId: String) {
        isPlayingEventIdVal = sdk.isPlayingByEventId(eventId)
    }

    public func playParam(eventId: String, intensity: Float, duration: Float, angleX: Float, offsetY: Float) -> Int {
        print("playParam eventId: \(eventId), intensity: \(intensity), duration: \(duration), angleX: \(angleX), offsetY: \(offsetY)")
        return sdk.playParam(eventId: eventId, intensity: intensity, duration: duration, angleX: angleX, offsetY: offsetY)
    }

    public func playLoop(eventId: String, intensity: Float, duration: Float, angleX: Float, offsetY: Float, interval: Int, maxCount: Int) -> Int {
        return sdk.playLoop(eventId: eventId, intensity: intensity, duration: duration, angleX: angleX, offsetY: offsetY, interval: interval, maxCount: maxCount)
    }

    public func playWithStartTime(eventId: String, startMillis: Int, intensity: Float, duration: Float, angleX: Float, offsetY: Float) -> Int {
        return sdk.playWithStartTime(eventId: eventId, startMillis: startMillis, intensity: intensity, duration: duration, angleX: angleX, offsetY: offsetY)
    }

    public func playWithoutResult(eventId: String, intensity: Float, duration: Float, angleX: Float, offsetY: Float) {
        sdk.playWithoutResult(eventId: eventId, intensity: intensity, duration: duration, angleX: angleX, offsetY: offsetY)
    }

    // MARK: - Dot / Path (V2)

    private func motorCount(for position: BhapticsPosition) -> Int {
        Self.motorCount(for: position)
    }

    public func playDotIndex(position: BhapticsPosition, index: Int, intensity: Int, durationMillis: Int) -> Int {
        let count = motorCount(for: position)
        var motors = Array(repeating: 0, count: count)
        if index >= 0 && index < count {
            motors[index] = intensity
        }
        requestId = sdk.playDot(position: position.index, durationMillis: durationMillis, arr: motors)
        print("playDotIndex position: \(position), index: \(index), intensity: \(intensity), duration: \(durationMillis)")
        return requestId
    }

    public func playPathPoint(position: BhapticsPosition, x: Float, y: Float, intensity: Int, durationMillis: Int) -> Int {
        requestId = sdk.playPath(position: position.index, durationMillis: durationMillis, x: [x], y: [y], intensity: [intensity])
        print("playPathPoint position: \(position), x: \(x), y: \(y), intensity: \(intensity), duration: \(durationMillis)")
        return requestId
    }

    // MARK: - Glove (waveform)

    public func playGloveIndex(position: BhapticsPosition, index: Int, intensity: Int, shape: Int, playTime: Int, frequency: Int, repeatCount: Int) -> Int {
        let points = [GlovePoint(index: index, intensity: intensity, shape: shape, playTime: playTime)]
        requestId = sdk.playGlove(position: position.index, points: points, frequency: frequency, repeatCount: repeatCount)
        print("playGloveIndex position: \(position), index: \(index), intensity: \(intensity), shape: \(shape), playTime: \(playTime), frequency: \(frequency), repeatCount: \(repeatCount)")
        return requestId
    }

    public func playGloveAll(position: BhapticsPosition, intensity: Int, shape: Int, playTime: Int, frequency: Int, repeatCount: Int) -> Int {
        let points = (0...5).map { GlovePoint(index: $0, intensity: intensity, shape: shape, playTime: playTime) }
        requestId = sdk.playGlove(position: position.index, points: points, frequency: frequency, repeatCount: repeatCount)
        print("playGloveAll position: \(position), intensity: \(intensity), shape: \(shape), playTime: \(playTime), frequency: \(frequency), repeatCount: \(repeatCount)")
        return requestId
    }

    public func playGloveDk3(position: BhapticsPosition, intensities: [Int], shape: Int, playTime: Int, frequency: Int, repeatCount: Int) -> Int {
        let motorCount = Self.motorCount(for: position)
        let points = (0..<motorCount).map { index in
            GlovePoint(index: index, intensity: index < intensities.count ? intensities[index] : 0, shape: shape, playTime: playTime)
        }
        requestId = sdk.playGlove(position: position.index, points: points, frequency: frequency, repeatCount: repeatCount)
        print("playGloveDk3 position: \(position), intensities: \(points.map(\.intensity)), shape: \(shape), playTime: \(playTime), frequency: \(frequency), repeatCount: \(repeatCount)")
        return requestId
    }

    private func updateDevice(devices: [BhapticsDevice]) {
        deviceList = devices
        isConnected = devices.contains(where: \.connected)
    }
}

extension BhapticsViewModel: BhapticsKitDelegate {
    func bHapticsKit(_ bHapticsSDK: BhapticsKit, bleStateChange state: Bool) {
        if (state) {
            sdk.scan()
            isScanning = sdk.isScanning()
        }
    }

    func bHapticsKit(_ bHapticsSDK: BhapticsKit, deviceStateUpdated devices: [BhapticsDevice]) {
        updateDevice(devices: devices)
    }

    func bHapticsKit(_ bHapticsSDK: BhapticsKit, didConnect device: BhapticsDevice) {
        updateDevice(devices: bHapticsSDK.getDevices())
    }

    func bHapticsKit(_ bHapticsSDK: BhapticsKit, didDisconnect device: BhapticsDevice) {
        updateDevice(devices: bHapticsSDK.getDevices())
    }
}

extension BhapticsViewModel {
    public static let PositionOptions = [BhapticsPosition.Vest, BhapticsPosition.ForearmL, BhapticsPosition.ForearmR, BhapticsPosition.GloveL, BhapticsPosition.GloveR, BhapticsPosition.Head]

    public static func motorCount(for position: BhapticsPosition) -> Int {
        if position == .Vest { return 32 }
        if position == .ForearmL || position == .ForearmR { return 3 }
        if position == .GloveL || position == .GloveR { return 8 }
        if position == .Head { return 4 }
        return 20
    }
}
