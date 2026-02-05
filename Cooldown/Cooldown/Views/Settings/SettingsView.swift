//
//  SettingsView.swift
//  Cooldown
//
//  Settings screen for configuring thresholds and behavior
//

import SwiftUI
import CooldownShared

struct SettingsView: View {
    @EnvironmentObject var stateManager: StateManager
    
    @State private var thresholdMinutes: Double = 15
    @State private var cooldownMinutes: Double = 5
    @State private var softModeEnabled: Bool = true
    @State private var overridesPerDay: Int = 1
    @State private var showingResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Presets
                    presetsSection
                    
                    // Timing settings
                    timingSection
                    
                    // Override settings
                    overrideSection
                    
                    // Danger zone
                    dangerZone
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [Color("Background"), Color("BackgroundSecondary")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadSettings()
            }
            .alert("Reset Everything?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will clear all your settings, data, and stop monitoring. You'll need to go through setup again.")
            }
        }
    }
    
    // MARK: - Presets
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Quick Presets", icon: "wand.and.stars")
            
            HStack(spacing: 12) {
                ForEach(UserSettings.Preset.allCases, id: \.self) { preset in
                    presetButton(preset)
                }
            }
        }
    }
    
    private func presetButton(_ preset: UserSettings.Preset) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                thresholdMinutes = Double(preset.thresholdMinutes)
                cooldownMinutes = Double(preset.cooldownMinutes)
                saveSettings()
            }
        } label: {
            VStack(spacing: 8) {
                Text(preset.rawValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isPresetSelected(preset) ? .white : Color("TextPrimary"))
                
                Text("\(preset.thresholdMinutes)/\(preset.cooldownMinutes)m")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(isPresetSelected(preset) ? .white.opacity(0.8) : Color("TextSecondary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPresetSelected(preset) ?
                          AnyShapeStyle(LinearGradient(colors: [Color("Primary"), Color("Secondary")], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                          AnyShapeStyle(Color("CardBackground")))
            )
        }
    }
    
    private func isPresetSelected(_ preset: UserSettings.Preset) -> Bool {
        Int(thresholdMinutes) == preset.thresholdMinutes && 
        Int(cooldownMinutes) == preset.cooldownMinutes
    }
    
    // MARK: - Timing
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Timing", icon: "clock.fill")
            
            VStack(spacing: 20) {
                // Threshold slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Scroll limit")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextPrimary"))
                        
                        Spacer()
                        
                        Text("\(Int(thresholdMinutes)) min")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color("Primary"))
                    }
                    
                    Slider(value: $thresholdMinutes, in: 5...60, step: 5)
                        .tint(Color("Primary"))
                        .onChange(of: thresholdMinutes) { _ in
                            saveSettings()
                        }
                    
                    Text("How long you can scroll before I suggest a break")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color("TextSecondary"))
                }
                
                Divider()
                
                // Cooldown slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Break duration")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextPrimary"))
                        
                        Spacer()
                        
                        Text("\(Int(cooldownMinutes)) min")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color("Primary"))
                    }
                    
                    Slider(value: $cooldownMinutes, in: 1...15, step: 1)
                        .tint(Color("Primary"))
                        .onChange(of: cooldownMinutes) { _ in
                            saveSettings()
                        }
                    
                    Text("How long the break lasts")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color("TextSecondary"))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
        }
    }
    
    // MARK: - Override
    
    private var overrideSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Overrides", icon: "hand.raised.fill")
            
            VStack(spacing: 16) {
                // Soft mode toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Allow overrides")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("TextPrimary"))
                        
                        Text("Let me skip a break (with limits)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color("TextSecondary"))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $softModeEnabled)
                        .labelsHidden()
                        .tint(Color("Primary"))
                        .onChange(of: softModeEnabled) { _ in
                            saveSettings()
                        }
                }
                
                if softModeEnabled {
                    Divider()
                    
                    // Overrides per day
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Overrides per day")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("TextPrimary"))
                            
                            Text("Resets at midnight")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color("TextSecondary"))
                        }
                        
                        Spacer()
                        
                        Picker("", selection: $overridesPerDay) {
                            ForEach(0...5, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: overridesPerDay) { _ in
                            saveSettings()
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardBackground"))
            )
        }
    }
    
    // MARK: - Danger Zone
    
    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Danger Zone", icon: "exclamationmark.triangle.fill")
            
            Button {
                showingResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset App")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.05))
                        )
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color("Primary"))
            
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color("TextSecondary"))
                .textCase(.uppercase)
        }
    }
    
    private func loadSettings() {
        thresholdMinutes = Double(stateManager.settings.thresholdMinutes)
        cooldownMinutes = Double(stateManager.settings.cooldownMinutes)
        softModeEnabled = stateManager.settings.softModeEnabled
        overridesPerDay = stateManager.settings.overridesPerDay
    }
    
    private func saveSettings() {
        var newSettings = stateManager.settings
        newSettings.thresholdMinutes = Int(thresholdMinutes)
        newSettings.cooldownMinutes = Int(cooldownMinutes)
        newSettings.softModeEnabled = softModeEnabled
        newSettings.overridesPerDay = overridesPerDay
        stateManager.updateSettings(newSettings)
    }
    
    private func resetApp() {
        stateManager.stopMonitoring()
        PersistenceManager.shared.clearAll()
        
        // Reset local state
        var newSettings = UserSettings.default
        newSettings.hasCompletedOnboarding = false
        stateManager.updateSettings(newSettings)
    }
}

#Preview {
    SettingsView()
        .environmentObject(StateManager.shared)
}
