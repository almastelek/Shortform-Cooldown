//
//  PersistenceManager.swift
//  CooldownShared
//
//  Manages persistent storage across app and extensions via App Groups
//

import Foundation
import FamilyControls

/// Manages persistent storage for Cooldown using App Groups
public final class PersistenceManager {
    
    // MARK: - Singleton
    
    public static let shared = PersistenceManager()
    
    // MARK: - Constants
    
    private let appGroupIdentifier = "group.com.almas.shortform-cooldown"
    
    private enum Keys {
        static let userSettings = "userSettings"
        static let runtimeState = "runtimeState"
        static let eventLog = "eventLog"
    }
    
    // MARK: - Storage
    
    private lazy var sharedDefaults: UserDefaults? = {
        UserDefaults(suiteName: appGroupIdentifier)
    }()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Thread Safety
    
    private let queue = DispatchQueue(label: "com.almas.cooldown.persistence", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - User Settings
    
    /// Load user settings
    public func loadSettings() -> UserSettings {
        queue.sync {
            guard let defaults = sharedDefaults,
                  let data = defaults.data(forKey: Keys.userSettings),
                  let settings = try? decoder.decode(UserSettings.self, from: data) else {
                return .default
            }
            return settings
        }
    }
    
    /// Save user settings
    public func saveSettings(_ settings: UserSettings) {
        queue.async { [weak self] in
            guard let self = self,
                  let defaults = self.sharedDefaults,
                  let data = try? self.encoder.encode(settings) else {
                return
            }
            defaults.set(data, forKey: Keys.userSettings)
        }
    }
    
    // MARK: - Runtime State
    
    /// Load runtime state
    public func loadRuntimeState() -> RuntimeState {
        queue.sync {
            guard let defaults = sharedDefaults,
                  let data = defaults.data(forKey: Keys.runtimeState),
                  let state = try? decoder.decode(RuntimeState.self, from: data) else {
                return .initial
            }
            return state
        }
    }
    
    /// Save runtime state
    public func saveRuntimeState(_ state: RuntimeState) {
        queue.async { [weak self] in
            guard let self = self,
                  let defaults = self.sharedDefaults,
                  let data = try? self.encoder.encode(state) else {
                return
            }
            defaults.set(data, forKey: Keys.runtimeState)
        }
    }
    
    /// Update runtime state atomically
    public func updateRuntimeState(_ transform: (inout RuntimeState) -> Void) {
        queue.sync {
            var state = loadRuntimeStateInternal()
            transform(&state)
            saveRuntimeStateInternal(state)
        }
    }
    
    private func loadRuntimeStateInternal() -> RuntimeState {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.runtimeState),
              let state = try? decoder.decode(RuntimeState.self, from: data) else {
            return .initial
        }
        return state
    }
    
    private func saveRuntimeStateInternal(_ state: RuntimeState) {
        guard let defaults = sharedDefaults,
              let data = try? encoder.encode(state) else {
            return
        }
        defaults.set(data, forKey: Keys.runtimeState)
    }
    
    // MARK: - Event Log
    
    /// Load event log
    public func loadEventLog() -> EventLog {
        queue.sync {
            guard let defaults = sharedDefaults,
                  let data = defaults.data(forKey: Keys.eventLog),
                  let log = try? decoder.decode(EventLog.self, from: data) else {
                return EventLog()
            }
            return log
        }
    }
    
    /// Save event log
    public func saveEventLog(_ log: EventLog) {
        queue.async { [weak self] in
            guard let self = self,
                  let defaults = self.sharedDefaults,
                  let data = try? self.encoder.encode(log) else {
                return
            }
            defaults.set(data, forKey: Keys.eventLog)
        }
    }
    
    /// Log an event
    public func logEvent(_ eventType: EventType, details: String? = nil, duration: TimeInterval? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let log = self.loadEventLogInternal()
            log.log(eventType, details: details, duration: duration)
            self.saveEventLogInternal(log)
        }
    }
    
    private func loadEventLogInternal() -> EventLog {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Keys.eventLog),
              let log = try? decoder.decode(EventLog.self, from: data) else {
            return EventLog()
        }
        return log
    }
    
    private func saveEventLogInternal(_ log: EventLog) {
        guard let defaults = sharedDefaults,
              let data = try? encoder.encode(log) else {
            return
        }
        defaults.set(data, forKey: Keys.eventLog)
    }
    
    // MARK: - Reset
    
    /// Clear all stored data
    public func clearAll() {
        queue.async { [weak self] in
            guard let self = self,
                  let defaults = self.sharedDefaults else { return }
            defaults.removeObject(forKey: Keys.userSettings)
            defaults.removeObject(forKey: Keys.runtimeState)
            defaults.removeObject(forKey: Keys.eventLog)
        }
    }
}
