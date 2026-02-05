//
//  UserSettings.swift
//  CooldownShared
//
//  User-configurable settings for the Cooldown app
//

import Foundation
import FamilyControls

/// User-configurable settings for the Cooldown behavior
public struct UserSettings: Codable, Equatable {
    
    // MARK: - App Selection
    
    /// The set of apps selected for monitoring
    /// Stored as FamilyActivitySelection for FamilyControls compatibility
    public var familyActivitySelection: FamilyActivitySelection
    
    // MARK: - Timing Configuration
    
    /// Minutes of continuous usage before triggering cooldown (default: 15)
    public var thresholdMinutes: Int
    
    /// Minutes the cooldown period lasts (default: 5)
    public var cooldownMinutes: Int
    
    /// Seconds outside apps needed to reset the usage counter (default: 90)
    public var breakSeconds: Int
    
    // MARK: - Override Configuration
    
    /// Whether soft override mode is enabled (default: true)
    public var softModeEnabled: Bool
    
    /// Number of overrides allowed per day (default: 1)
    public var overridesPerDay: Int
    
    /// Minutes of additional access granted per override (default: 2)
    public var overrideMinutes: Int
    
    // MARK: - Onboarding
    
    /// Whether the user has completed onboarding
    public var hasCompletedOnboarding: Bool
    
    // MARK: - Initialization
    
    public init(
        familyActivitySelection: FamilyActivitySelection = FamilyActivitySelection(),
        thresholdMinutes: Int = 15,
        cooldownMinutes: Int = 5,
        breakSeconds: Int = 90,
        softModeEnabled: Bool = true,
        overridesPerDay: Int = 1,
        overrideMinutes: Int = 2,
        hasCompletedOnboarding: Bool = false
    ) {
        self.familyActivitySelection = familyActivitySelection
        self.thresholdMinutes = thresholdMinutes
        self.cooldownMinutes = cooldownMinutes
        self.breakSeconds = breakSeconds
        self.softModeEnabled = softModeEnabled
        self.overridesPerDay = overridesPerDay
        self.overrideMinutes = overrideMinutes
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
    
    /// Default settings
    public static let `default` = UserSettings()
    
    // MARK: - Validation
    
    /// Whether the user has selected at least one app
    public var hasSelectedApps: Bool {
        !familyActivitySelection.applicationTokens.isEmpty ||
        !familyActivitySelection.categoryTokens.isEmpty
    }
    
    /// Clamp values to valid ranges
    public mutating func validate() {
        thresholdMinutes = max(1, min(60, thresholdMinutes))
        cooldownMinutes = max(1, min(30, cooldownMinutes))
        breakSeconds = max(30, min(300, breakSeconds))
        overridesPerDay = max(0, min(5, overridesPerDay))
        overrideMinutes = max(1, min(10, overrideMinutes))
    }
}

// MARK: - Threshold Presets

extension UserSettings {
    /// Preset timing configurations
    public enum Preset: String, CaseIterable {
        case gentle = "Gentle"
        case balanced = "Balanced"
        case strict = "Strict"
        
        public var thresholdMinutes: Int {
            switch self {
            case .gentle: return 20
            case .balanced: return 15
            case .strict: return 10
            }
        }
        
        public var cooldownMinutes: Int {
            switch self {
            case .gentle: return 3
            case .balanced: return 5
            case .strict: return 10
            }
        }
        
        public var description: String {
            switch self {
            case .gentle:
                return "Longer sessions, shorter breaks"
            case .balanced:
                return "Recommended for most people"
            case .strict:
                return "Shorter sessions, longer breaks"
            }
        }
    }
    
    /// Apply a preset configuration
    public mutating func apply(preset: Preset) {
        thresholdMinutes = preset.thresholdMinutes
        cooldownMinutes = preset.cooldownMinutes
    }
}
