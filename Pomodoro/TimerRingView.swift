//
//  TimerRingView.swift
//  Pomodoro
//
//  Created by Onur Arda on 18.10.2026.
//

import SwiftUI

struct TimerRingView: View {
    let phase: PomodoroPhase
    let progress: Double
    let formattedTime: String
    let isRunning: Bool
    let completedInCycle: Int
    let cycleTarget: Int

    @State private var pulseScale: CGFloat = 1.0
    @State private var orbitRotation: Double = 0.0

    private let ringDiameter: CGFloat = 282

    var body: some View {
        ZStack {
            // Soft outer breathing bubble halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.primaryColor.opacity(isRunning ? 0.22 : 0.09),
                            phase.secondaryColor.opacity(isRunning ? 0.08 : 0.02),
                            phase.secondaryColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 195
                    )
                )
                .frame(width: 350, height: 350)
                .scaleEffect(isRunning ? pulseScale : 0.94)
                .animation(
                    isRunning
                        ? .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
                        : .spring(response: 0.5, dampingFraction: 0.8),
                    value: isRunning
                )
                .animation(
                    isRunning
                        ? .easeInOut(duration: 2.5).repeatForever(autoreverses: true)
                        : .default,
                    value: pulseScale
                )

            // Secondary subtle glass bubble ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isRunning ? 0.40 : 0.20),
                            phase.primaryColor.opacity(isRunning ? 0.18 : 0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 314, height: 314)
                .scaleEffect(isRunning ? (2.0 - pulseScale * 0.94) : 0.98)

            // Orbiting mini satellite bubbles around the timer ring
            orbitingMiniBubbles
                .frame(width: 316, height: 316)
                .rotationEffect(.degrees(orbitRotation))

            // Frosted inner glass disc for a clean, soft bubble card feel
            Circle()
                .fill(.ultraThinMaterial.opacity(0.55))
                .frame(width: ringDiameter - 24, height: ringDiameter - 24)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Background Track Ring
            Circle()
                .stroke(
                    phase.primaryColor.opacity(0.11),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .frame(width: ringDiameter, height: ringDiameter)

            // Animated Progress Ring
            Circle()
                .trim(from: 0, to: max(0.008, progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            phase.primaryColor,
                            phase.secondaryColor,
                            phase.primaryColor
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .frame(width: ringDiameter, height: ringDiameter)
                .rotationEffect(.degrees(-90))
                .shadow(color: phase.primaryColor.opacity(0.42), radius: isRunning ? 12 : 5, x: 0, y: 4)
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: progress)
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: phase)

            // Glossy Bubble Orb at Progress Tip
            progressTipBubble
                .frame(width: ringDiameter, height: ringDiameter)
                .animation(.spring(response: 0.55, dampingFraction: 0.82), value: progress)

            // Center Content with Cute Animated Logo
            VStack(spacing: 8) {
                // Cute Animated Pomodoro Bubble Logo (tappable for bounce!)
                PomodoroLogoView(
                    phase: phase,
                    isRunning: isRunning,
                    size: 52,
                    showExpression: true
                )
                .padding(.bottom, 2)

                // Phase Subtitle Pill
                HStack(spacing: 5) {
                    Image(systemName: phase.symbolName)
                        .font(.caption2.weight(.semibold))
                        .contentTransition(.symbolEffect(.replace))
                    Text(phase.subtitle)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(phase.primaryColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(phase.primaryColor.opacity(0.13))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.8)
                        )
                )
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: phase)

                // Countdown Digits with smooth numeric transition
                Text(formattedTime)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: formattedTime)

                // Bubble Cycle Dot Indicators
                HStack(spacing: 8) {
                    ForEach(0..<max(1, cycleTarget), id: \.self) { index in
                        let isFilled = index < completedInCycle
                        ZStack {
                            Capsule()
                                .fill(
                                    isFilled
                                        ? LinearGradient(
                                            colors: [phase.primaryColor, phase.secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(
                                            colors: [
                                                phase.primaryColor.opacity(0.16),
                                                phase.primaryColor.opacity(0.10)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                )
                                .frame(width: isFilled ? 20 : 10, height: 10)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.white.opacity(isFilled ? 0.5 : 0.2), lineWidth: 0.8)
                                )
                                .shadow(
                                    color: isFilled ? phase.primaryColor.opacity(0.35) : .clear,
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )

                            // Tiny bubble shine on each indicator dot
                            Circle()
                                .fill(Color.white.opacity(isFilled ? 0.65 : 0.35))
                                .frame(width: 3, height: 3)
                                .offset(x: isFilled ? -4 : -1.5, y: -1.8)
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: completedInCycle)
                        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: phase)
                    }
                }
                .padding(.top, 2)
            }
        }
        .onAppear {
            pulseScale = 1.07
            withAnimation(.linear(duration: 28).repeatForever(autoreverses: false)) {
                orbitRotation = 360
            }
        }
        .onChange(of: isRunning) { _, newValue in
            pulseScale = newValue ? 1.07 : 1.0
        }
    }

    // MARK: - Progress Tip Glossy Bubble
    private var progressTipBubble: some View {
        let clampedProgress = max(0.008, min(1.0, progress))
        let angleRadians = (clampedProgress * 360.0 - 90.0) * (.pi / 180.0)
        let radius = ringDiameter / 2.0
        let xOffset = cos(angleRadians) * radius
        let yOffset = sin(angleRadians) * radius

        return ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 11, height: 11)
                .shadow(color: phase.primaryColor.opacity(0.6), radius: 4, x: 0, y: 1)

            Circle()
                .fill(phase.primaryColor)
                .frame(width: 5, height: 5)
        }
        .offset(x: xOffset, y: yOffset)
    }

    // MARK: - Orbiting Mini Bubbles
    private var orbitingMiniBubbles: some View {
        ZStack {
            miniOrbitBubble(diameter: 10, angleDegrees: 25, distance: 156, opacity: isRunning ? 0.65 : 0.35)
            miniOrbitBubble(diameter: 7, angleDegrees: 140, distance: 158, opacity: isRunning ? 0.50 : 0.25)
            miniOrbitBubble(diameter: 12, angleDegrees: 215, distance: 155, opacity: isRunning ? 0.60 : 0.30)
            miniOrbitBubble(diameter: 8, angleDegrees: 310, distance: 160, opacity: isRunning ? 0.55 : 0.28)
        }
    }

    private func miniOrbitBubble(diameter: CGFloat, angleDegrees: Double, distance: CGFloat, opacity: Double) -> some View {
        let rad = angleDegrees * (.pi / 180.0)
        return Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        phase.primaryColor.opacity(0.45)
                    ],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: diameter
                )
            )
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.8)
            )
            .opacity(opacity)
            .offset(
                x: cos(rad) * distance,
                y: sin(rad) * distance
            )
    }
}
