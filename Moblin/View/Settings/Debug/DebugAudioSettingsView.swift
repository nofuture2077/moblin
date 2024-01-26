import HaishinKit
import SwiftUI

private let audioGenerators = ["Off", "Square wave"]

struct DebugAudioSettingsView: View {
    @EnvironmentObject var model: Model

    private func submitChannel0(value: String) {
        guard let channel = Int(value) else {
            return
        }
        model.database.debug!.audioOutputToInputChannelsMap!.channel0 = channel
        model.store()
    }

    private func submitChannel1(value: String) {
        guard let channel = Int(value) else {
            return
        }
        model.database.debug!.audioOutputToInputChannelsMap!.channel1 = channel
        model.store()
    }

    var body: some View {
        Form {
            Section {
                TextEditNavigationView(
                    title: "Output channel 0",
                    value: String(model.database.debug!.audioOutputToInputChannelsMap!.channel0),
                    onSubmit: submitChannel0
                )
                TextEditNavigationView(
                    title: "Output channel 1",
                    value: String(model.database.debug!.audioOutputToInputChannelsMap!.channel1),
                    onSubmit: submitChannel0
                )
            } header: {
                Text("Channels mapping")
            }
            Section {
                Picker("", selection: $model.audioGenerator) {
                    ForEach(audioGenerators, id: \.self) { mode in
                        Text(mode)
                    }
                }
                .onChange(of: model.audioGenerator) { _ in
                    model.setAudioGenerator(generator: model.audioGenerator)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Generator")
            } footer: {
                Text("Use generated audio as source instead of mic.")
            }
            Section {
                HStack {
                    Slider(
                        value: $model.squareWaveGeneratorAmplitude,
                        in: 0 ... 10000,
                        step: 10
                    )
                    .onChange(of: model.squareWaveGeneratorAmplitude) { value in
                        squareWaveGeneratorAmplitude = Int16(value)
                    }
                    Text(String(Int16(model.squareWaveGeneratorAmplitude)))
                        .frame(width: 55)
                }
            } header: {
                Text("Amplitude")
            }
            Section {
                HStack {
                    Slider(
                        value: $model.squareWaveGeneratorInterval,
                        in: 5 ... 500,
                        step: 5
                    )
                    .onChange(of: model.squareWaveGeneratorInterval) { value in
                        squareWaveGeneratorInterval = UInt64(value)
                    }
                    Text(String(UInt64(model.squareWaveGeneratorInterval)))
                        .frame(width: 55)
                }
            } header: {
                Text("Interval")
            }
        }
        .navigationTitle("Audio")
        .toolbar {
            SettingsToolbar()
        }
    }
}
