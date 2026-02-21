import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FadeLiftInModifier: ViewModifier {
    let delay: Double
    let indexedDelay: Double
    let reduceMotion: Bool
    let enabled: Bool

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(enabled ? (isVisible ? 1 : 0.001) : 1)
            .offset(y: enabled ? (isVisible ? 0 : (reduceMotion ? 2 : AppMotion.entryOffsetY)) : 0)
            .animation(entryAnimation, value: isVisible)
            .onAppear {
                guard enabled else {
                    isVisible = true
                    return
                }
                guard !isVisible else { return }
                let totalDelay = delay + indexedDelay
                if totalDelay <= 0 {
                    isVisible = true
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                        isVisible = true
                    }
                }
            }
    }

    private var entryAnimation: Animation {
        .easeOut(duration: reduceMotion ? 0.12 : AppMotion.durationNormal)
    }
}

struct PressFeedbackModifier: ViewModifier {
    let haptic: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(reduceMotion ? 1 : (isPressed ? AppMotion.pressScale : 1))
            .opacity(isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: reduceMotion ? 0.08 : AppMotion.durationFast), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        let shouldTriggerHaptic = isPressed
                        isPressed = false
                        if shouldTriggerHaptic && haptic {
                            MotionHaptics.impactLight()
                        }
                    }
            )
    }
}

private struct MotionEntryWrapperModifier: ViewModifier {
    let index: Int
    let enabled: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.modifier(
            FadeLiftInModifier(
                delay: 0,
                indexedDelay: Double(max(0, index)) * AppMotion.staggerStep,
                reduceMotion: reduceMotion,
                enabled: enabled
            )
        )
    }
}

enum MotionHaptics {
    static func impactLight() {
#if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
#endif
    }
}

extension View {
    func motionEntry(index: Int = 0, enabled: Bool = true) -> some View {
        modifier(MotionEntryWrapperModifier(index: index, enabled: enabled))
    }

    func motionPressable(haptic: Bool = false) -> some View {
        modifier(PressFeedbackModifier(haptic: haptic))
    }
}
