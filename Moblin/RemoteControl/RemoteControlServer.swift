import Foundation

protocol RemoteControlServerDelegate: AnyObject {
    func getStatus(onComplete: @escaping (RemoteControlStatusTopLeft, RemoteControlStatusTopRight) -> Void)
}

private func randomString() -> String {
    return Data.random(length: 64).base64EncodedString()
}

class RemoteControlServer {
    private var clientUrl: URL
    private var password: String
    private weak var delegate: (any RemoteControlServerDelegate)?
    private var webSocket: URLSessionWebSocketTask
    private var task: Task<Void, Error>?
    private var clientIdentified: Bool = false
    private var challenge: String = ""
    private var salt: String = ""

    init(clientUrl: URL, password: String, delegate: RemoteControlServerDelegate) {
        self.clientUrl = clientUrl
        self.password = password
        self.delegate = delegate
        webSocket = URLSession(configuration: .default).webSocketTask(with: clientUrl)
    }

    func start() {
        stop()
        logger.info("remote-control-server: start")
        task = Task.init {
            while true {
                setupConnection()
                do {
                    try await receiveMessages()
                } catch {
                    logger.debug("remote-control-server: error: \(error.localizedDescription)")
                }
                if Task.isCancelled {
                    logger.debug("remote-control-server: Cancelled")
                    break
                }
                logger.debug("remote-control-server: Disconnected")
                try await Task.sleep(nanoseconds: 5_000_000_000)
                logger.debug("remote-control-server: Reconnecting")
            }
        }
    }

    func stop() {
        logger.info("remote-control-server: stop")
        task?.cancel()
        task = nil
    }

    private func setupConnection() {
        webSocket = URLSession.shared.webSocketTask(with: clientUrl)
        webSocket.resume()
        challenge = randomString()
        salt = randomString()
        send(message: .event(data: .hello(
            apiVersion: remoteControlApiVersion,
            authentication: .init(challenge: challenge, salt: salt)
        )))
        clientIdentified = false
    }

    private func send(message: RemoteControlMessageToClient) {
        do {
            try webSocket.send(.string(message.toJson())) { _ in }
        } catch {
            logger.info("remote-control-server: Encode failed")
        }
    }

    private func receiveMessages() async throws {
        while true {
            let message = try await webSocket.receive()
            if Task.isCancelled {
                break
            }
            switch message {
            case let .data(message):
                logger.debug("remote-control-server: Got data \(message)")
            case let .string(message):
                logger.debug("remote-control-server: Got message \(message)")
                do {
                    switch try RemoteControlMessageToServer.fromJson(data: message) {
                    case let .request(id: id, data: data):
                        handleRequest(id: id, data: data)
                    }
                } catch {
                    logger.info("remote-control-server: Decode failed")
                }
            default:
                logger.debug("remote-control-server: ???")
            }
        }
    }

    private func handleRequest(id: Int, data: RemoteControlRequest) {
        guard let delegate else {
            return
        }
        var result: RemoteControlResult?
        if clientIdentified {
            switch data {
            case .getStatus:
                delegate.getStatus { topLeft, topRight in
                    self.send(message: .response(
                        id: id,
                        result: .ok,
                        data: .getStatus(topLeft: topLeft, topRight: topRight)
                    ))
                }
            default:
                break
            }
        } else {
            switch data {
            case let .identify(authentication: authentication):
                if authentication == remoteControlHashPassword(
                    challenge: challenge,
                    salt: salt,
                    password: password
                ) {
                    clientIdentified = true
                    result = .ok
                } else {
                    result = .wrongPassword
                }
            default:
                break
            }
        }
        if let result {
            send(message: .response(id: id, result: result, data: nil))
        }
    }
}