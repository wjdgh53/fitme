import Foundation
import SwiftUI

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

#if canImport(WatchKit)
import WatchKit
#endif

#if canImport(WatchKit)

@MainActor
final class WatchWorkoutController: ObservableObject {
    @Published var status: FitMeWatchWorkoutStatus = .idle
    @Published var sessionId: String? = nil
    @Published var exerciseName: String = "Loading Plan..."
    @Published var currentExerciseIndex: Int = 0
    @Published var totalExercises: Int = 0
    @Published var currentSetIndex: Int = 0
    @Published var totalSets: Int = 0
    @Published var currentWeight: Int? = nil
    @Published var currentReps: Int? = nil
    @Published var previousWeight: Int? = nil
    @Published var previousReps: Int? = nil
    @Published var weightUnit: String = "kg"
    @Published var restRemainingSeconds: Int = 60
    @Published var elapsedSeconds: Int = 0
    @Published var workoutSummary: FitMeWatchWorkoutSummary? = nil

    private let link = WatchPhoneLink()
    private let store = WatchEventQueueStore()
    private var lastAppliedStateUpdatedAt: Date? = nil
    private var pollingTask: Task<Void, Never>? = nil

    init() {
        link.onStateUpdate = { [weak self] state in
            Task { @MainActor in
                self?.applyPhoneState(state)
            }
        }

        link.onSummaryUpdate = { [weak self] summary in
            Task { @MainActor in
                self?.applyPhoneSummary(summary)
            }
        }

        link.onAck = { [weak self] ack in
            Task { @MainActor in
                self?.store.remove(dedupeKeys: ack.dedupeKeys, sessionId: ack.sessionId)
            }
        }

        link.processCurrentContextIfAny()

        // Try flushing any pending events when the app starts.
        Task { @MainActor in
            flushPendingEvents()
        }

#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--demo-active") {
            sessionId = "demo"
            status = .active
            exerciseName = "Barbell Curl"
            currentExerciseIndex = 1
            totalExercises = 6
            currentSetIndex = 2
            totalSets = 5
            currentWeight = 65
            currentReps = 8
            weightUnit = "lb"
            restRemainingSeconds = 0
            elapsedSeconds = 26
        }
#endif
    }

    func onStart() {
        let hasPreparedPlan = (status == .idle && sessionId != nil && totalExercises > 0)

        workoutSummary = nil
        previousWeight = nil
        previousReps = nil
        restRemainingSeconds = 0
        elapsedSeconds = 0

        if hasPreparedPlan {
            // Phone already staged a plan for this sessionId.
            // Start immediately without showing the "Generating plan..." step.
            status = .active
            enqueueEvent(type: .start)
            playHaptic(.start)
            return
        }

        lastAppliedStateUpdatedAt = nil

        sessionId = UUID().uuidString
        exerciseName = "Generating plan..."
        currentExerciseIndex = 0
        totalExercises = 0
        currentSetIndex = 0
        totalSets = 0
        currentWeight = nil
        currentReps = nil
        status = .generating
        startGeneratingTimeoutPolling()
        enqueueEvent(type: .start)
        playHaptic(.start)
    }

    func resetToIdle() {
        pollingTask?.cancel()
        pollingTask = nil
        lastAppliedStateUpdatedAt = nil
        status = .idle
        sessionId = nil
        workoutSummary = nil
        exerciseName = "Ready"
        currentExerciseIndex = 0
        totalExercises = 0
        currentSetIndex = 0
        totalSets = 0
        currentWeight = nil
        currentReps = nil
        previousWeight = nil
        previousReps = nil
        restRemainingSeconds = 0
        elapsedSeconds = 0
    }

    func tickElapsed() {
        guard status == .active || status == .resting else { return }
        elapsedSeconds += 1
    }

    func changeWeight(by delta: Int) {
        let current = currentWeight ?? 0
        let next = max(0, current + delta)
        currentWeight = next
        enqueueEvent(type: .adjustWeight, payload: ["value": "\(next)"])
    }

    func changeReps(by delta: Int) {
        let current = currentReps ?? 0
        let next = max(0, current + delta)
        currentReps = next
        enqueueEvent(type: .adjustReps, payload: ["value": "\(next)"])
    }

    func onCompleteSet() {
        guard status == .active else { return }
        previousWeight = currentWeight
        previousReps = currentReps
        let hasTotalExercises = totalExercises > 0
        let hasTotalSets = totalSets > 0
        let isLastSet = hasTotalSets && currentSetIndex >= totalSets
        // `currentExerciseIndex` is stored as 1-based for display.
        let isLastExercise = hasTotalExercises && currentExerciseIndex >= totalExercises

        if isLastSet && isLastExercise {
            enqueueEvent(type: .end)
            status = .ended
            playHaptic(.success)
            return
        }

        status = .resting
        restRemainingSeconds = max(0, restRemainingSeconds)
        enqueueEvent(type: .completeSet)
        playHaptic(.success)
    }

    func onSkipRest() {
        guard status == .resting else { return }
        status = .active
        currentSetIndex = min(max(1, currentSetIndex + 1), max(1, totalSets))
        enqueueEvent(type: .skipRest)
        playHaptic(.click)
    }

    func onPause() {
        guard status == .active || status == .resting else { return }
        status = .paused
        enqueueEvent(type: .pause)
        playHaptic(.click)
    }

    func onResume() {
        guard status == .paused else { return }
        status = .active
        enqueueEvent(type: .resume)
        playHaptic(.click)
    }

    func onEnd() {
        pollingTask?.cancel()
        pollingTask = nil
        enqueueEvent(type: .end)
        status = .ended
        playHaptic(.failure)
    }

    func onChangeExercise() {
        enqueueEvent(type: .changeExercise)
        playHaptic(.click)
    }

    func updateRestSeconds(_ seconds: Int) {
        restRemainingSeconds = max(0, min(600, seconds))
        enqueueEvent(type: .adjustRest, payload: ["seconds": "\(restRemainingSeconds)"])
    }

    func tickRest() {
        guard status == .resting else { return }
        if restRemainingSeconds > 0 {
            restRemainingSeconds -= 1
            if restRemainingSeconds == 0 {
                playHaptic(.notification)
            }
        }
    }

    func flushPendingEvents() {
        guard let sid = sessionId ?? store.peekSessionId() else {
            link.flush(events: [])
            return
        }
        let pending = store.pendingEvents(for: sid)
        link.flush(events: pending)
    }

    private func enqueueEvent(type: FitMeWatchEventType, payload: [String: String]? = nil) {
        let sid = sessionId ?? UUID().uuidString
        sessionId = sid
        let event = FitMeWatchEvent(sessionId: sid, type: type, payload: payload)
        store.append(event)
        flushPendingEvents()
    }

    private func applyPhoneState(_ state: FitMeWorkoutStateSnapshot) {
        if let last = lastAppliedStateUpdatedAt, sessionId == state.sessionId, state.updatedAt <= last {
            return
        }
        lastAppliedStateUpdatedAt = state.updatedAt

        let oldSessionId = sessionId
        let oldSetIndex = currentSetIndex
        let oldWeight = currentWeight
        let oldReps = currentReps

        if oldSessionId != state.sessionId {
            previousWeight = nil
            previousReps = nil
            elapsedSeconds = 0
        } else if state.currentSetIndex > oldSetIndex {
            previousWeight = oldWeight
            previousReps = oldReps
        }

        sessionId = state.sessionId
        exerciseName = state.exerciseName
        // Phone sends 0-based; watch stores 1-based for display.
        currentExerciseIndex = max(1, state.currentExerciseIndex + 1)
        totalExercises = max(0, state.totalExercises)
        currentSetIndex = max(1, state.currentSetIndex)
        totalSets = max(0, state.totalSets)
        currentWeight = state.currentWeight
        currentReps = state.currentReps
        if let unit = state.weightUnit {
            weightUnit = unit
        }
        restRemainingSeconds = max(0, state.restRemainingSeconds)
        status = state.status
        
        if status != .generating {
            pollingTask?.cancel()
            pollingTask = nil
        }
    }

    private func startGeneratingTimeoutPolling() {
        pollingTask?.cancel()
        pollingTask = Task { @MainActor [weak self] in
            let startTime = Date()
            let timeout: TimeInterval = 20
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                
                guard let self = self else { break }
                if self.status != .generating { break }
                
                self.link.processCurrentContextIfAny()
                
                if Date().timeIntervalSince(startTime) > timeout {
                    if self.status == .generating {
                        self.status = .error
                        self.exerciseName = "No connection to iPhone"
                        self.playHaptic(.failure)
                    }
                    break
                }
            }
        }
    }

    private func applyPhoneSummary(_ summary: FitMeWatchWorkoutSummary) {
        guard sessionId == nil || summary.sessionId == sessionId else { return }
        workoutSummary = summary
    }

    private enum Haptic {
        case start
        case click
        case success
        case failure
        case notification
    }

    private func playHaptic(_ haptic: Haptic) {
        #if canImport(WatchKit)
        switch haptic {
        case .start:
            WKInterfaceDevice.current().play(.start)
        case .click:
            WKInterfaceDevice.current().play(.click)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .failure:
            WKInterfaceDevice.current().play(.failure)
        case .notification:
            WKInterfaceDevice.current().play(.notification)
        }
        #else
        _ = haptic
        #endif
    }
}

