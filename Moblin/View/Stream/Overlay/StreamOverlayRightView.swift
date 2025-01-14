import SwiftUI

private let barsPerDb: Float = 0.3
private let clippingThresholdDb: Float = -1.0
private let redThresholdDb: Float = -8.5
private let yellowThresholdDb: Float = -20
private let zeroThresholdDb: Float = -60

// Approx 60 * 0.3 = 20
private let maxBars = "||||||||||||||||||||"

struct AudioLevelView: View {
    var showBar: Bool
    var level: Float
    var channels: Int

    private func bars(count: Float) -> Substring {
        let barCount = Int(count.rounded(.toNearestOrAwayFromZero))
        return maxBars.prefix(barCount)
    }

    private func isClipping() -> Bool {
        return level > clippingThresholdDb
    }

    private func clippingText() -> Substring {
        let db = -zeroThresholdDb
        return bars(count: db * barsPerDb)
    }

    private func redText() -> Substring {
        guard level > redThresholdDb else {
            return ""
        }
        let db = level - redThresholdDb
        return bars(count: db * barsPerDb)
    }

    private func yellowText() -> Substring {
        guard level > yellowThresholdDb else {
            return ""
        }
        let db = min(level - yellowThresholdDb, redThresholdDb - yellowThresholdDb)
        return bars(count: db * barsPerDb)
    }

    private func greenText() -> Substring {
        guard level > zeroThresholdDb else {
            return ""
        }
        let db = min(level - zeroThresholdDb, yellowThresholdDb - zeroThresholdDb)
        return bars(count: db * barsPerDb)
    }

    var body: some View {
        HStack(spacing: 1) {
            HStack(spacing: 1) {
                if level.isNaN {
                    Text("Muted,")
                        .foregroundColor(.white)
                } else if level == .infinity {
                    Text("Unknown,")
                        .foregroundColor(.white)
                } else {
                    if showBar {
                        HStack(spacing: 0) {
                            if isClipping() {
                                Text(clippingText())
                                    .foregroundColor(.red)
                            } else {
                                Text(redText())
                                    .foregroundColor(.red)
                                Text(yellowText())
                                    .foregroundColor(.yellow)
                                Text(greenText())
                                    .foregroundColor(.green)
                            }
                        }
                        .padding([.bottom], 2)
                        .bold()
                    } else {
                        Text(formatAudioLevelDb(level: level))
                            .foregroundColor(.white)
                    }
                }
                Text(formatAudioLevelChannels(channels: channels))
                    .foregroundColor(.white)
            }
            .padding([.leading, .trailing], 2)
            .background(Color(white: 0, opacity: 0.6))
            .cornerRadius(5)
            .font(smallFont)
            Image(systemName: "waveform")
                .frame(width: 17, height: 17)
                .font(smallFont)
                .padding([.leading, .trailing], 2)
                .padding([.bottom], showBar ? 2 : 0)
                .foregroundColor(.white)
                .background(Color(white: 0, opacity: 0.6))
                .cornerRadius(5)
        }
        .padding(0)
    }
}

struct RightOverlayView: View {
    @EnvironmentObject var model: Model

    private var database: Database {
        model.settings.database
    }

    private func netStreamColor() -> Color {
        if model.isStreaming() {
            switch model.streamState {
            case .connecting:
                return .white
            case .connected:
                return .white
            case .disconnected:
                return .red
            }
        } else {
            return .white
        }
    }

    private func remoteControlColor() -> Color {
        if model.isRemoteControlStreamerConfigured() && !model.isRemoteControlStreamerConnected() {
            return .red
        } else if model.isRemoteControlAssistantConfigured() && !model.isRemoteControlAssistantConnected() {
            return .red
        }
        return .white
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            if model.isShowingStatusAudioLevel() {
                AudioLevelView(
                    showBar: database.show.audioBar,
                    level: model.audioLevel,
                    channels: model.numberOfAudioChannels
                )
            }
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusRtmpServer(),
                icon: "server.rack",
                text: model.rtmpSpeedAndTotal,
                textFirst: true,
                color: .white
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusRemoteControl(),
                icon: "appletvremote.gen1",
                text: model.remoteControlStatus,
                textFirst: true,
                color: remoteControlColor()
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusGameController(),
                icon: "gamecontroller",
                text: model.gameControllersTotal,
                textFirst: true,
                color: .white
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusBitrate(),
                icon: "speedometer",
                text: model.speedAndTotal,
                textFirst: true,
                color: netStreamColor()
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusUptime(),
                icon: "deskclock",
                text: model.uptime,
                textFirst: true,
                color: netStreamColor()
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusLocation(),
                icon: "location",
                text: model.location,
                textFirst: true,
                color: .white
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusSrtla(),
                icon: "phone.connection",
                text: model.srtlaConnectionStatistics,
                textFirst: true,
                color: netStreamColor()
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusRecording(),
                icon: "record.circle",
                text: model.recordingLength,
                textFirst: true,
                color: .white
            )
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusBrowserWidgets(),
                icon: "globe",
                text: model.browserWidgetsStatus,
                textFirst: true,
                color: .white
            )
            Spacer()
            if !model.showDrawOnStream {
                if database.show.zoomPresets && model.hasZoom {
                    if model.cameraPosition == .front {
                        Picker("", selection: $model.frontZoomPresetId) {
                            ForEach(database.zoom.front) { preset in
                                Text(preset.name)
                                    .tag(preset.id)
                            }
                        }
                        .onChange(of: model.frontZoomPresetId) { id in
                            model.setCameraZoomPreset(id: id)
                        }
                        .pickerStyle(.segmented)
                        .padding([.bottom], 1)
                        .background(Color(uiColor: .systemBackground).opacity(0.8))
                        .frame(width: CGFloat(50 * database.zoom.front.count))
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(.secondary)
                        )
                        .padding([.bottom], 5)
                    } else {
                        Picker("", selection: $model.backZoomPresetId) {
                            ForEach(model.backZoomPresets()) { preset in
                                Text(preset.name)
                                    .tag(preset.id)
                            }
                        }
                        .onChange(of: model.backZoomPresetId) { id in
                            model.setCameraZoomPreset(id: id)
                        }
                        .pickerStyle(.segmented)
                        .padding([.bottom], 1)
                        .background(Color(uiColor: .systemBackground).opacity(0.8))
                        .frame(width: CGFloat(50 * model.backZoomPresets().count))
                        .cornerRadius(7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(.secondary)
                        )
                        .padding([.bottom], 5)
                    }
                }
                Picker("", selection: $model.sceneIndex) {
                    ForEach(0 ..< model.enabledScenes.count, id: \.self) { id in
                        let scene = model.enabledScenes[id]
                        Text(scene.name)
                            .tag(scene.id)
                    }
                }
                .onChange(of: model.sceneIndex) { tag in
                    model.setSceneId(id: model.enabledScenes[tag].id)
                    model.sceneUpdated(store: false, scrollQuickButtons: true)
                }
                .pickerStyle(.segmented)
                .padding([.bottom], 1)
                .background(Color(uiColor: .systemBackground).opacity(0.8))
                .frame(width: CGFloat(70 * model.enabledScenes.count))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(.secondary)
                )
            }
        }
    }
}
