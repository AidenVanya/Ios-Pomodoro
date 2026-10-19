//
//  PomodoroModels.swift
//  Pomodoro
//
//  Created by Onur Arda on 18.10.2026.
//

import SwiftUI
import Foundation

// MARK: - Pomodoro Phase
enum PomodoroPhase: String, CaseIterable, Codable, Identifiable {
    case focus = "focus"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus:
            return "Odaklan"
        case .shortBreak:
            return "Kısa Mola"
        case .longBreak:
            return "Uzun Mola"
        }
    }

    var subtitle: String {
        switch self {
        case .focus:
            return "Derin çalışma zamanı"
        case .shortBreak:
            return "Nefes al ve dinlen"
        case .longBreak:
            return "Enerjini yenile"
        }
    }

    var symbolName: String {
        switch self {
        case .focus:
            return "brain.head.profile"
        case .shortBreak:
            return "cup.and.saucer.fill"
        case .longBreak:
            return "leaf.fill"
        }
    }

    var primaryColor: Color {
        switch self {
        case .focus:
            return Color(red: 0.95, green: 0.36, blue: 0.33) // Warm Coral Red
        case .shortBreak:
            return Color(red: 0.20, green: 0.78, blue: 0.58) // Calm Mint Teal
        case .longBreak:
            return Color(red: 0.35, green: 0.52, blue: 0.96) // Serene Indigo Blue
        }
    }

    var secondaryColor: Color {
        switch self {
        case .focus:
            return Color(red: 0.98, green: 0.60, blue: 0.32)
        case .shortBreak:
            return Color(red: 0.16, green: 0.62, blue: 0.76)
        case .longBreak:
            return Color(red: 0.56, green: 0.38, blue: 0.96)
        }
    }
}

// MARK: - Pomodoro Task
struct PomodoroTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var estimatedPomodoros: Int = 4
    var completedPomodoros: Int = 0
    var isCompleted: Bool = false
    var createdAt: Date = Date()

    var progress: Double {
        guard estimatedPomodoros > 0 else { return 0 }
        return min(1.0, Double(completedPomodoros) / Double(estimatedPomodoros))
    }
}

// MARK: - Completed Session Record
struct PomodoroSession: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var phase: PomodoroPhase
    var durationSeconds: Int
    var completedAt: Date = Date()
    var taskTitle: String?
}

// MARK: - User Settings
struct PomodoroSettings: Codable, Equatable {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var sessionsBeforeLongBreak: Int = 4
    var dailyGoalSessions: Int = 8
    var autoStartBreaks: Bool = false
    var autoStartFocus: Bool = false
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true

    func durationSeconds(for phase: PomodoroPhase) -> Int {
        switch phase {
        case .focus:
            return max(1, focusMinutes) * 60
        case .shortBreak:
            return max(1, shortBreakMinutes) * 60
        case .longBreak:
            return max(1, longBreakMinutes) * 60
        }
    }
}
