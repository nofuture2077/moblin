import SwiftUI

struct StreamWizardAfreecaTvSettingsView: View {
    @EnvironmentObject private var model: Model

    var body: some View {
        Form {
            Section {
                TextField("MyChannel", text: $model.wizardAfreecaTvChannelName)
                    .disableAutocorrection(true)
            } header: {
                Text("Channel name")
            }
            Section {
                TextField("908123903", text: $model.wizardAfreecsTvCStreamId)
                    .disableAutocorrection(true)
            } header: {
                Text("Video id")
            }
            Section {
                NavigationLink(destination: StreamWizardNetworkSetupSettingsView(platform: "AfreecaTV")) {
                    WizardNextButtonView()
                }
            }
        }
        .onAppear {
            model.wizardPlatform = .afreecaTv
        }
        .navigationTitle("AfreecaTV")
        .toolbar {
            CreateStreamWizardToolbar()
        }
    }
}