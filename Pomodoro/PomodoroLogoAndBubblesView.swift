//
//  PomodoroLogoAndBubblesView.swift
//  Pomodoro
//
//  Created by Onur Arda on 19.10.2026.
//

import SwiftUI

// MARK: - Cute & Minimal Animated Pomodoro Bubble Logo
struct PomodoroLogoView: View {
    let phase: PomodoroPhase
    let isRunning: Bool
    var size: CGFloat = 56
    var showExpression: Bool = true

    @State private var isFloating: Bool = false
    @State private var leafSway: Bool = false
    @State private var isBlinking: Bool = false
    @State private var tapBounce: Bool = false
    @State private var popBubbles: [MiniPopBubble] = []

    var body: some View {
        ZStack {
            // Pop bubble particles on tap or state change
            ForEach(popBubbles) { bubble in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                phase.primaryColor.opacity(0.45)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: bubble.diameter
                        )
                    )
                    .frame(width: bubble.diameter, height: bubble.diameter)
                    .offset(x: bubble.offsetX, y: bubble.offsetY)
                    .opacity(bubble.opacity)
                    .scaleEffect(bubble.scale)
            }

            // Soft outer bubble aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            phase.primaryColor.opacity(isRunning ? 0.30 : 0.16),
                            phase.secondaryColor.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size * 1.38, height: size * 1.38)
                .scaleEffect(isFloating ? 1.08 : 0.94)

            // Main Tomato-Bubble Character Group
            ZStack {
                // Plump Berry-Bubble Body
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                phase.primaryColor,
                                phase.secondaryColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size * 0.92)
                    .overlay(
                        // Inner translucent bubble rim light
                        Ellipse()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.65),
                                        Color.white.opacity(0.12),
                                        phase.secondaryColor.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: max(1.5, size * 0.04)
                            )
                    )
                    .shadow(
                        color: phase.primaryColor.opacity(isRunning ? 0.42 : 0.26),
                        radius: size * 0.22,
                        x: 0,
                        y: size * 0.10
                    )

                // Glossy Bubble Specular Highlight (Top-Left)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.75),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.22, height: size * 0.11)
                    .rotationEffect(.degrees(-32))
                    .offset(x: -size * 0.22, y: -size * 0.20)

                // Tiny secondary bubble shine dot
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: size * 0.07, height: size * 0.07)
                    .offset(x: -size * 0.31, y: -size * 0.06)

                // Cute Minimalist Face Expression
                if showExpression {
                    logoFaceView
                        .offset(y: size * 0.05)
                }

                // Cute Leafy Crown at the Top
                leafCrownView
                    .offset(y: -size * 0.43)
            }
            .scaleEffect(
                x: tapBounce ? 1.14 : (isFloating && isRunning ? 1.03 : 1.0),
                y: tapBounce ? 0.88 : (isFloating && isRunning ? 0.97 : 1.0)
            )
            .offset(y: isFloating ? -size * 0.04 : size * 0.04)
        }
        .contentShape(Circle())
        .onTapGesture {
            triggerCuteBounce()
        }
        .onAppear {
            startAmbientAnimations()
        }
        .onChange(of: phase) { _, _ in
            triggerCuteBounce()
        }
        .onChange(of: isRunning) { _, _ in
            triggerCuteBounce()
        }
    }

    // MARK: - Cute Leafy Crown
    private var leafCrownView: some View {
        ZStack {
            // Left Leaf
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.84, blue: 0.56),
                            Color(red: 0.14, green: 0.66, blue: 0.44)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.28, height: size * 0.13)
                .rotationEffect(.degrees(leafSway ? -22 : -32), anchor: .trailing)
                .offset(x: -size * 0.10, y: size * 0.02)

            // Right Leaf
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.26, green: 0.84, blue: 0.56),
                            Color(red: 0.14, green: 0.66, blue: 0.44)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.28, height: size * 0.13)
                .rotationEffect(.degrees(leafSway ? 32 : 22), anchor: .leading)
                .offset(x: size * 0.10, y: size * 0.02)

            // Center Little Stem
            Capsule()
                .fill(Color(red: 0.18, green: 0.72, blue: 0.48))
                .frame(width: size * 0.08, height: size * 0.16)
                .rotationEffect(.degrees(leafSway ? 6 : -6), anchor: .bottom)
                .offset(y: -size * 0.04)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
    }

    // MARK: - Cute Minimal Face Expression
    private var logoFaceView: some View {
        VStack(spacing: size * 0.05) {
            // Eyes + Rosy Cheeks
            HStack(spacing: size * 0.20) {
                eyeShape
                eyeShape
            }
            .overlay {
                // Soft pastel blush cheeks
                HStack(spacing: size * 0.34) {
                    Ellipse()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: size * 0.12, height: size * 0.06)
                    Ellipse()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: size * 0.12, height: size * 0.06)
                }
                .offset(y: size * 0.06)
            }

            // Cute Mouth
            mouthShape
        }
    }

    @ViewBuilder
    private var eyeShape: some View {
        switch phase {
        case .focus:
            // Cute round eyes that blink softly
            Capsule()
                .fill(Color.white.opacity(0.95))
                .frame(
                    width: size * 0.085,
                    height: isBlinking ? max(1.5, size * 0.02) : size * 0.10
                )
                .overlay(alignment: .topLeading) {
                    if !isBlinking {
                        Circle()
                            .fill(phase.primaryColor.opacity(0.5))
                            .frame(width: size * 0.03, height: size * 0.03)
                            .offset(x: size * 0.015, y: size * 0.015)
                    }
                }
        case .shortBreak:
            // Happy relaxed arc eyes (^ ^)
            CuteArcShape(isUpward: true)
                .stroke(
                    Color.white.opacity(0.95),
                    style: StrokeStyle(lineWidth: max(1.8, size * 0.042), lineCap: .round)
                )
                .frame(width: size * 0.11, height: size * 0.055)
        case .longBreak:
            // Peaceful serene sleeping/zen arc eyes
            CuteArcShape(isUpward: false)
                .stroke(
                    Color.white.opacity(0.95),
                    style: StrokeStyle(lineWidth: max(1.8, size * 0.042), lineCap: .round)
                )
                .frame(width: size * 0.11, height: size * 0.05)
        }
    }

    @ViewBuilder
    private var mouthShape: some View {
        switch phase {
        case .focus:
            // Gentle confident smile
            CuteArcShape(isUpward: false)
                .stroke(
                    Color.white.opacity(0.95),
                    style: StrokeStyle(lineWidth: max(1.6, size * 0.038), lineCap: .round)
                )
                .frame(width: size * 0.13, height: size * 0.05)
        case .shortBreak:
            // Happy open bubble smile
            Capsule()
                .fill(Color.white.opacity(0.92))
                .frame(width: size * 0.12, height: size * 0.065)
        case .longBreak:
            // Cute tiny 'o' breathing mouth
            Circle()
                .stroke(
                    Color.white.opacity(0.92),
                    lineWidth: max(1.5, size * 0.035)
                )
                .frame(width: size * 0.075, height: size * 0.075)
                .scaleEffect(isFloating ? 1.15 : 0.88)
        }
    }

    // MARK: - Animations & Interactions
    private func startAmbientAnimations() {
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            isFloating = true
        }
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            leafSway = true
        }

        // Periodic gentle blink
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3.6))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.12)) {
                    isBlinking = true
                }
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.12)) {
                    isBlinking = false
                }
            }
        }
    }

    private func triggerCuteBounce() {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.42)) {
            tapBounce = true
        }

        // Spawn mini bubbles around the logo
        let newBubbles: [MiniPopBubble] = (0..<5).map { index in
            let angle = (Double(index) / 5.0) * (.pi * 2.0) + Double.random(in: -0.3...0.3)
            let distance = size * CGFloat.random(in: 0.58...0.85)
            return MiniPopBubble(
                diameter: max(5, size * CGFloat.random(in: 0.10...0.18)),
                targetX: cos(angle) * distance,
                targetY: sin(angle) * distance - size * 0.12
            )
        }
        popBubbles = newBubbles

        withAnimation(.easeOut(duration: 0.55)) {
            for index in popBubbles.indices {
                popBubbles[index].offsetX = popBubbles[index].targetX
                popBubbles[index].offsetY = popBubbles[index].targetY
                popBubbles[index].opacity = 0
                popBubbles[index].scale = 1.25
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.36, dampingFraction: 0.55)) {
                tapBounce = false
            }
            try? await Task.sleep(for: .milliseconds(450))
            popBubbles.removeAll()
        }
    }
}

