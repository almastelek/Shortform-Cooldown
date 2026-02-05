//
//  OnboardingView.swift
//  Cooldown
//
//  Multi-step onboarding flow with playful design
//

import SwiftUI
import FamilyControls
import CooldownShared

struct OnboardingView: View {
    @EnvironmentObject var stateManager: StateManager
    @EnvironmentObject var authViewModel: AuthorizationViewModel
    
    @State private var currentStep = 0
    @State private var isAuthorizing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let totalSteps = 4
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            progressIndicator
            
            // Content
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                authorizationStep.tag(1)
                appSelectionStep.tag(2)
                confirmationStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
        }
        .background(
            LinearGradient(
                colors: [Color("Background"), Color("BackgroundSecondary")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .alert("Oops!", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color("Primary") : Color("Primary").opacity(0.3))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }
    
    // MARK: - Step 1: Welcome
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Mascot
            Image("ChillMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            
            VStack(spacing: 12) {
                Text("Hey there! I'm Chill 🐧")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                Text("I'm here to help you take healthy breaks from scrolling. No judgment, just gentle nudges!")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Info cards
            VStack(spacing: 12) {
                InfoCard(
                    icon: "eye.slash.fill",
                    title: "Privacy First",
                    description: "I never see what you're looking at"
                )
                
                InfoCard(
                    icon: "timer",
                    title: "Time Tracking",
                    description: "I just count how long you're in certain apps"
                )
                
                InfoCard(
                    icon: "hand.raised.fill",
                    title: "Your Choice",
                    description: "You pick which apps and when to take breaks"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            primaryButton(title: "Let's get started!") {
                withAnimation { currentStep = 1 }
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Step 2: Authorization
    
    private var authorizationStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("Primary"), Color("Secondary")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("Screen Time Access")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                Text("I need access to Screen Time to track your app usage. This stays on your device - I don't send any data anywhere!")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Authorization status
            authorizationStatusView
            
            Spacer()
            
            if authViewModel.authorizationStatus == .approved {
                primaryButton(title: "Continue") {
                    withAnimation { currentStep = 2 }
                }
            } else {
                primaryButton(title: isAuthorizing ? "Requesting..." : "Grant Access") {
                    requestAuthorization()
                }
                .disabled(isAuthorizing)
            }
            
            Button("Skip for now") {
                withAnimation { currentStep = 2 }
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(Color("TextSecondary"))
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }
    
    private var authorizationStatusView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(authViewModel.authorizationStatus == .approved ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            Text(authViewModel.authorizationStatus == .approved ? "Access granted" : "Access needed")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color("TextPrimary"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
    
    // MARK: - Step 3: App Selection
    
    private var appSelectionStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Choose Your Apps")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                Text("Which apps tend to pull you into endless scrolling? Select them below.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Family Activity Picker
            FamilyActivityPicker(selection: Binding(
                get: { stateManager.settings.familyActivitySelection },
                set: { selection in
                    var newSettings = stateManager.settings
                    newSettings.familyActivitySelection = selection
                    stateManager.updateSettings(newSettings)
                }
            ))
            .frame(height: 300)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal, 24)
            
            // Selection count
            if stateManager.settings.hasSelectedApps {
                Text("\(stateManager.settings.familyActivitySelection.applicationTokens.count) apps selected")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("Primary"))
            }
            
            Spacer()
            
            primaryButton(title: "Continue") {
                withAnimation { currentStep = 3 }
            }
            .disabled(!stateManager.settings.hasSelectedApps)
            .opacity(stateManager.settings.hasSelectedApps ? 1 : 0.5)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Step 4: Confirmation
    
    private var confirmationStep: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Mascot celebrating
            Image("ChillMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
            
            VStack(spacing: 12) {
                Text("You're all set! 🎉")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                Text("Here's how it works:")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
            }
            
            Spacer()
            
            // How it works
            VStack(alignment: .leading, spacing: 16) {
                HowItWorksRow(
                    number: "1",
                    title: "Use your apps normally",
                    description: "I'll be quietly keeping track in the background"
                )
                
                HowItWorksRow(
                    number: "2",
                    title: "After \(stateManager.settings.thresholdMinutes) mins",
                    description: "I'll gently suggest it's time for a break"
                )
                
                HowItWorksRow(
                    number: "3",
                    title: "Take a \(stateManager.settings.cooldownMinutes)-min breather",
                    description: "Then you're free to scroll again!"
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("CardBackground"))
            )
            .padding(.horizontal, 24)
            
            Spacer()
            
            primaryButton(title: "Start Monitoring") {
                completeOnboarding()
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helpers
    
    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color("Primary"), Color("Primary").opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color("Primary").opacity(0.4), radius: 10, y: 5)
        }
        .padding(.horizontal, 24)
    }
    
    private func requestAuthorization() {
        isAuthorizing = true
        Task {
            do {
                try await authViewModel.requestAuthorization()
            } catch {
                await MainActor.run {
                    errorMessage = "Could not get Screen Time access. Please try again or enable it in Settings."
                    showError = true
                }
            }
            await MainActor.run {
                isAuthorizing = false
            }
        }
    }
    
    private func completeOnboarding() {
        var newSettings = stateManager.settings
        newSettings.hasCompletedOnboarding = true
        stateManager.updateSettings(newSettings)
        
        // Start monitoring
        do {
            try stateManager.startMonitoring()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Supporting Views

struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color("Primary"))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color("Primary").opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("CardBackground"))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
    }
}

struct HowItWorksRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("Primary"), Color("Secondary")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                
                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color("TextSecondary"))
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(StateManager.shared)
        .environmentObject(AuthorizationViewModel())
}
