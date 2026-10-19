//
//  ContentView.swift
//  Pomodoro
//
//  Created by Onur Arda on 18.10.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = PomodoroViewModel()
    @State private var showingTasksSheet = false
    @State private var showingStatsSheet = false
    @State private var showingSettingsSheet = false

    @Namespace private var phaseNamespace
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            // Smooth animated ambient background with floating bubbles
            ambientBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar (Cute Logo + Daily Goal Pill + Stats & Settings Actions)
                topHeaderBar
                    .padding(.horizontal, 22)
                    .padding(.top, 10)

                // Segmented Phase Selector with matchedGeometryEffect
                phaseSelectorBar
                    .padding(.horizontal, 22)
                    .padding(.top, 18)

                Spacer(minLength: 10)

                // Main Circular Timer Ring with Animated Bubble Logo
                TimerRingView(
                    phase: viewModel.currentPhase,
                    progress: viewModel.progress,
                    formattedTime: viewModel.formattedTime,
                    isRunning: viewModel.isRunning,
                    completedInCycle: viewModel.completedFocusInCycle,
                    cycleTarget: viewModel.settings.sessionsBeforeLongBreak
                )

                Spacer(minLength: 10)

                // Active Task Pill Card
                activeTaskButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)

                // Primary Playback Controls
                controlButtonsBar
                    .padding(.bottom, 26)
            }
        }
        .sheet(isPresented: $showingTasksSheet) {
            TasksSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingStatsSheet) {
            StatsSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheetView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.syncWithCurrentTime()
            }
        }
    }

    // MARK: - Ambient Bubble Background
    private var ambientBackground: some View {
        ZStack {
            Color(.systemBackground)

            LinearGradient(
                colors: [
                    viewModel.currentPhase.primaryColor.opacity(viewModel.isRunning ? 0.20 : 0.11),
                    viewModel.currentPhase.secondaryColor.opacity(viewModel.isRunning ? 0.11 : 0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.75), value: viewModel.currentPhase)
            .animation(.easeInOut(duration: 0.75), value: viewModel.isRunning)

            // Floating translucent pastel bubbles
            AmbientBubblesBackgroundView(
                phase: viewModel.currentPhase,
                isRunning: viewModel.isRunning
            )
            .animation(.easeInOut(duration: 0.75), value: viewModel.currentPhase)
        }
    }

    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            Button {
                showingStatsSheet = true
            } label: {
                HStack(spacing: 9) {
                    PomodoroLogoView(
                        phase: viewModel.currentPhase,
                        isRunning: viewModel.isRunning,
                        size: 22,
                        showExpression: false
                    )

                    Text("\(viewModel.todayFocusSessionsCount)/\(viewModel.settings.dailyGoalSessions) Odak")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.55),
                                            viewModel.currentPhase.primaryColor.opacity(0.18)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: viewModel.currentPhase.primaryColor.opacity(0.10), radius: 8, x: 0, y: 3)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 10) {
                Button {
                    showingStatsSheet = true
                } label: {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("İstatistikler")

                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ayarlar")
            }
        }
    }

    // MARK: - Segmented Phase Selector
    private var phaseSelectorBar: some View {
        HStack(spacing: 6) {
            ForEach(PomodoroPhase.allCases) { phase in
                let isSelected = viewModel.currentPhase == phase
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                        viewModel.selectPhase(phase)
                    }
                } label: {
                    Text(phase.title)
                        .font(.subheadline.weight(isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [phase.primaryColor, phase.secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Color.white.opacity(0.38), lineWidth: 1)
                                    )
                                    .matchedGeometryEffect(id: "ActivePhasePill", in: phaseNamespace)
                                    .shadow(color: phase.primaryColor.opacity(0.32), radius: 8, x: 0, y: 4)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.42), lineWidth: 1)
                )
        )
    }

    // MARK: - Active Task Card
    private var activeTaskButton: some View {
        Button {
            showingTasksSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    viewModel.currentPhase.primaryColor.opacity(0.18)
                                ],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 24
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        )

                    Image(systemName: "checklist")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.currentPhase.primaryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AKTİF GÖREV")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)

                    if let task = viewModel.selectedTask {
                        Text(task.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    } else {
                        Text("Bir odak görevi seç veya ekle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let task = viewModel.selectedTask {
                    Text("\(task.completedPomodoros)/\(task.estimatedPomodoros)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(viewModel.currentPhase.primaryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(viewModel.currentPhase.primaryColor.opacity(0.14))
                        )
                }

                Image(systemName: "chevron.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        viewModel.currentPhase.primaryColor.opacity(0.16)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: viewModel.currentPhase.primaryColor.opacity(0.08), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Primary Controls
    private var controlButtonsBar: some View {
        HStack(spacing: 24) {
            // Reset Button (Bubble Circle)
            Button {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) {
                    viewModel.resetTimer()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sıfırla")

            // Play / Pause Main Glossy Bubble Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.62)) {
                    viewModel.toggleTimer()
                }
            } label: {
                ZStack {
                    HStack(spacing: 10) {
                        Image(systemName: viewModel.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 23, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))

                        Text(viewModel.isRunning ? "Duraklat" : "Başlat")
                            .font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)

                    // Subtle top bubble shine on main button
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.32),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 132, height: 22)
                        .offset(y: -15)
                        .allowsHitTesting(false)
                }
                .frame(width: 162, height: 64)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    viewModel.currentPhase.primaryColor,
                                    viewModel.currentPhase.secondaryColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.42), lineWidth: 1.2)
                        )
                        .shadow(
                            color: viewModel.currentPhase.primaryColor.opacity(0.40),
                            radius: viewModel.isRunning ? 16 : 10,
                            x: 0,
                            y: 6
                        )
                )
                .scaleEffect(viewModel.isRunning ? 0.97 : 1.0)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isRunning ? "Duraklat" : "Başlat")

            // Skip Phase Button (Bubble Circle)
            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) {
                    viewModel.skipToNextPhase()
                }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sonraki Faz")
        }
    }
}

#Preview {
    ContentView()
}
