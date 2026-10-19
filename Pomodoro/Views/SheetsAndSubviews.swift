//
//  SheetsAndSubviews.swift
//  Pomodoro
//
//  Created by Onur Arda on 18.10.2026.
//

import SwiftUI

// MARK: - Tasks Sheet View
struct TasksSheetView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newTaskTitle: String = ""
    @State private var estimatedCount: Int = 2
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // New Task Composer Card
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(viewModel.currentPhase.primaryColor)

                        TextField("Yeni odak görevi ekle...", text: $newTaskTitle)
                            .focused($isInputFocused)
                            .submitLabel(.done)
                            .onSubmit(addNewTask)

                        if !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                            Button(action: addNewTask) {
                                Text("Ekle")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.currentPhase.primaryColor)
                                    )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }

                    HStack {
                        Text("Tahmini Pomodoro:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(1...6, id: \.self) { count in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                        estimatedCount = count
                                    }
                                } label: {
                                    Text("\(count)")
                                        .font(.caption.weight(.bold))
                                        .frame(width: 28, height: 28)
                                        .background(
                                            Circle()
                                                .fill(
                                                    estimatedCount == count
                                                        ? viewModel.currentPhase.primaryColor
                                                        : Color.primary.opacity(0.08)
                                                )
                                        )
                                        .foregroundStyle(estimatedCount == count ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                )
                .padding(.horizontal)

                // Tasks List
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView(
                        "Henüz Görev Yok",
                        systemImage: "checklist",
                        description: Text("Odaklanmak istediğin ilk görevi yukarıdan ekle.")
                    )
                } else {
                    List {
                        ForEach(viewModel.tasks) { task in
                            let isSelected = viewModel.selectedTaskID == task.id
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        viewModel.toggleTaskCompletion(task)
                                    }
                                } label: {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(
                                            task.isCompleted
                                                ? viewModel.currentPhase.primaryColor
                                                : .secondary
                                        )
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.body.weight(isSelected ? .semibold : .regular))
                                        .strikethrough(task.isCompleted, color: .secondary)
                                        .foregroundStyle(task.isCompleted ? .secondary : .primary)

                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .font(.caption2)
                                            .foregroundStyle(viewModel.currentPhase.primaryColor)
                                        Text("\(task.completedPomodoros) / \(task.estimatedPomodoros) oturum")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if isSelected {
                                    Text("Aktif")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(viewModel.currentPhase.primaryColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.currentPhase.primaryColor.opacity(0.15))
                                        )
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.selectTask(task)
                                }
                                dismiss()
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteTask(task)
                                    }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Odak Görevleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addNewTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            viewModel.addTask(title: trimmed, estimatedPomodoros: estimatedCount)
            newTaskTitle = ""
            isInputFocused = false
        }
    }
}

// MARK: - Statistics Sheet View
struct StatsSheetView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Daily Goal Progress Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            PomodoroLogoView(
                                phase: viewModel.currentPhase,
                                isRunning: viewModel.isRunning,
                                size: 38,
                                showExpression: true
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Günlük Odak Hedefi")
                                    .font(.headline)
                                Text("\(viewModel.todayFocusSessionsCount) / \(viewModel.settings.dailyGoalSessions) Pomodoro tamamlandı")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("%\(Int(viewModel.dailyGoalProgress * 100))")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(viewModel.currentPhase.primaryColor)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 10)

                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                viewModel.currentPhase.primaryColor,
                                                viewModel.currentPhase.secondaryColor
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(10, geo.size.width * viewModel.dailyGoalProgress), height: 10)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.dailyGoalProgress)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )

                    // Metric Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatMetricCard(
                            title: "Bugün Odak",
                            value: "\(viewModel.todayFocusMinutes) dk",
                            icon: "flame.fill",
                            tint: viewModel.currentPhase.primaryColor
                        )
                        StatMetricCard(
                            title: "Toplam Odak",
                            value: "\(viewModel.totalFocusMinutes) dk",
                            icon: "clock.fill",
                            tint: .orange
                        )
                        StatMetricCard(
                            title: "Bugünkü Oturum",
                            value: "\(viewModel.todayFocusSessionsCount)",
                            icon: "checkmark.seal.fill",
                            tint: .green
                        )
                        StatMetricCard(
                            title: "Toplam Kayıt",
                            value: "\(viewModel.sessions.count)",
                            icon: "chart.bar.fill",
                            tint: .blue
                        )
                    }

                    // Session History
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Son Oturumlar")
                                .font(.headline)
                            Spacer()
                            if !viewModel.sessions.isEmpty {
                                Button("Temizle", role: .destructive) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        viewModel.clearHistory()
                                    }
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }

                        if viewModel.sessions.isEmpty {
                            Text("Henüz tamamlanmış bir oturum bulunmuyor. İlk odak sayacını başlat!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 12)
                        } else {
                            ForEach(viewModel.sessions.prefix(15)) { session in
                                HStack(spacing: 12) {
                                    Image(systemName: session.phase.symbolName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(session.phase.primaryColor)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            Circle()
                                                .fill(session.phase.primaryColor.opacity(0.14))
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.taskTitle ?? session.phase.title)
                                            .font(.subheadline.weight(.medium))
                                        Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text("\(max(1, session.durationSeconds / 60)) dk")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                }
                .padding()
            }
            .navigationTitle("İstatistikler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

private struct StatMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

// MARK: - Settings Sheet View
struct SettingsSheetView: View {
    @Bindable var viewModel: PomodoroViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Süre Ayarları (Dakika)") {
                    Stepper(
                        "Odaklanma: \(viewModel.settings.focusMinutes) dk",
                        value: $viewModel.settings.focusMinutes,
                        in: 1...90
                    )
                    Stepper(
                        "Kısa Mola: \(viewModel.settings.shortBreakMinutes) dk",
                        value: $viewModel.settings.shortBreakMinutes,
                        in: 1...30
                    )
                    Stepper(
                        "Uzun Mola: \(viewModel.settings.longBreakMinutes) dk",
                        value: $viewModel.settings.longBreakMinutes,
                        in: 5...60
                    )
                }

                Section("Döngü ve Hedef") {
                    Stepper(
                        "Uzun Mola Aralığı: \(viewModel.settings.sessionsBeforeLongBreak) oturum",
                        value: $viewModel.settings.sessionsBeforeLongBreak,
                        in: 2...8
                    )
                    Stepper(
                        "Günlük Hedef: \(viewModel.settings.dailyGoalSessions) oturum",
                        value: $viewModel.settings.dailyGoalSessions,
                        in: 1...20
                    )
                }

                Section("Otomasyon") {
                    Toggle("Molaları Otomatik Başlat", isOn: $viewModel.settings.autoStartBreaks)
                    Toggle("Odaklanmayı Otomatik Başlat", isOn: $viewModel.settings.autoStartFocus)
                }

                Section("Bildirim ve Geri Bildirim") {
                    Toggle("Ses Efektleri", isOn: $viewModel.settings.soundEnabled)
                    Toggle("Titreşim (Haptic)", isOn: $viewModel.settings.hapticsEnabled)
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