final class WatchEventQueueStore {
    private static let storageKey = "fitme.watch.eventQueue"
    private let defaults = UserDefaults.standard

    func peekSessionId() -> String? {
        loadAll().last?.sessionId
    }

    func append(_ event: FitMeWatchEvent) {
        var all = loadAll()
        all.append(event)
        saveAll(all)
    }

    func pendingEvents(for sessionId: String) -> [FitMeWatchEvent] {
        loadAll().filter { $0.sessionId == sessionId }
    }

    func remove(dedupeKeys: [String], sessionId: String) {
        guard !dedupeKeys.isEmpty else { return }
        let keys = Set(dedupeKeys)
        let filtered = loadAll().filter { !($0.sessionId == sessionId && keys.contains($0.dedupeKey)) }
        saveAll(filtered)
    }

    private func loadAll() -> [FitMeWatchEvent] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return (try? FitMeWatchCodec.decoder().decode([FitMeWatchEvent].self, from: data)) ?? []
    }

    private func saveAll(_ events: [FitMeWatchEvent]) {
        let data = try? FitMeWatchCodec.encoder().encode(events)
        defaults.set(data, forKey: Self.storageKey)
    }
}

final class WatchPhoneLink: NSObject {
    var onStateUpdate: ((FitMeWorkoutStateSnapshot) -> Void)?
    var onAck: ((FitMeWatchAck) -> Void)?
    var onSummaryUpdate: ((FitMeWatchWorkoutSummary) -> Void)?

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
        #endif
    }

    func flush(events: [FitMeWatchEvent]) {
        #if canImport(WatchConnectivity)
        guard let session else { return }
        guard !events.isEmpty else { return }

        let batch = FitMeWatchEventBatch(events: events)
        guard let data = try? FitMeWatchCodec.encoder().encode(batch) else { return }

        if session.isReachable {
            session.sendMessage([FitMeWatchWireKey.eventBatch: data], replyHandler: nil) { [weak self] _ in
                self?.session?.transferUserInfo([FitMeWatchWireKey.eventBatch: data])
            }
        } else {
            session.transferUserInfo([FitMeWatchWireKey.eventBatch: data])
        }
        #else
        _ = events
        #endif
    }

    func processCurrentContextIfAny() {
        #if canImport(WatchConnectivity)
        guard let session, session.activationState == .activated else { return }
        let context = session.receivedApplicationContext
        if let data = context[FitMeWatchWireKey.workoutState] as? Data,
           let state = try? FitMeWatchCodec.decoder().decode(FitMeWorkoutStateSnapshot.self, from: data) {
            onStateUpdate?(state)
        }
        if let data = context[FitMeWatchWireKey.workoutSummary] as? Data,
           let summary = try? FitMeWatchCodec.decoder().decode(FitMeWatchWorkoutSummary.self, from: data) {
            onSummaryUpdate?(summary)
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchPhoneLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if activationState == .activated {
            processCurrentContextIfAny()
        }
        _ = session
        _ = error
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let data = applicationContext[FitMeWatchWireKey.workoutState] as? Data,
           let state = try? FitMeWatchCodec.decoder().decode(FitMeWorkoutStateSnapshot.self, from: data) {
            onStateUpdate?(state)
        }
        if let data = applicationContext[FitMeWatchWireKey.workoutSummary] as? Data,
           let summary = try? FitMeWatchCodec.decoder().decode(FitMeWatchWorkoutSummary.self, from: data) {
            onSummaryUpdate?(summary)
        }
        _ = session
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let data = message[FitMeWatchWireKey.workoutState] as? Data,
           let state = try? FitMeWatchCodec.decoder().decode(FitMeWorkoutStateSnapshot.self, from: data) {
            onStateUpdate?(state)
        }
        if let data = message[FitMeWatchWireKey.workoutSummary] as? Data,
           let summary = try? FitMeWatchCodec.decoder().decode(FitMeWatchWorkoutSummary.self, from: data) {
            onSummaryUpdate?(summary)
        }
        if let data = message[FitMeWatchWireKey.ack] as? Data,
           let ack = try? FitMeWatchCodec.decoder().decode(FitMeWatchAck.self, from: data) {
            onAck?(ack)
        }
        _ = session
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if let data = userInfo[FitMeWatchWireKey.workoutState] as? Data,
           let state = try? FitMeWatchCodec.decoder().decode(FitMeWorkoutStateSnapshot.self, from: data) {
            onStateUpdate?(state)
        }
        if let data = userInfo[FitMeWatchWireKey.workoutSummary] as? Data,
           let summary = try? FitMeWatchCodec.decoder().decode(FitMeWatchWorkoutSummary.self, from: data) {
            onSummaryUpdate?(summary)
        }
        if let data = userInfo[FitMeWatchWireKey.ack] as? Data,
           let ack = try? FitMeWatchCodec.decoder().decode(FitMeWatchAck.self, from: data) {
            onAck?(ack)
        }
        _ = session
    }
}
#endif

#endif