// MARK: - Helper Shapes & Models for Logo
private struct CuteArcShape: Shape {
    let isUpward: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if isUpward {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.midX, y: rect.minY)
            )
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.midX, y: rect.maxY)
            )
        }
        return path
    }
}

private struct MiniPopBubble: Identifiable {
    let id = UUID()
    let diameter: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    var offsetX: CGFloat = 0
    var offsetY: CGFloat = 0
    var opacity: Double = 0.9
    var scale: CGFloat = 0.4
}

// MARK: - Ambient Floating Bubbles Background View
struct AmbientBubblesBackgroundView: View {
    let phase: PomodoroPhase
    let isRunning: Bool

    private let specs: [AmbientBubbleSpec] = [
        AmbientBubbleSpec(xRatio: 0.14, baseRadius: 26, speed: 18, swayAmp: 16, phaseOffset: 0.0),
        AmbientBubbleSpec(xRatio: 0.84, baseRadius: 36, speed: 14, swayAmp: 20, phaseOffset: 1.7),
        AmbientBubbleSpec(xRatio: 0.28, baseRadius: 16, speed: 24, swayAmp: 12, phaseOffset: 3.1),
        AmbientBubbleSpec(xRatio: 0.68, baseRadius: 22, speed: 20, swayAmp: 15, phaseOffset: 4.4),
        AmbientBubbleSpec(xRatio: 0.50, baseRadius: 44, speed: 12, swayAmp: 22, phaseOffset: 2.3),
        AmbientBubbleSpec(xRatio: 0.10, baseRadius: 14, speed: 26, swayAmp: 10, phaseOffset: 5.2),
        AmbientBubbleSpec(xRatio: 0.90, baseRadius: 18, speed: 22, swayAmp: 14, phaseOffset: 0.9),
        AmbientBubbleSpec(xRatio: 0.38, baseRadius: 28, speed: 16, swayAmp: 18, phaseOffset: 3.8),
        AmbientBubbleSpec(xRatio: 0.76, baseRadius: 13, speed: 28, swayAmp: 11, phaseOffset: 6.0)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let speedMultiplier = isRunning ? 1.35 : 0.55
                let totalHeight = size.height + 160

                for spec in specs {
                    let verticalTravel = (time * spec.speed * speedMultiplier + spec.phaseOffset * 90)
                        .truncatingRemainder(dividingBy: Double(totalHeight))
                    let y = size.height + 80 - CGFloat(verticalTravel)

                    let wave = sin(time * 0.9 + spec.phaseOffset) * Double(spec.swayAmp)
                    let x = size.width * spec.xRatio + CGFloat(wave)

                    let pulse = 1.0 + 0.06 * sin(time * 1.5 + spec.phaseOffset)
                    let radius = spec.baseRadius * CGFloat(pulse)

                    let bubbleRect = CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )

                    // Soft translucent bubble body
                    let gradient = Gradient(colors: [
                        phase.primaryColor.opacity(isRunning ? 0.16 : 0.10),
                        phase.secondaryColor.opacity(isRunning ? 0.08 : 0.05),
                        Color.white.opacity(0.02)
                    ])

                    context.fill(
                        Path(ellipseIn: bubbleRect),
                        with: .radialGradient(
                            gradient,
                            center: CGPoint(x: x - radius * 0.25, y: y - radius * 0.25),
                            startRadius: radius * 0.1,
                            endRadius: radius
                        )
                    )

                    // Delicate bubble rim stroke
                    context.stroke(
                        Path(ellipseIn: bubbleRect),
                        with: .color(phase.primaryColor.opacity(isRunning ? 0.20 : 0.12)),
                        lineWidth: 1.2
                    )

                    // Tiny specular highlight dot inside each bubble (top-left)
                    let shineRadius = max(2.2, radius * 0.18)
                    let shineCenter = CGPoint(
                        x: x - radius * 0.36,
                        y: y - radius * 0.36
                    )
                    let shineRect = CGRect(
                        x: shineCenter.x - shineRadius,
                        y: shineCenter.y - shineRadius * 0.7,
                        width: shineRadius * 2,
                        height: shineRadius * 1.4
                    )
                    context.fill(
                        Path(ellipseIn: shineRect),
                        with: .color(Color.white.opacity(isRunning ? 0.45 : 0.28))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct AmbientBubbleSpec {
    let xRatio: CGFloat
    let baseRadius: CGFloat
    let speed: Double
    let swayAmp: CGFloat
    let phaseOffset: Double
}
