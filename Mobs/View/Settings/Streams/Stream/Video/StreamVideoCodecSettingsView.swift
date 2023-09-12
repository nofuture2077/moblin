import SwiftUI

struct StreamVideoCodecSettingsView: View {
    @ObservedObject var model: Model
    private var stream: SettingsStream
    @State private var selection: String
    
    init(model: Model, stream: SettingsStream) {
        self.model = model
        self.stream = stream
        self.selection = stream.codec.rawValue
    }
    
    var body: some View {
        Form {
            Section {
                Picker("", selection: $selection) {
                    ForEach(codecs, id: \.self) { codec in
                        Text(codec)
                    }
                }
                .onChange(of: selection) { codec in
                    stream.codec = SettingsStreamCodec(rawValue: codec)!
                    model.store()
                    if stream.enabled {
                        model.reloadStream()
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .navigationTitle("Codec")
    }
}
