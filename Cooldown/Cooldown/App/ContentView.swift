//
//  ContentView.swift
//  Cooldown
//
//  Root content view that routes between onboarding and dashboard
//

import SwiftUI
import FamilyControls
import CooldownShared

struct ContentView: View {
    @EnvironmentObject var stateManager: StateManager
    @EnvironmentObject var authViewModel: AuthorizationViewModel
    
    var body: some View {
        Group {
            if !stateManager.settings.hasCompletedOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut, value: stateManager.settings.hasCompletedOnboarding)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(Color("Primary"))
    }
}

#Preview {
    ContentView()
        .environmentObject(StateManager.shared)
        .environmentObject(AuthorizationViewModel())
}
