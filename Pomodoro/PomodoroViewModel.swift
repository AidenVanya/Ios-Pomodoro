//
//  PomodoroViewModel.swift
//  Pomodoro
//
//  Created by Onur Arda on 18.10.2026.
//

import SwiftUI
import Foundation
import UserNotifications
import AudioToolbox
#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
final class PomodoroViewModel {
    // MARK: - Timer State
    private(set) var currentPhase: PomodoroPhase = .focus
    private(set) var remainingSeconds: Int = 25 * 60
    private(set) var isRunning: Bool = false
    private(set) var completedFocusInCycle: Int = 0

    // MARK: - Data & Settings
    var settings: PomodoroSettings {
        didSet {
            saveSettings()
            if !isRunning {
                remainingSeconds = settings.durationSeconds(for: currentPhase)
            }
        }
    }
    var tasks: [PomodoroTask] = [] {
        didSet { saveTasks() }
    }
    var selectedTaskID: UUID? {
        didSet { saveSelectedTaskID() }
    }
    private(set) var sessions: [PomodoroSession] = [] {
        didSet { saveSessions() }
    }

    // MARK: - Private Properties
    private var timerTask: Task<Void, Never>?
    private var targetEndDate: Date?
    private let userDefaults: UserDefaults

    private enum StorageKey {
        static let settings = "pomodoro.settings.v1"
        static let tasks = "pomodoro.tasks.v1"
        static let sessions = "pomodoro.sessions.v1"
        static let selectedTaskID = "pomodoro.selectedTaskID.v1"
    }

    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: StorageKey.settings),
           let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = PomodoroSettings()
        }

        if let data = userDefaults.data(forKey: StorageKey.tasks),
           let decoded = try? JSONDecoder().decode([PomodoroTask].self, from: data) {
            self.tasks = decoded
        } else {
            self.tasks = [
                PomodoroTask(title: "UI Tasarımını Tamamla", estimatedPomodoros: 3, completedPomodoros: 1),
                PomodoroTask(title: "SwiftUI Animasyonlarını Test Et", estimatedPomodoros: 2, completedPomodoros: 0),
                PomodoroTask(title: "Kod İncelemesi ve Dokümantasyon", estimatedPomodoros: 2, completedPomodoros: 0)
            ]
        }

        if let data = userDefaults.data(forKey: StorageKey.sessions),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            self.sessions = decoded
        } else {
            self.sessions = []
        }

        if let idString = userDefaults.string(forKey: StorageKey.selectedTaskID),
           let uuid = UUID(uuidString: idString) {
            self.selectedTaskID = uuid
        } else {
            self.selectedTaskID = self.tasks.first(where: { !$0.isCompleted })?.id
        }

        self.remainingSeconds = self.settings.durationSeconds(for: .focus)
    }

    // MARK: - Computed Properties
    var totalSecondsForCurrentPhase: Int {
        settings.durationSeconds(for: currentPhase)
    }

    var progress: Double {
        let total = Double(totalSecondsForCurrentPhase)
        guard total > 0 else { return 0 }
        let elapsed = total - Double(remainingSeconds)
        return min(1.0, max(0.0, elapsed / total))
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var selectedTask: PomodoroTask? {
        guard let selectedTaskID else { return nil }
        return tasks.first(where: { $0.id == selectedTaskID })
    }

    var todayFocusSessionsCount: Int {
        let calendar = Calendar.current
        return sessions.filter {
            $0.phase == .focus && calendar.isDateInToday($0.completedAt)
        }.count
    }

    var todayFocusMinutes: Int {
        let calendar = Calendar.current
        let totalSeconds = sessions
            .filter { $0.phase == .focus && calendar.isDateInToday($0.completedAt) }
            .reduce(0) { $0 + $1.durationSeconds }
        return max(0, totalSeconds / 60)
    }

    var totalFocusMinutes: Int {
        let totalSeconds = sessions
            .filter { $0.phase == .focus }
            .reduce(0) { $0 + $1.durationSeconds }
        return max(0, totalSeconds / 60)
    }

    var dailyGoalProgress: Double {
        guard settings.dailyGoalSessions > 0 else { return 0 }
        return min(1.0, Double(todayFocusSessionsCount) / Double(settings.dailyGoalSessions))
    }

    // MARK: - Timer Controls
    func toggleTimer() {
        if isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    func startTimer() {
        guard !isRunning else { return }
        requestNotificationPermissionIfNeeded()

        isRunning = true
        let now = Date()
        targetEndDate = now.addingTimeInterval(TimeInterval(remainingSeconds))
        schedulePhaseEndNotification(in: remainingSeconds)
        triggerImpactHaptic(style: .medium)

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled, let self else { break }
                self.tick()
            }
        }
    }

    func pauseTimer() {
        guard isRunning else { return }
        if let targetEndDate {
            let diff = Int(ceil(targetEndDate.timeIntervalSinceNow))
            remainingSeconds = max(0, diff)
        }
        isRunning = false
        targetEndDate = nil
        timerTask?.cancel()
        timerTask = nil
        cancelScheduledNotifications()
        triggerImpactHaptic(style: .light)
    }

    func resetTimer() {
        pauseTimer()
        remainingSeconds = settings.durationSeconds(for: currentPhase)
        triggerImpactHaptic(style: .rigid)
    }

    func selectPhase(_ phase: PomodoroPhase) {
        pauseTimer()
        currentPhase = phase
        remainingSeconds = settings.durationSeconds(for: phase)
        triggerSelectionHaptic()
    }

    func skipToNextPhase() {
        pauseTimer()
        advancePhase(recordSession: false)
        triggerImpactHaptic(style: .soft)
    }

    /// Synchronizes timer state when returning from background or on each tick
    func syncWithCurrentTime() {
        guard isRunning else { return }
        tick()
    }

    /// Advances the timer and completes current phase immediately (also handy for unit testing)
    func completeCurrentPhaseNow() {
        pauseTimer()
        handlePhaseCompletion()
    }

    // MARK: - Internal Tick & Phase Transition
    private func tick() {
        guard isRunning, let targetEndDate else { return }
        let remaining = Int(ceil(targetEndDate.timeIntervalSinceNow))
        if remaining <= 0 {
            remainingSeconds = 0
            isRunning = false
            self.targetEndDate = nil
            timerTask?.cancel()
            timerTask = nil
            handlePhaseCompletion()
        } else if remaining != remainingSeconds {
            remainingSeconds = remaining
        }
    }

    private func handlePhaseCompletion() {
        playCompletionFeedback()
        advancePhase(recordSession: true)
    }

    private func advancePhase(recordSession: Bool) {
        let finishedPhase = currentPhase
        let finishedDuration = settings.durationSeconds(for: finishedPhase)

        if recordSession {
            let record = PomodoroSession(
                phase: finishedPhase,
                durationSeconds: finishedDuration,
                completedAt: Date(),
                taskTitle: selectedTask?.title
            )
            sessions.insert(record, at: 0)

            if finishedPhase == .focus, let selectedTaskID,
               let index = tasks.firstIndex(where: { $0.id == selectedTaskID }) {
                tasks[index].completedPomodoros += 1
                if tasks[index].completedPomodoros >= tasks[index].estimatedPomodoros {
                    tasks[index].isCompleted = true
                }
            }
        }

        // Determine next phase
        switch finishedPhase {
        case .focus:
            completedFocusInCycle += 1
            if completedFocusInCycle >= settings.sessionsBeforeLongBreak {
                currentPhase = .longBreak
                completedFocusInCycle = 0
            } else {
                currentPhase = .shortBreak
            }
        case .shortBreak, .longBreak:
            currentPhase = .focus
        }

        remainingSeconds = settings.durationSeconds(for: currentPhase)

        // Auto-start if enabled
        let shouldAutoStart: Bool
        switch currentPhase {
        case .focus:
            shouldAutoStart = recordSession && settings.autoStartFocus
        case .shortBreak, .longBreak:
            shouldAutoStart = recordSession && settings.autoStartBreaks
        }

        if shouldAutoStart {
            startTimer()
        }
    }

    // MARK: - Task Management
    func addTask(title: String, estimatedPomodoros: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newTask = PomodoroTask(
            title: trimmed,
            estimatedPomodoros: max(1, estimatedPomodoros)
        )
        tasks.insert(newTask, at: 0)
        if selectedTaskID == nil {
            selectedTaskID = newTask.id
        }
        triggerImpactHaptic(style: .light)
    }

    func toggleTaskCompletion(_ task: PomodoroTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted && selectedTaskID == task.id {
            selectedTaskID = tasks.first(where: { !$0.isCompleted })?.id
        } else if !tasks[index].isCompleted && selectedTaskID == nil {
            selectedTaskID = task.id
        }
        triggerSelectionHaptic()
    }

    func deleteTask(_ task: PomodoroTask) {
        tasks.removeAll { $0.id == task.id }
        if selectedTaskID == task.id {
            selectedTaskID = tasks.first(where: { !$0.isCompleted })?.id
        }
    }

    func selectTask(_ task: PomodoroTask) {
        selectedTaskID = task.id
        triggerSelectionHaptic()
    }

    func clearHistory() {
        sessions.removeAll()
        completedFocusInCycle = 0
    }

    // MARK: - Persistence
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: StorageKey.settings)
        }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            userDefaults.set(data, forKey: StorageKey.tasks)
        }
    }

    private func saveSessions() {
        if let data = try? JSONEncoder().encode(sessions) {
            userDefaults.set(data, forKey: StorageKey.sessions)
        }
    }

    private func saveSelectedTaskID() {
        userDefaults.set(selectedTaskID?.uuidString, forKey: StorageKey.selectedTaskID)
    }

    // MARK: - Haptics, Sound & Local Notifications
    private func triggerImpactHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard settings.hapticsEnabled else { return }
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }

    private func triggerSelectionHaptic() {
        guard settings.hapticsEnabled else { return }
        #if canImport(UIKit)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }

    private func playCompletionFeedback() {
        if settings.hapticsEnabled {
            #if canImport(UIKit)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
        if settings.soundEnabled {
            AudioServicesPlaySystemSound(1005)
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func schedulePhaseEndNotification(in seconds: Int) {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        switch currentPhase {
        case .focus:
            content.title = "Odak Oturumu Tamamlandı! 🎉"
            content.body = "Harika iş çıkardın. Şimdi kısa bir mola verme zamanı."
        case .shortBreak, .longBreak:
            content.title = "Mola Sona Erdi ⚡️"
            content.body = "Yeni bir odak oturumu için hazırsın!"
        }
        if settings.soundEnabled {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoro.phase.end", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
