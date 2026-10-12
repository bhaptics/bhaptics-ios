import SwiftUI
import BhapticsPlugin

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = BhapticsViewModel.shared
    @State private var position = BhapticsPosition.Vest
    @State private var intensity = 100.0
    @State private var durationMillis = 300.0
    @State private var selectedEvent = ""
    @State private var eventIntensity = 1.0
    @State private var eventDuration = 1.0
    @State private var eventAngleX = 0.0
    @State private var eventOffsetY = 0.0
    @State private var eventsLoading = true
    @State private var requestID = 0
    @State private var selectedTab = 0
    @State private var gloveShape = 0.0
    @State private var glovePlayTime = 4.0
    @State private var gloveFrequency = 80.0
    @State private var gloveRepeat = 50.0

    private static let glovePlayTimeOptions: [Double] = [0, 1, 2, 4, 6, 8]

    private let deviceColumns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 12)]
    private let motorColumns = Array(repeating: GridItem(.fixed(56), spacing: 12), count: 4)

    var body: some View {
        TabView(selection: $selectedTab) {
            devicesTab
                .tabItem { Label("Devices", systemImage: "antenna.radiowaves.left.and.right") }
                .tag(0)
            motorsTab
                .tabItem { Label("Motors", systemImage: "waveform.path") }
                .tag(1)
            eventsTab
                .tabItem { Label("Events", systemImage: "list.bullet.rectangle") }
                .tag(2)
        }
        .onChange(of: selectedTab) { _ in viewModel.stopAll() }
        .task {
            await viewModel.initialize()
            selectedEvent = defaultEvent
            eventsLoading = false
        }
    }

    private var devicesTab: some View {
        ScrollView {
            VStack(spacing: isCompact ? 16 : 24) {
                sampleHeader
                connectionSection
            }
            .padding(isCompact ? 16 : 24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    private var motorsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompact ? 16 : 24) {
                pageTitle("Motor Test", subtitle: "Play paths or individual motors.")
                directSection
            }
            .padding(isCompact ? 16 : 24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    private var eventsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompact ? 16 : 24) {
                pageTitle("Event Test", subtitle: "Play and control registered haptic events.")
                eventSection
            }
            .padding(isCompact ? 16 : 24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
    }

    private var connectionSection: some View {
        GroupBox("Devices") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
#if os(macOS)
                    Spacer()
                    Button("Refresh") { viewModel.refresh() }
                    Button("Ping All") { viewModel.pingAll() }
                        .disabled(viewModel.deviceList.isEmpty)
#else
                    Label(
                        viewModel.isScanning ? "Scanning" : "Ready to scan",
                        systemImage: viewModel.isScanning ? "dot.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right"
                    )
                    Spacer()
                    Button(viewModel.isScanning ? "Stop" : "Scan") {
                        _ = viewModel.toggleScanning()
                    }
                    .buttonStyle(.borderedProminent)
#endif
                }

                if viewModel.deviceList.isEmpty {
                    Text(emptyDeviceMessage)
                        .foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: deviceColumns, spacing: 12) {
                        ForEach(viewModel.deviceList) { device in
                            deviceCard(device)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var directSection: some View {
        GroupBox("Motor Controls") {
            VStack(alignment: .leading, spacing: 18) {
                if isCompact {
                    HStack {
                        Text("Position")
                        Spacer()
                        Picker("Position", selection: $position) {
                            positionOptions
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                } else {
                    Picker("Position", selection: $position) {
                        positionOptions
                    }
                    .pickerStyle(.segmented)
                }

                valueSlider("Intensity", value: $intensity, range: 0...100, suffix: "%")
                valueSlider("Duration", value: $durationMillis, range: 100...2000, step: 100, suffix: " ms")

                HStack(spacing: 10) {
                    pathCenterButton
                    stopAllButton
                }
                .frame(maxWidth: isCompact ? .infinity : 420, alignment: .leading)

                Text("Tap a motor")
                    .font(.headline)

                LazyVGrid(columns: motorColumns, spacing: 12) {
                    ForEach(0..<motorCount, id: \.self) { index in
                        Button {
                            requestID = viewModel.playDotIndex(position: position, index: index, intensity: Int(intensity), durationMillis: Int(durationMillis))
                        } label: {
                            Text("\(index + 1)")
                                .frame(width: 52, height: 52)
                                .background(Color.accentColor.opacity(0.1), in: Circle())
                                .overlay(Circle().stroke(Color.accentColor.opacity(0.35)))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 56, height: 56)
                    }
                }
                .frame(maxWidth: .infinity)

                if position == .GloveL || position == .GloveR {
                    VStack(alignment: .leading, spacing: 10) {
                        valueSlider("Shape", value: $gloveShape, range: 0...2, suffix: "")
                        HStack {
                            Text("PlayTime")
                            Spacer()
                            Picker("PlayTime", selection: $glovePlayTime) {
                                ForEach(Self.glovePlayTimeOptions, id: \.self) { option in
                                    Text("\(Int(option))").tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 260)
                        }
                        valueSlider("Frequency", value: $gloveFrequency, range: 0...100, step: 5, suffix: " Hz")
                        valueSlider("RepeatCount", value: $gloveRepeat, range: 0...255, suffix: " (\(max(gloveRepeatCount, 1) * 40) ms)")

                        Button("Waveform 0–5") {
                            requestID = viewModel.playGloveAll(position: position, intensity: Int(intensity), shape: Int(gloveShape), playTime: Int(glovePlayTime), frequency: Int(gloveFrequency), repeatCount: gloveRepeatCount)
                        }
                        .buttonStyle(.borderedProminent)

                        HStack(spacing: 10) {
                            Button("DK3 All 8") {
                                requestID = viewModel.playGloveDk3(position: position, intensities: Array(repeating: Int(intensity), count: motorCount), shape: Int(gloveShape), playTime: Int(glovePlayTime), frequency: Int(gloveFrequency), repeatCount: gloveRepeatCount)
                            }
                            Button("DK3 Palm 7·8") {
                                var intensities = Array(repeating: 0, count: motorCount)
                                for index in 6..<motorCount { intensities[index] = Int(intensity) }
                                requestID = viewModel.playGloveDk3(position: position, intensities: intensities, shape: Int(gloveShape), playTime: Int(glovePlayTime), frequency: Int(gloveFrequency), repeatCount: gloveRepeatCount)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var eventSection: some View {
        GroupBox("Event Test") {
            VStack(alignment: .leading, spacing: 18) {
                if isCompact {
                    VStack(alignment: .leading, spacing: 10) {
                        eventPicker
                        HStack {
                            Spacer()
                            eventStatus
                        }
                    }
                } else {
                    HStack {
                        eventPicker
                        Spacer()
                        eventStatus
                    }
                }

                valueSlider("Intensity", value: $eventIntensity, range: 0...2, step: 0.1, suffix: "×")
                valueSlider("Duration", value: $eventDuration, range: 0.1...2, step: 0.1, suffix: "×")
                EventTransformControl(angleX: $eventAngleX, offsetY: $eventOffsetY, isCompact: isCompact)

                if isCompact {
                    VStack(spacing: 10) {
                        LazyVGrid(columns: twoColumns, spacing: 10) {
                            eventPlaybackButtons
                        }
                        stopEventButton
                    }
                } else {
                    HStack {
                        eventPlaybackButtons
                        stopEventButton
                    }
                    .frame(maxWidth: 620, alignment: .leading)
                }
            }
            .padding(.top, 8)
            .task(id: selectedEvent) {
                while !Task.isCancelled {
                    if selectedEvent.isEmpty {
                        viewModel.isPlayingEventIdVal = false
                    } else {
                        viewModel.isPlayingByEventId(eventId: selectedEvent)
                    }
                    try? await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
    }

    @ViewBuilder
    private var sampleHeader: some View {
        if isCompact {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    headerIcon(size: 48, symbolSize: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("bHaptics SDK").font(.title.bold())
                        Text("Interactive Sample").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                connectionStatus
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 16) {
                headerIcon(size: 64, symbolSize: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text("bHaptics SDK").font(.largeTitle.bold())
                    Text("Interactive Sample").foregroundStyle(.secondary)
                }
                Spacer()
                connectionStatus
            }
        }
    }

    private func headerIcon(size: CGFloat, symbolSize: CGFloat) -> some View {
        Image(systemName: "waveform.path")
            .font(.system(size: symbolSize, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: size / 4))
    }

    private func pageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(isCompact ? .title.bold() : .largeTitle.bold())
            Text(subtitle).foregroundStyle(.secondary)
        }
    }

    private var connectionStatus: some View {
        Label(viewModel.status, systemImage: viewModel.isConnected ? "checkmark.circle.fill" : "circle.dashed")
            .font(.subheadline)
            .foregroundStyle(viewModel.isConnected ? .green : .secondary)
    }

    @ViewBuilder
    private var positionOptions: some View {
        ForEach(BhapticsViewModel.PositionOptions, id: \.self) {
            Text($0.name).tag($0)
        }
    }

    private var pathCenterButton: some View {
        Button {
            requestID = viewModel.playPathPoint(position: position, x: 0.5, y: 0.5, intensity: Int(intensity), durationMillis: Int(durationMillis))
        } label: {
            actionLabel("Path Center")
        }
        .buttonStyle(.borderedProminent)
    }

    private var stopAllButton: some View {
        Button { viewModel.stopAll() } label: {
            actionLabel("Stop All")
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }

    @ViewBuilder
    private var eventPicker: some View {
        if eventsLoading {
            HStack {
                ProgressView()
                Text("Loading events…")
            }
        } else if viewModel.eventList.isEmpty {
            Text("No events loaded")
                .foregroundStyle(.secondary)
        } else {
            Picker("Event", selection: Binding(
                get: { selectedEvent },
                set: { newEvent in
                    viewModel.stopEventId(eventId: selectedEvent)
                    viewModel.isPlayingEventIdVal = false
                    selectedEvent = newEvent
                }
            )) {
                ForEach(Array(Set(viewModel.eventList)).sorted(), id: \.self) {
                    Text($0).tag($0)
                }
            }
        }
    }

    private var eventStatus: some View {
        HStack {
            PlaybackStatusBadge(
                isPlaying: viewModel.isPlayingEventIdVal,
                eventName: selectedEvent
            )
            Button("Reload") { Task { await loadEvents() } }
        }
    }

    @ViewBuilder
    private var eventPlaybackButtons: some View {
        Button {
            requestID = viewModel.playParam(eventId: selectedEvent, intensity: Float(eventIntensity), duration: Float(eventDuration), angleX: Float(eventAngleX), offsetY: Float(eventOffsetY))
        } label: {
            actionLabel("Play")
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedEvent.isEmpty)

        Button {
            requestID = viewModel.playLoop(eventId: selectedEvent, intensity: Float(eventIntensity), duration: Float(eventDuration), angleX: Float(eventAngleX), offsetY: Float(eventOffsetY), interval: 1000, maxCount: 10)
        } label: {
            actionLabel("Loop")
        }
        .buttonStyle(.bordered)
        .disabled(selectedEvent.isEmpty)

        Button { viewModel.pause(selectedEvent) } label: {
            actionLabel("Pause")
        }
            .buttonStyle(.bordered)
            .disabled(selectedEvent.isEmpty)
        Button { viewModel.resume(selectedEvent) } label: {
            actionLabel("Resume")
        }
            .buttonStyle(.bordered)
            .disabled(selectedEvent.isEmpty)
    }

    private var stopEventButton: some View {
        Button { viewModel.stopEventId(eventId: selectedEvent) } label: {
            actionLabel("Stop Event")
        }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(selectedEvent.isEmpty)
    }

    private func actionLabel(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, minHeight: 32)
    }

    private func deviceCard(_ device: BhapticsDevice) -> some View {
        VStack(spacing: 10) {
            Image(systemName: device.connected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(device.connected ? .green : .secondary)
            Text(device.deviceType)
                .lineLimit(1)
            Text(device.battery >= 0 ? "\(device.battery)%" : "Battery --")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(deviceActionTitle(device)) {
#if os(macOS)
                viewModel.ping(device)
#else
                device.paired ? viewModel.unpair(device: device) : viewModel.pair(device: device)
#endif
            }
#if os(macOS)
            .buttonStyle(.bordered)
#endif
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func valueSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double = 1, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(title): \(value.wrappedValue, specifier: step < 1 ? "%.1f" : "%.0f")\(suffix)")
            Slider(value: value, in: range, step: step)
        }
    }

    private var motorCount: Int { BhapticsViewModel.motorCount(for: position) }
    private var gloveRepeatCount: Int { Int(gloveRepeat) }
    private var isCompact: Bool { horizontalSizeClass == .compact }
    private var twoColumns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: 2) }
    private var emptyDeviceMessage: String {
#if os(macOS)
        return "No devices found. Connect a device through bHaptics Player."
#else
        return "No devices found. Turn on a bHaptics device and start scanning."
#endif
    }

    private func deviceActionTitle(_ device: BhapticsDevice) -> String {
#if os(macOS)
        return "Ping"
#else
        return device.paired ? "Unpair" : "Pair"
#endif
    }

    @MainActor
    private func loadEvents() async {
        eventsLoading = true
        viewModel.getEvnetList()
        selectedEvent = defaultEvent
        eventsLoading = false
    }

    private var defaultEvent: String {
        viewModel.eventList.sorted().first ?? ""
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}
