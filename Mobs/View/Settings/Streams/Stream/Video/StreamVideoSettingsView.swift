import SwiftUI

struct StreamVideoSettingsView: View {
    @ObservedObject var model: Model
    var stream: SettingsStream
    
    var body: some View {
        Form {
            Section {
                NavigationLink(destination: StreamVideoResolutionSettingsView(model: model, stream: stream)) {
                    TextItemView(name: "Resolution", value: stream.resolution.rawValue)
                }
                NavigationLink(destination: StreamVideoFpsSettingsView(model: model, stream: stream)) {
                    TextItemView(name: "FPS", value: String(stream.fps))
                }
                NavigationLink(destination: StreamVideoCodecSettingsView(model: model, stream: stream)) {
                    TextItemView(name: "Codec", value: stream.codec.rawValue)
                }
            }
        }
        .navigationTitle("Video")
    }
}
