import CoreMedia
import Foundation
import HaishinKit
import Network

let rtmpServerDispatchQueue = DispatchQueue(label: "com.eerimoq.rtmp-server")

class RtmpServer {
    private var listener: NWListener!
    private var clients: [RtmpServerClient]
    private var onListening: (UInt16) -> Void
    private var onPublishStart: () -> Void
    private var onPublishStop: () -> Void
    private var onFrame: (CMSampleBuffer) -> Void

    init(
        onListening: @escaping (UInt16) -> Void,
        onPublishStart: @escaping () -> Void,
        onPublishStop: @escaping () -> Void,
        onFrame: @escaping (CMSampleBuffer) -> Void
    ) {
        self.onListening = onListening
        self.onPublishStart = onPublishStart
        self.onPublishStop = onPublishStop
        self.onFrame = onFrame
        clients = []
    }

    func start(port: UInt16) {
        rtmpServerDispatchQueue.async {
            do {
                let options = NWProtocolTCP.Options()
                let parameters = NWParameters(tls: nil, tcp: options)
                parameters.requiredLocalEndpoint = .hostPort(
                    host: .ipv4(.any),
                    port: NWEndpoint.Port(rawValue: port) ?? 1935
                )
                parameters.allowLocalEndpointReuse = true
                self.listener = try NWListener(using: parameters)
            } catch {
                logger.error("rtmp-server: Failed to create listener with error \(error)")
                return
            }
            self.listener.stateUpdateHandler = self.handleListenerStateChange(to:)
            self.listener.newConnectionHandler = self.handleNewListenerConnection(connection:)
            self.listener.start(queue: rtmpServerDispatchQueue)
        }
    }

    func stop() {
        rtmpServerDispatchQueue.async {
            for client in self.clients {
                client.stop()
            }
            self.clients.removeAll()
            self.listener?.cancel()
            self.listener = nil
        }
    }

    private func handleListenerStateChange(to state: NWListener.State) {
        logger.info("rtmp-server: State change to \(state)")
        switch state {
        case .setup:
            break
        case .ready:
            logger.info("rtmp-server: Listening on port \(listener.port!.rawValue)")
            onListening(listener.port!.rawValue)
        default:
            break
        }
    }

    private func handleClientDisconnected(client: RtmpServerClient) {
        client.stop()
        clients.removeAll { c in
            c === client
        }
        logNumberOfClients()
        onPublishStop()
    }

    private func handleNewListenerConnection(connection: NWConnection) {
        let client = RtmpServerClient(connection: connection)
        client.start(onDisconnected: handleClientDisconnected, onFrame: onFrame)
        clients.append(client)
        logNumberOfClients()
        onPublishStart()
    }

    private func logNumberOfClients() {
        logger.info("rtmp-server: Number of clients: \(clients.count)")
    }
}