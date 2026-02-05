//
//  CooldownState.swift
//  CooldownShared
//
//  State machine states for the Cooldown app
//

import Foundation

/// Represents the current operational state of the Cooldown system
public enum CooldownState: String, Codable, Equatable {
    /// App is installed but monitoring has not been started
    case inactive
    
    /// Actively monitoring selected apps for usage threshold
    case monitoring
    
    /// Usage threshold reached - apps are shielded during cooldown period
    case cooldownActive
    
    /// User has activated an override - temporary access granted
    case overrideActive
    
    /// Monitoring temporarily paused by user
    case paused
    
    /// An error occurred in the monitoring system
    case error
    
    /// Human-readable status message
    public var displayMessage: String {
        switch self {
        case .inactive:
            return "Not monitoring"
        case .monitoring:
            return "Keeping an eye on things 👀"
        case .cooldownActive:
            return "Taking a breather..."
        case .overrideActive:
            return "Override active"
        case .paused:
            return "Monitoring paused"
        case .error:
            return "Something went wrong"
        }
    }
    
    /// Color name for the state (matches asset catalog)
    public var colorName: String {
        switch self {
        case .inactive:
            return "StateInactive"
        case .monitoring:
            return "StateMonitoring"
        case .cooldownActive:
            return "StateCooldown"
        case .overrideActive:
            return "StateOverride"
        case .paused:
            return "StatePaused"
        case .error:
            return "StateError"
        }
    }
}
