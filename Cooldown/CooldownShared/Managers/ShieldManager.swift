//
//  ShieldManager.swift
//  CooldownShared
//
//  Manages applying and removing shields to selected apps
//

import Foundation
import ManagedSettings
import FamilyControls

/// Manages applying and removing shields to selected apps
public final class ShieldManager {
    
    // MARK: - Singleton
    
    public static let shared = ShieldManager()
    
    // MARK: - Properties
    
    /// The managed settings store for controlling app shields
    private let store = ManagedSettingsStore()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Shield Control
    
    /// Apply shields to the apps in the given selection
    public func applyShield(to selection: FamilyActivitySelection) {
        // Shield applications
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        
        // Shield categories
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        
        // Shield web domains if any
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        
        // Log the action
        PersistenceManager.shared.logEvent(.shieldDisplayed, details: "Shield applied to \(selection.applicationTokens.count) apps")
    }
    
    /// Remove all shields
    public func removeShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // Log the action
        PersistenceManager.shared.logEvent(.cooldownEnded, details: "Shields removed")
    }
    
    /// Check if shields are currently applied
    public var isShieldActive: Bool {
        store.shield.applications != nil || store.shield.applicationCategories != nil
    }
    
    // MARK: - Convenience
    
    /// Apply shields using the current user settings
    public func applyShieldFromSettings() {
        let settings = PersistenceManager.shared.loadSettings()
        applyShield(to: settings.familyActivitySelection)
    }
}
