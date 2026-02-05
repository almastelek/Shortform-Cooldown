//
//  RuntimeState.swift
//  CooldownShared
//
//  Runtime state tracking for the Cooldown app
//

import Foundation

/// Tracks the current runtime state of the Cooldown system
public struct RuntimeState: Codable, Equatable {
    
    // MARK: - State
    
    /// Current operational state
    public var currentState: CooldownState
    
    /// When the current cooldown period ends (nil if not in cooldown)
    public var cooldownEndTime: Date?
    
    /// When the current override period ends (nil if not in override)
    public var overrideEndTime: Date?
    
    // MARK: - Daily Tracking
    
    /// Number of overrides used today
    public var overridesUsedToday: Int
    
    /// The date when override count was last reset
    public var lastResetDate: Date
    
    // MARK: - Initialization
    
    public init(
        currentState: CooldownState = .inactive,
        cooldownEndTime: Date? = nil,
        overrideEndTime: Date? = nil,
        overridesUsedToday: Int = 0,
        lastResetDate: Date = Date()
    ) {
        self.currentState = currentState
        self.cooldownEndTime = cooldownEndTime
        self.overrideEndTime = overrideEndTime
        self.overridesUsedToday = overridesUsedToday
        self.lastResetDate = lastResetDate
    }
    
    /// Default initial state
    public static let initial = RuntimeState()
    
    // MARK: - Computed Properties
    
    /// Whether we're currently in an active cooldown
    public var isInCooldown: Bool {
        currentState == .cooldownActive && cooldownEndTime != nil
    }
    
    /// Whether we're currently in an active override
    public var isInOverride: Bool {
        currentState == .overrideActive && overrideEndTime != nil
    }
    
    /// Time remaining in cooldown (nil if not in cooldown)
    public var cooldownTimeRemaining: TimeInterval? {
        guard let endTime = cooldownEndTime else { return nil }
        let remaining = endTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }
    
    /// Time remaining in override (nil if not in override)
    public var overrideTimeRemaining: TimeInterval? {
        guard let endTime = overrideEndTime else { return nil }
        let remaining = endTime.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }
    
    /// Formatted cooldown remaining time (e.g., "4:32")
    public var cooldownTimeRemainingFormatted: String? {
        guard let remaining = cooldownTimeRemaining else { return nil }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - State Transitions
    
    /// Start monitoring
    public mutating func startMonitoring() {
        currentState = .monitoring
        cooldownEndTime = nil
        overrideEndTime = nil
    }
    
    /// Trigger cooldown with the specified duration
    public mutating func triggerCooldown(durationMinutes: Int) {
        currentState = .cooldownActive
        cooldownEndTime = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        overrideEndTime = nil
    }
    
    /// Use an override with the specified duration
    public mutating func useOverride(durationMinutes: Int) {
        currentState = .overrideActive
        overrideEndTime = Date().addingTimeInterval(TimeInterval(durationMinutes * 60))
        overridesUsedToday += 1
        // Keep cooldownEndTime so we can resume after override if needed
    }
    
    /// End cooldown and return to monitoring
    public mutating func endCooldown() {
        currentState = .monitoring
        cooldownEndTime = nil
        overrideEndTime = nil
    }
    
    /// End override and resume cooldown
    public mutating func endOverride() {
        currentState = .cooldownActive
        overrideEndTime = nil
        // cooldownEndTime should still be set
    }
    
    /// Pause monitoring
    public mutating func pause() {
        currentState = .paused
    }
    
    /// Resume monitoring from pause
    public mutating func resume() {
        currentState = .monitoring
        cooldownEndTime = nil
        overrideEndTime = nil
    }
    
    // MARK: - Daily Reset
    
    /// Check if we need to reset daily counters and do so if needed
    public mutating func resetDailyIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            overridesUsedToday = 0
            lastResetDate = Date()
        }
    }
    
    /// Check and reconcile state based on current time
    public mutating func reconcile() {
        resetDailyIfNeeded()
        
        switch currentState {
        case .cooldownActive:
            if let endTime = cooldownEndTime, Date() >= endTime {
                endCooldown()
            }
        case .overrideActive:
            if let endTime = overrideEndTime, Date() >= endTime {
                // Override ended, check if cooldown should resume or has also ended
                if let cooldownEnd = cooldownEndTime, Date() < cooldownEnd {
                    endOverride()
                } else {
                    endCooldown()
                }
            }
        default:
            break
        }
    }
}
