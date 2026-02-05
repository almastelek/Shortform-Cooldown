//
//  CooldownMonitor.swift
//  CooldownMonitor
//
//  DeviceActivityMonitor extension that triggers cooldowns
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import CooldownShared

/// Monitors device activity and triggers cooldowns when thresholds are reached
class CooldownMonitor: DeviceActivityMonitor {
    
    private let persistence = PersistenceManager.shared
    private let shieldManager = ShieldManager.shared
    
    // MARK: - Interval Callbacks
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Log that monitoring interval started
        persistence.logEvent(.monitoringStarted, details: "Daily interval started")
        
        // Reconcile state in case app was in cooldown that should have ended
        persistence.updateRuntimeState { state in
            state.reconcile()
            
            // Remove shields if cooldown ended while we were inactive
            if state.currentState == .monitoring {
                self.shieldManager.removeShield()
            }
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Log interval end
        persistence.logEvent(.monitoringStopped, details: "Daily interval ended")
    }
    
    // MARK: - Threshold Callbacks
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // Only handle our threshold event
        guard event == StateManager.thresholdEventName else { return }
        
        // Load current state
        var state = persistence.loadRuntimeState()
        let settings = persistence.loadSettings()
        
        // Check if already in cooldown or override
        guard state.currentState == .monitoring else {
            return
        }
        
        // Trigger cooldown
        state.triggerCooldown(durationMinutes: settings.cooldownMinutes)
        persistence.saveRuntimeState(state)
        
        // Apply shields
        shieldManager.applyShield(to: settings.familyActivitySelection)
        
        // Log event
        persistence.logEvent(.cooldownStarted, details: "Threshold of \(settings.thresholdMinutes) minutes reached")
        
        // Send notification
        sendCooldownNotification(cooldownMinutes: settings.cooldownMinutes)
    }
    
    // MARK: - Warning Callbacks (unused but required)
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        // We're not using pre-threshold warnings per user preference
    }
    
    // MARK: - Notifications
    
    private func sendCooldownNotification(cooldownMinutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a breather! 🐧"
        content.body = getRandomCooldownMessage(minutes: cooldownMinutes)
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(
            identifier: "cooldown.triggered.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                self.persistence.logEvent(.error, details: "Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    private func getRandomCooldownMessage(minutes: Int) -> String {
        let messages = [
            "You've been scrolling for a while. Let's take a \(minutes)-minute break! 🌟",
            "Hey, you've seen enough for now! Time to do something else. 💙",
            "Let's take a quick break together! See you in \(minutes) minutes. 🧊",
            "Brain break time! Step away for \(minutes) minutes. 🌈",
            "Scroll session complete! Take \(minutes) to recharge. ⚡️"
        ]
        return messages.randomElement() ?? messages[0]
    }
}
