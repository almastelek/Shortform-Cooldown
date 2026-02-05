//
//  ShieldConfigurationExtension.swift
//  CooldownShield
//
//  Custom shield UI displayed when blocked apps are opened
//

import ManagedSettings
import ManagedSettingsUI
import UIKit
import CooldownShared

/// Provides custom shield configuration for blocked apps
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private let persistence = PersistenceManager.shared
    
    // MARK: - Shield Configuration
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShieldConfiguration()
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfiguration()
    }
    
    // MARK: - Configuration Builder
    
    private func createShieldConfiguration() -> ShieldConfiguration {
        let state = persistence.loadRuntimeState()
        let settings = persistence.loadSettings()
        
        // Calculate remaining time
        let timeRemaining = state.cooldownTimeRemaining ?? 0
        let minutesRemaining = Int(timeRemaining) / 60
        let secondsRemaining = Int(timeRemaining) % 60
        let timeString = String(format: "%d:%02d", minutesRemaining, secondsRemaining)
        
        // Choose a random message
        let messages = [
            "You've seen enough for now 🐧",
            "Let's take a breather together! 🧊",
            "Time for a quick break 💙",
            "Brain break in progress... 🌟",
            "Just a short pause! 🌈"
        ]
        let subtitle = messages.randomElement() ?? messages[0]
        
        // Primary button - opens main app
        let primaryAction = ShieldConfiguration.Label(
            text: "Open Cooldown",
            color: UIColor(named: "Primary") ?? .systemTeal
        )
        
        // Secondary button - override (if available)
        var secondaryAction: ShieldConfiguration.Label? = nil
        
        if settings.softModeEnabled {
            state.resetDailyIfNeeded()
            let overridesRemaining = settings.overridesPerDay - state.overridesUsedToday
            
            if overridesRemaining > 0 {
                secondaryAction = ShieldConfiguration.Label(
                    text: "Use Override (\(overridesRemaining) left)",
                    color: UIColor(named: "Accent") ?? .systemOrange
                )
            }
        }
        
        // Create icon from SF Symbol
        let icon = ShieldConfiguration.Label(
            text: timeString,
            color: UIColor(named: "Primary") ?? .systemTeal
        )
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(named: "Background") ?? .systemBackground,
            icon: icon,
            title: ShieldConfiguration.Label(
                text: timeRemaining > 0 ? timeString : "Cooldown Active",
                color: UIColor(named: "TextPrimary") ?? .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: UIColor(named: "TextSecondary") ?? .secondaryLabel
            ),
            primaryButtonLabel: primaryAction,
            primaryButtonBackgroundColor: UIColor(named: "Primary") ?? .systemTeal,
            secondaryButtonLabel: secondaryAction
        )
    }
}

// MARK: - Shield Action Extension

/// Handles shield button actions
class ShieldActionExtension: ShieldActionDelegate {
    
    private let persistence = PersistenceManager.shared
    private let shieldManager = ShieldManager.shared
    
    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }
    
    override func handle(
        action: ShieldAction,
        for webDomain: WebDomain,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }
    
    override func handle(
        action: ShieldAction,
        for category: ActivityCategory,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }
    
    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // Open main app - handled by system
            completionHandler(.close)
            
        case .secondaryButtonPressed:
            // Use override
            let settings = persistence.loadSettings()
            var state = persistence.loadRuntimeState()
            
            state.resetDailyIfNeeded()
            
            guard settings.softModeEnabled,
                  state.overridesUsedToday < settings.overridesPerDay else {
                completionHandler(.none)
                return
            }
            
            // Activate override
            state.useOverride(durationMinutes: settings.overrideMinutes)
            persistence.saveRuntimeState(state)
            
            // Remove shields temporarily
            shieldManager.removeShield()
            
            // Log
            persistence.logEvent(.overrideUsed)
            
            // Allow access
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.none)
        }
    }
}
