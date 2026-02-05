//
//  StateManager.swift
//  CooldownShared
//
//  Central state management for the Cooldown system
//

import Foundation
import DeviceActivity
import FamilyControls
import Combine

/// Central manager for Cooldown system state
public final class StateManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = StateManager()
    
    // MARK: - Published Properties
    
    @Published public private(set) var settings: UserSettings
    @Published public private(set) var runtimeState: RuntimeState
    
    // MARK: - Constants
    
    /// Activity name for daily monitoring
    public static let dailyActivityName = DeviceActivityName("cooldown.daily")
    
    /// Event name for threshold reached
    public static let thresholdEventName = DeviceActivityEvent.Name("cooldown.threshold")
    
    // MARK: - Private
    
    private let persistence = PersistenceManager.shared
    private let shieldManager = ShieldManager.shared
    private let deviceActivityCenter = DeviceActivityCenter()
    private var timer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        self.settings = persistence.loadSettings()
        self.runtimeState = persistence.loadRuntimeState()
        
        // Reconcile state on launch
        reconcileState()
        
        // Start timer for state updates
        startTimer()
    }
    
    // MARK: - State Refresh
    
    /// Reload state from persistence (useful when extension has made changes)
    public func refresh() {
        settings = persistence.loadSettings()
        runtimeState = persistence.loadRuntimeState()
        reconcileState()
    }
    
    // MARK: - Monitoring Control
    
    /// Start monitoring selected apps
    public func startMonitoring() throws {
        guard settings.hasSelectedApps else {
            throw CooldownError.noAppsSelected
        }
        
        // Configure the daily monitoring schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        
        // Create an event that fires when threshold is reached
        let event = DeviceActivityEvent(
            applications: settings.familyActivitySelection.applicationTokens,
            categories: settings.familyActivitySelection.categoryTokens,
            webDomains: settings.familyActivitySelection.webDomainTokens,
            threshold: DateComponents(minute: settings.thresholdMinutes)
        )
        
        // Start monitoring
        try deviceActivityCenter.startMonitoring(
            Self.dailyActivityName,
            during: schedule,
            events: [Self.thresholdEventName: event]
        )
        
        // Update state
        runtimeState.startMonitoring()
        saveRuntimeState()
        
        // Log
        persistence.logEvent(.monitoringStarted)
    }
    
    /// Stop monitoring
    public func stopMonitoring() {
        deviceActivityCenter.stopMonitoring([Self.dailyActivityName])
        
        // Remove any active shields
        shieldManager.removeShield()
        
        // Update state
        runtimeState.currentState = .inactive
        runtimeState.cooldownEndTime = nil
        runtimeState.overrideEndTime = nil
        saveRuntimeState()
        
        // Log
        persistence.logEvent(.monitoringStopped)
    }
    
    /// Pause monitoring
    public func pauseMonitoring() {
        deviceActivityCenter.stopMonitoring([Self.dailyActivityName])
        shieldManager.removeShield()
        
        runtimeState.pause()
        saveRuntimeState()
    }
    
    /// Resume monitoring
    public func resumeMonitoring() throws {
        runtimeState.resume()
        saveRuntimeState()
        
        try startMonitoring()
    }
    
    // MARK: - Cooldown Control
    
    /// Trigger a cooldown (called from DeviceActivityMonitor extension)
    public func triggerCooldown() {
        runtimeState.triggerCooldown(durationMinutes: settings.cooldownMinutes)
        saveRuntimeState()
        
        // Apply shields
        shieldManager.applyShieldFromSettings()
        
        // Log
        persistence.logEvent(.cooldownStarted)
        
        // Send notification
        sendCooldownNotification()
    }
    
    /// Use an override (called from shield when user holds override button)
    public func useOverride() -> Bool {
        // Check if overrides available
        runtimeState.resetDailyIfNeeded()
        
        guard settings.softModeEnabled,
              runtimeState.overridesUsedToday < settings.overridesPerDay else {
            return false
        }
        
        runtimeState.useOverride(durationMinutes: settings.overrideMinutes)
        saveRuntimeState()
        
        // Remove shields temporarily
        shieldManager.removeShield()
        
        // Log
        persistence.logEvent(.overrideUsed)
        
        return true
    }
    
    /// Check how many overrides are remaining today
    public var overridesRemaining: Int {
        runtimeState.resetDailyIfNeeded()
        return max(0, settings.overridesPerDay - runtimeState.overridesUsedToday)
    }
    
    // MARK: - Settings
    
    /// Update settings
    public func updateSettings(_ newSettings: UserSettings) {
        var validatedSettings = newSettings
        validatedSettings.validate()
        
        settings = validatedSettings
        persistence.saveSettings(validatedSettings)
        
        // Log
        persistence.logEvent(.settingsChanged)
        
        // If monitoring, restart with new settings
        if runtimeState.currentState == .monitoring {
            do {
                try startMonitoring()
            } catch {
                print("Failed to restart monitoring: \(error)")
            }
        }
    }
    
    // MARK: - State Reconciliation
    
    /// Reconcile state based on current time
    private func reconcileState() {
        let previousState = runtimeState.currentState
        runtimeState.reconcile()
        
        // Handle state transitions
        if previousState == .cooldownActive && runtimeState.currentState == .monitoring {
            // Cooldown ended
            shieldManager.removeShield()
        } else if previousState == .overrideActive && runtimeState.currentState == .cooldownActive {
            // Override ended, resume cooldown
            shieldManager.applyShieldFromSettings()
        }
        
        saveRuntimeState()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    private func timerTick() {
        let previousState = runtimeState.currentState
        runtimeState.reconcile()
        
        // Check for state changes
        if previousState != runtimeState.currentState {
            if previousState == .cooldownActive && runtimeState.currentState == .monitoring {
                shieldManager.removeShield()
                persistence.logEvent(.cooldownEnded)
            } else if previousState == .overrideActive && runtimeState.currentState == .cooldownActive {
                shieldManager.applyShieldFromSettings()
                persistence.logEvent(.overrideEnded)
            }
            
            saveRuntimeState()
        }
        
        // Trigger UI refresh
        objectWillChange.send()
    }
    
    // MARK: - Helpers
    
    private func saveRuntimeState() {
        persistence.saveRuntimeState(runtimeState)
    }
    
    private func sendCooldownNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time for a breather! 🐧"
        content.body = "You've been scrolling for a while. Let's take a \(settings.cooldownMinutes)-minute break!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "cooldown.triggered",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Errors

public enum CooldownError: LocalizedError {
    case noAppsSelected
    case notAuthorized
    case monitoringFailed
    
    public var errorDescription: String? {
        switch self {
        case .noAppsSelected:
            return "Please select at least one app to monitor"
        case .notAuthorized:
            return "Screen Time access not authorized"
        case .monitoringFailed:
            return "Failed to start monitoring"
        }
    }
}

// MARK: - DeviceActivityName Extension

extension DeviceActivityName {
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}

extension DeviceActivityEvent.Name {
    public init(_ rawValue: String) {
        self.init(rawValue: rawValue)
    }
}
