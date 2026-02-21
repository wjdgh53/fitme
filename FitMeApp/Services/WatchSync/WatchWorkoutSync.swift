import Foundation

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
final class WatchWorkoutSync: NSObject, ObservableObject {
    private static let persistedIncomingEventsKey = "fitme.watch.incomingEvents"
    private static let maxPersistedIncomingEvents = 2000

    @Published private(set) var isActivated: Bool = false
    @Published private(set) var isPaired: Bool = false
    @Published private(set) var isWatchAppInstalled: Bool = false
    @Published private(set) var lastReceivedState: FitMeWorkoutStateSnapshot?
    @Published private(set) var lastReceivedEvents: [FitMeWatchEvent] = []

    private let processedKeyStore = ProcessedDedupeKeyStore()
    private var lastImmediateSentSessionId: String?
    private var lastSentStatus: FitMeWatchWorkoutStatus?
    private var lastOutgoingState: FitMeWorkoutStateSnapshot?
    private var lastQueuedUserInfoState: FitMeWorkoutStateSnapshot?
    private var lastQueuedUserInfoAck: FitMeWatchAck?
    private var lastQueuedUserInfoSummary: FitMeWatchWorkoutSummary?
    private let defaults = UserDefaults.standard

    #if canImport(WatchConnectivity)
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    #else
    private let session: Any? = nil
    #endif

    override init() {
        super.init()

        #if canImport(WatchConnectivity)
        session?.delegate = self
        session?.activate()
        refreshConnectionStatus()
        #endif
    }

    func drainPersistedIncomingEvents() -> [FitMeWatchEvent] {
        guard let data = defaults.data(forKey: Self.persistedIncomingEventsKey) else { return [] }
        defaults.removeObject(forKey: Self.persistedIncomingEventsKey)
        return (try? FitMeWatchCodec.decoder().decode([FitMeWatchEvent].self, from: data)) ?? []
    }

    func refreshConnectionStatus() {
        #if canImport(WatchConnectivity)
        guard let session else {
            isActivated = false
            isPaired = false
            isWatchAppInstalled = false
            return
        }
        isActivated = session.activationState == .activated
        isPaired = session.isPaired
        isWatchAppInstalled = session.isWatchAppInstalled
        #endif
    }

    func flushLatestState() {
        #if canImport(WatchConnectivity)
        guard let state = lastOutgoingState else { return }
        sendWorkoutState(state, force: true)
        #endif
    }

