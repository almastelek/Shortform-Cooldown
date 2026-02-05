//
//  CooldownApp.swift
//  Cooldown
//
//  Main entry point for the Cooldown app
//

import SwiftUI
import FamilyControls

@main
struct CooldownApp: App {
    @StateObject private var stateManager = StateManager.shared
    @StateObject private var authorizationCenter = AuthorizationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stateManager)
                .environmentObject(authorizationCenter)
                .onAppear {
                    requestNotificationPermission()
                }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}

/// ViewModel for FamilyControls authorization status
class AuthorizationViewModel: ObservableObject {
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    init() {
        checkAuthorization()
    }
    
    func checkAuthorization() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
    
    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        await MainActor.run {
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        }
    }
}
