//
//  DashboardView.swift
//  Cooldown
//
//  Main dashboard showing current status and controls
//

import SwiftUI
import CooldownShared

struct DashboardView: View {
    @EnvironmentObject var stateManager: StateManager
    
    @State private var showingAppPicker = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status card
                    statusCard
                    
                    // Quick stats
                    statsRow
                    
                    // Control buttons
                    controlsSection
                    
                    // Override info
                    if stateManager.settings.softModeEnabled {
                        overrideInfoCard
                    }
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
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(spacing: 20) {
            // Mascot with state-based expression
            mascotView
            
            // Status text
            VStack(spacing: 8) {
                Text(stateManager.runtimeState.currentState.displayMessage)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                statusSubtext
            }
            
            // Timer if in cooldown
            if stateManager.runtimeState.isInCooldown {
                cooldownTimer
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        )
    }
    
    private var mascotView: some View {
        ZStack {
            // Glow effect based on state
            Circle()
                .fill(stateColor.opacity(0.2))
                .frame(width: 140, height: 140)
                .blur(radius: 20)
            
            Image("ChillMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
        }
    }
    
    private var stateColor: Color {
        switch stateManager.runtimeState.currentState {
        case .monitoring:
            return Color("Primary")
        case .cooldownActive:
            return Color("Secondary")
        case .overrideActive:
            return Color("Accent")
        case .paused:
            return Color.gray
        default:
            return Color("Primary")
        }
    }
    
    @ViewBuilder
    private var statusSubtext: some View {
        switch stateManager.runtimeState.currentState {
        case .monitoring:
            Text("I'll let you know when it's time for a break")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        case .cooldownActive:
            Text("Let's take a quick breather together!")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        case .overrideActive:
            Text("Override active - enjoy your extra time!")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color("Accent"))
                .multilineTextAlignment(.center)
        case .paused:
            Text("Monitoring is paused")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color("TextSecondary"))
        default:
            EmptyView()
        }
    }
    
    private var cooldownTimer: some View {
        VStack(spacing: 8) {
            if let timeRemaining = stateManager.runtimeState.cooldownTimeRemainingFormatted {
                Text(timeRemaining)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("Primary"), Color("Secondary")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .monospacedDigit()
                
                Text("until you can scroll again")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Cooldowns Today",
                value: "\(PersistenceManager.shared.loadEventLog().cooldownsToday)",
                icon: "timer",
                color: Color("Primary")
            )
            
            StatCard(
                title: "Overrides Left",
                value: "\(stateManager.overridesRemaining)",
                icon: "hand.raised.fill",
                color: Color("Accent")
            )
        }
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Pause/Resume button
            if stateManager.runtimeState.currentState == .monitoring {
                controlButton(
                    title: "Pause Monitoring",
                    icon: "pause.fill",
                    style: .secondary
                ) {
                    stateManager.pauseMonitoring()
                }
            } else if stateManager.runtimeState.currentState == .paused {
                controlButton(
                    title: "Resume Monitoring",
                    icon: "play.fill",
                    style: .primary
                ) {
                    try? stateManager.resumeMonitoring()
                }
            }
            
            // Edit apps button
            controlButton(
                title: "Edit Monitored Apps",
                icon: "square.grid.2x2.fill",
                style: .secondary
            ) {
                showingAppPicker = true
            }
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet()
        }
    }
    
    private func controlButton(
        title: String,
        icon: String,
        style: ControlButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundColor(style == .primary ? .white : Color("TextPrimary"))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(style == .primary ?
                          AnyShapeStyle(LinearGradient(colors: [Color("Primary"), Color("Primary").opacity(0.8)], startPoint: .leading, endPoint: .trailing)) :
                          AnyShapeStyle(Color("CardBackground")))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style == .secondary ? Color("Border") : Color.clear, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Override Info
    
    private var overrideInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color("Primary"))
                
                Text("About Overrides")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
            }
            
            Text("When a cooldown starts, you can use an override to get \(stateManager.settings.overrideMinutes) more minutes. You have \(stateManager.settings.overridesPerDay) override(s) per day.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color("TextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("Primary").opacity(0.1))
        )
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("TextPrimary"))
            
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color("TextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
}

enum ControlButtonStyle {
    case primary, secondary
}

struct AppPickerSheet: View {
    @EnvironmentObject var stateManager: StateManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: Binding(
                get: { stateManager.settings.familyActivitySelection },
                set: { selection in
                    var newSettings = stateManager.settings
                    newSettings.familyActivitySelection = selection
                    stateManager.updateSettings(newSettings)
                }
            ))
            .navigationTitle("Select Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(StateManager.shared)
}