    func sendWorkoutState(_ state: FitMeWorkoutStateSnapshot, force: Bool = false) {
        #if canImport(WatchConnectivity)
        lastOutgoingState = state
        guard let session else { return }
        guard canSyncToWatch(session) else { return }
        guard let data = try? FitMeWatchCodec.encoder().encode(state) else { return }
        
        try? session.updateApplicationContext([FitMeWatchWireKey.workoutState: data])
        
        let isNewSession = state.sessionId != lastImmediateSentSessionId
        let isStatusChange = state.status != lastSentStatus
        
        if (force || isNewSession || isStatusChange || state.status == .ended) {
            if session.isReachable {
                session.sendMessage([FitMeWatchWireKey.workoutState: data], replyHandler: nil, errorHandler: { [weak self] _ in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if state != self.lastQueuedUserInfoState {
                            session.transferUserInfo([FitMeWatchWireKey.workoutState: data])
                            self.lastQueuedUserInfoState = state
                        }
                    }
                })
                lastImmediateSentSessionId = state.sessionId
                lastSentStatus = state.status
            } else if force || state != lastQueuedUserInfoState {
                // Fallback for status changes when not reachable
                session.transferUserInfo([FitMeWatchWireKey.workoutState: data])
                lastQueuedUserInfoState = state
            }
        }
        #else
        _ = state
        _ = force
        #endif
    }

    func sendAck(_ ack: FitMeWatchAck) {
        #if canImport(WatchConnectivity)
        guard let session else { return }
        guard canSyncToWatch(session) else { return }
        guard let data = try? FitMeWatchCodec.encoder().encode(ack) else { return }
        if session.isReachable {
            session.sendMessage([FitMeWatchWireKey.ack: data], replyHandler: nil, errorHandler: { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    if ack != self.lastQueuedUserInfoAck {
                        session.transferUserInfo([FitMeWatchWireKey.ack: data])
                        self.lastQueuedUserInfoAck = ack
                    }
                }
            })
        } else if ack != lastQueuedUserInfoAck {
            session.transferUserInfo([FitMeWatchWireKey.ack: data])
            lastQueuedUserInfoAck = ack
        }
        #else
        _ = ack
        #endif
    }

    func sendWorkoutSummary(_ summary: FitMeWatchWorkoutSummary) {
        #if canImport(WatchConnectivity)
        guard let session else { return }
        guard canSyncToWatch(session) else { return }
        guard let data = try? FitMeWatchCodec.encoder().encode(summary) else { return }

        try? session.updateApplicationContext([FitMeWatchWireKey.workoutSummary: data])

        if session.isReachable {
            session.sendMessage([FitMeWatchWireKey.workoutSummary: data], replyHandler: nil, errorHandler: { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    if summary != self.lastQueuedUserInfoSummary {
                        session.transferUserInfo([FitMeWatchWireKey.workoutSummary: data])
                        self.lastQueuedUserInfoSummary = summary
                    }
                }
            })
        } else if summary != lastQueuedUserInfoSummary {
            session.transferUserInfo([FitMeWatchWireKey.workoutSummary: data])
            lastQueuedUserInfoSummary = summary
        }
        #else
        _ = summary
        #endif
    }

    private func handleIncomingStateData(_ data: Data) {
        guard let state = try? FitMeWatchCodec.decoder().decode(FitMeWorkoutStateSnapshot.self, from: data) else { return }
        lastReceivedState = state
    }

    private func handleIncomingEventBatchData(_ data: Data) {
        guard let batch = try? FitMeWatchCodec.decoder().decode(FitMeWatchEventBatch.self, from: data),
              !batch.events.isEmpty else { return }

        // Always dedupe first so we persist "processed" status before ACKing.
        let newEvents = batch.events.filter { processedKeyStore.markIfNew(sessionId: $0.sessionId, key: $0.dedupeKey) }

        if !newEvents.isEmpty {
            // Persist before ACK so we can recover if the app is killed.
            persistIncomingEvents(newEvents)
        }

        // Fix iOS ACK starvation: always send an ACK for every incoming watch event batch,
        // even if all events are duplicates.
        let ack = FitMeWatchAck(sessionId: batch.events[0].sessionId, dedupeKeys: batch.events.map { $0.dedupeKey })
        sendAck(ack)

        guard !newEvents.isEmpty else { return }
        lastReceivedEvents = newEvents

        NotificationCenter.default.post(name: .fitMeDidReceiveWatchEvents, object: newEvents)
    }

    private func persistIncomingEvents(_ events: [FitMeWatchEvent]) {
        guard !events.isEmpty else { return }
        var all: [FitMeWatchEvent] = []
        if let data = defaults.data(forKey: Self.persistedIncomingEventsKey),
           let decoded = try? FitMeWatchCodec.decoder().decode([FitMeWatchEvent].self, from: data) {
            all = decoded
        }

        all.append(contentsOf: events)
        if all.count > Self.maxPersistedIncomingEvents {
            all.removeFirst(all.count - Self.maxPersistedIncomingEvents)
        }

        if let data = try? FitMeWatchCodec.encoder().encode(all) {
            defaults.set(data, forKey: Self.persistedIncomingEventsKey)
        }
    }

    #if canImport(WatchConnectivity)
    private func canSyncToWatch(_ session: WCSession) -> Bool {
        session.activationState == .activated && session.isPaired && session.isWatchAppInstalled
    }
    #endif
}

private final class ProcessedDedupeKeyStore {
    private static let maxKeysPerSession = 2000
    private let defaults = UserDefaults.standard
    private let keyPrefix = "fitme.watch.processedKeys."

    func markIfNew(sessionId: String, key: String) -> Bool {
        let storageKey = keyPrefix + sessionId
        var stored = defaults.array(forKey: storageKey) as? [String] ?? []
        if stored.contains(key) { return false }
        stored.append(key)
        if stored.count > Self.maxKeysPerSession {
            stored.removeFirst(stored.count - Self.maxKeysPerSession)
        }
        defaults.set(stored, forKey: storageKey)
        return true
    }
}

extension Notification.Name {
    static let fitMeDidReceiveWatchEvents = Notification.Name("fitme.didReceiveWatchEvents")
}

#if canImport(WatchConnectivity)
extension WatchWorkoutSync: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in
            refreshConnectionStatus()
            if activationState == .activated {
                flushLatestState()
            }
        }
        _ = error
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            if session.isReachable {
                flushLatestState()
            }
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            session.activate()
            refreshConnectionStatus()
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            refreshConnectionStatus()
            if session.activationState == .activated {
                flushLatestState()
            }
        }
    }
    #endif

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext[FitMeWatchWireKey.workoutState] as? Data {
            Task { @MainActor in
                handleIncomingStateData(data)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[FitMeWatchWireKey.eventBatch] as? Data {
            Task { @MainActor in
                handleIncomingEventBatchData(data)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let data = userInfo[FitMeWatchWireKey.eventBatch] as? Data {
            Task { @MainActor in
                handleIncomingEventBatchData(data)
            }
        }
    }
}
#endif
