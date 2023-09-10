import SwiftUI

struct WidgetsSettingsView: View {
    @ObservedObject var model: Model

    var database: Database {
        get {
            model.database
        }
    }

    func isWidgetUsed(widget: SettingsWidget) -> Bool {
        for scene in database.scenes {
            for sceneWidget in scene.widgets {
                if sceneWidget.widgetId == widget.id {
                    return true
                }
            }
        }
        for button in database.buttons {
            if button.type == "Widget" {
                if button.widget.widgetId == widget.id {
                    return true
                }
            }
        }
        return false
    }

    var body: some View {
        Form {
            Section {
                ForEach(database.widgets) { widget in
                    NavigationLink(destination: WidgetSettingsView(widget: widget, model: model)) {
                        HStack {
                            Image(systemName: widgetImage(widget: widget))
                            Text(widget.name)
                        }
                    }
                    .deleteDisabled(isWidgetUsed(widget: widget))
                }
                .onDelete(perform: { offsets in
                    database.widgets.remove(atOffsets: offsets)
                    model.store()
                    model.objectWillChange.send()
                })
                CreateButtonView(action: {
                    database.widgets.append(SettingsWidget(name: "My widget"))
                    model.store()
                    model.objectWillChange.send()
                })
            } footer: {
                Text("Only unused widgets can be deleted.")
            }
        }
        .navigationTitle("Widgets")
    }
}
