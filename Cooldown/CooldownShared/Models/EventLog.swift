//
//  EventLog.swift
//  CooldownShared
//
//  Event logging for the Cooldown app
//

import Foundation

/// Types of events that can be logged
public enum EventType: String, Codable {
    case monitoringStarted
    case monitoringStopped
    case thresholdReached
    case cooldownStarted
    case cooldownEnded
    case overrideUsed
    case overrideEnded
    case appOpened
    case shieldDisplayed
    case settingsChanged
    case error
}

/// A single logged event
public struct EventLogEntry: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let eventType: EventType
    public let details: String?
    public let duration: TimeInterval?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: EventType,
        details: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.details = details
        self.duration = duration
    }
}

/// Manages the event log
public class EventLog: Codable {
    
    /// Maximum number of entries to keep
    private static let maxEntries = 500
    
    /// The logged entries
    private(set) var entries: [EventLogEntry]
    
    public init(entries: [EventLogEntry] = []) {
        self.entries = entries
    }
    
    /// Add a new entry
    public func log(_ eventType: EventType, details: String? = nil, duration: TimeInterval? = nil) {
        let entry = EventLogEntry(
            eventType: eventType,
            details: details,
            duration: duration
        )
        entries.append(entry)
        
        // Trim if needed
        if entries.count > Self.maxEntries {
            entries = Array(entries.suffix(Self.maxEntries))
        }
    }
    
    /// Get entries for today
    public var todayEntries: [EventLogEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.timestamp) }
    }
    
    /// Get entries for this week
    public var thisWeekEntries: [EventLogEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.timestamp >= weekAgo }
    }
    
    /// Count of cooldowns triggered today
    public var cooldownsToday: Int {
        todayEntries.filter { $0.eventType == .cooldownStarted }.count
    }
    
    /// Count of overrides used today
    public var overridesToday: Int {
        todayEntries.filter { $0.eventType == .overrideUsed }.count
    }
    
    /// Clear all entries
    public func clear() {
        entries = []
    }
}
