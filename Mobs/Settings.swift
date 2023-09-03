import SwiftUI

class SettingsConnection: Codable, Identifiable {
    var name: String
    var id: UUID = UUID()
    var enabled: Bool = false
    var rtmpUrl: String = "rtmp://arn03.contribute.live-video.net/app/your_stream_key"
    var srtUrl: String = "srt://platform.com:5000"
    var srtla: Bool = false
    var twitchChannelName: String = ""
    var twitchChannelId: String = ""

    init(name: String) {
        self.name = name
    }
}

class SettingsSceneWidget: Codable, Identifiable {
    var widgetId: UUID
    var id: UUID = UUID()
    var x: Int = 0
    var y: Int = 0
    var w: Int = 10
    var h: Int = 10
    
    init(widgetId: UUID) {
        self.widgetId = widgetId
    }
}

class SettingsScene: Codable, Identifiable {
    var name: String
    var id: UUID = UUID()
    var enabled: Bool = true
    var widgets: [SettingsSceneWidget] = []

    init(name: String) {
        self.name = name
    }
}

class SettingsWidgetText: Codable {
    var formatString: String = "Sub goal: {subs} / 10"
}

class SettingsWidgetImage: Codable {
    var url: String = "https://"
}

class SettingsWidgetVideo: Codable {
    var url: String = "https://"
}

class SettingsWidgetCamera: Codable {
    var direction: String = "Back"
}

class SettingsWidgetChat: Codable {
}

class SettingsWidgetRecording: Codable {
}

class SettingsWidgetWebview: Codable {
    var url: String = "https://"
}

let widgetTypes = ["Camera", /*"Text", */ "Image"/*, "Video", "Chat", "Recording", "Webview"*/]

class SettingsWidget: Codable, Identifiable, Equatable {
    var name: String
    var id: UUID = UUID()
    var type: String = widgetTypes[0]
    var text: SettingsWidgetText = SettingsWidgetText()
    var image: SettingsWidgetImage = SettingsWidgetImage()
    var video: SettingsWidgetVideo = SettingsWidgetVideo()
    var camera: SettingsWidgetCamera = SettingsWidgetCamera()
    var chat: SettingsWidgetChat = SettingsWidgetChat()
    var recording: SettingsWidgetRecording = SettingsWidgetRecording()
    var webview: SettingsWidgetWebview = SettingsWidgetWebview()

    init(name: String) {
        self.name = name
    }
    
    static func == (lhs: SettingsWidget, rhs: SettingsWidget) -> Bool {
        return lhs.id == rhs.id
    }
}

class SettingsVariableText: Codable {
    var value: String = "15.0"
}

class SettingsVariableHttp: Codable {
    var url: String = "https://"
}

class SettingsVariableTwitchPubSub: Codable {
    var pattern: String = ""
}

class SettingsVariableTextWebsocket: Codable {
    var url: String = "https://"
    var pattern: String = ""
}

let variableTypes = ["Text", "HTTP", "Twitch PubSub", "Websocket"]

class SettingsVariable: Codable, Identifiable {
    var name: String
    var id: UUID = UUID()
    var type: String = "Text"
    var text: SettingsVariableText = SettingsVariableText()
    var http: SettingsVariableHttp = SettingsVariableHttp()
    var twitchPubSub: SettingsVariableTwitchPubSub = SettingsVariableTwitchPubSub()
    var websocket: SettingsVariableTextWebsocket = SettingsVariableTextWebsocket()

    init(name: String) {
        self.name = name
    }
}

class Show: Codable {
    var chat: Bool = true
    var viewers: Bool = true
    var uptime: Bool = true
    var connection: Bool = true
    var speed: Bool = true
    var resolution: Bool = true
    var fps: Bool = true
}

class Database: Codable {
    var connections: [SettingsConnection] = []
    var scenes: [SettingsScene] = []
    var widgets: [SettingsWidget] = []
    var variables: [SettingsVariable] = []
    var show: Show = Show()
}

func addDefaultWidgets(database: Database) {
    var widget = SettingsWidget(name: "Back camera")
    widget.type = "Camera"
    widget.camera.direction = "Back"
    database.widgets.append(widget)
    
    widget = SettingsWidget(name: "Front camera")
    widget.type = "Camera"
    widget.camera.direction = "Front"
    database.widgets.append(widget)
}

func createSceneWidgetBackCamera(database: Database) -> SettingsSceneWidget {
    let widget = SettingsSceneWidget(widgetId: database.widgets[0].id)
    widget.x = 0
    widget.y = 0
    widget.h = 100
    widget.w = 100
    return widget
}

func createSceneWidgetFrontCamera(database: Database) -> SettingsSceneWidget {
    let widget = SettingsSceneWidget(widgetId: database.widgets[1].id)
    widget.x = 80
    widget.y = 0
    widget.h = 20
    widget.w = 20
    return widget
}

func addDefaultScenes(database: Database) {
    var scene = SettingsScene(name: "Back")
    scene.widgets.append(createSceneWidgetBackCamera(database: database))
    database.scenes.append(scene)
    
    scene = SettingsScene(name: "Front")
    scene.widgets.append(createSceneWidgetFrontCamera(database: database))
    database.scenes.append(scene)
    
    scene = SettingsScene(name: "Both")
    scene.widgets.append(createSceneWidgetBackCamera(database: database))
    scene.widgets.append(createSceneWidgetFrontCamera(database: database))
    database.scenes.append(scene)
}

func addDefaultConnections(database: Database) {
    let connection = SettingsConnection(name: "Twitch")
    connection.id = UUID()
    connection.enabled = true
    connection.rtmpUrl = "rtmp://arn03.contribute.live-video.net/app/your_stream_key"
    connection.srtUrl = "srt://192.168.202.169:5000"
    connection.twitchChannelName = "jinnytty"
    connection.twitchChannelId = "159498717"
    database.connections.append(connection)
}

func createDefault() -> Database {
    let database = Database()
    addDefaultWidgets(database: database)
    addDefaultScenes(database: database)
    addDefaultConnections(database: database)
    return database
}

final class Settings {
    var database = Database()
    @AppStorage("settings") var storage = ""

    func load() {
        do {
            database = try JSONDecoder().decode(Database.self, from: storage.data(using: .utf8)!)
        } catch {
            logger.info("settings: Failed to load. Using default.")
            database = createDefault()
        }
    }

    func store() {
        do {
            storage = String(decoding: try JSONEncoder().encode(database), as: UTF8.self)
        } catch {
            logger.error("settings: Failed to store.")
        }
    }
}
