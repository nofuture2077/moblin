import AVFoundation
import Foundation
import SwiftUI

class StreamingHistoryStream: Identifiable, Codable {
    var id = UUID()
    var settings: SettingsStream
    var startTime: Date = .init()
    var stopTime: Date = .init()
    var totalBytes: UInt64 = 0
    var numberOfFffffs: Int? = 0

    init(settings: SettingsStream) {
        self.settings = settings
    }

    func duration() -> Duration {
        return .seconds(stopTime.timeIntervalSince(startTime))
    }

    func isSuccessful() -> Bool {
        return numberOfFffffs! == 0
    }
}

class StreamingHistoryDatabase: Codable {
    var totalTime: Duration? = .seconds(0)
    var totalBytes: UInt64? = 0
    var totalStreams: UInt64? = 0
    var streams: [StreamingHistoryStream]

    init() {
        streams = []
    }

    static func fromString(settings: String) throws -> StreamingHistoryDatabase {
        let database = try JSONDecoder().decode(
            StreamingHistoryDatabase.self,
            from: settings.data(using: .utf8)!
        )
        return database
    }

    func toString() throws -> String {
        return try String(decoding: JSONEncoder().encode(self), as: UTF8.self)
    }
}

final class StreamingHistory {
    private var realDatabase = StreamingHistoryDatabase()
    var database: StreamingHistoryDatabase {
        realDatabase
    }

    @AppStorage("streamingHistory") var storage = ""

    func load() {
        do {
            try tryLoadAndMigrate(settings: storage)
        } catch {
            logger.info("streaming-history: Failed to load with error \(error). Using default.")
            realDatabase = StreamingHistoryDatabase()
        }
    }

    private func tryLoadAndMigrate(settings: String) throws {
        realDatabase = try StreamingHistoryDatabase.fromString(settings: settings)
        migrateFromOlderVersions()
    }

    func store() {
        do {
            storage = try realDatabase.toString()
        } catch {
            logger.error("streaming-history: Failed to store.")
        }
    }

    private func migrateFromOlderVersions() {
        if database.totalTime == nil {
            database.totalTime = database.streams.reduce(.seconds(0)) { total, stream in
                total + stream.duration()
            }
            store()
        }
        if database.totalBytes == nil {
            database.totalBytes = database.streams.reduce(0) { total, stream in
                total + stream.totalBytes
            }
            store()
        }
        if database.totalStreams == nil {
            database.totalStreams = UInt64(database.streams.count)
            store()
        }
        for stream in database.streams where stream.numberOfFffffs == nil {
            stream.numberOfFffffs = 0
            store()
        }
    }

    func append(stream: StreamingHistoryStream) {
        while database.streams.count > 100 {
            database.streams.remove(at: 0)
        }
        database.totalTime! += stream.duration()
        database.totalBytes! += stream.totalBytes
        database.totalStreams! += 1
        database.streams.append(stream)
    }
}