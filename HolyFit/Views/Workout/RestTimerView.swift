import SwiftUI
import UserNotifications
import UIKit

struct RestTimerView: View {
    @Environment(\.dismiss) private var dismiss
    let initialDuration: Int

    @State private var duration: Int
    @State private var remaining: Int
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var didFinish = false
    @State private var ringAppeared = false

    init(duration: Int) {
        self.initialDuration = duration
        _duration = State(initialValue: duration)
        _remaining = State(initialValue: duration)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Full dark background
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.xxl) {
                // Title
                HStack {
                    Text("휴식 타이머")
                        .font(AppFont.heading(20))
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                            .symbolEffect(.pulse, isActive: isRunning)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.lg)

                // Circular timer ring
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 14)
                        .frame(width: 240, height: 240)

                    // Gradient progress ring
                    Circle()
                        .trim(from: 0, to: ringAppeared ? progress : 0)
                        .stroke(
                            LinearGradient(
                                colors: remaining > 10
                                    ? [AppColors.gradientEnd, AppColors.gradientStart]
                                    : [AppColors.warning, AppColors.danger],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 240, height: 240)
                        .animation(.linear(duration: 1), value: remaining)

                    // Inner content
                    VStack(spacing: AppSpacing.xs) {
                        Text(timeString)
                            .font(AppFont.stat(54))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: remaining)

                        Text(didFinish ? "완료!" : "남음")
                            .font(AppFont.caption(13))
                            .foregroundStyle(didFinish ? AppColors.success : .secondary)
                            .animation(.spring(response: 0.3), value: didFinish)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("남은 시간")
                    .accessibilityValue(didFinish ? "완료" : "\(remaining)초")
                }

                // Preset buttons
                HStack(spacing: AppSpacing.sm) {
                    ForEach(AppConstants.restTimerPresets, id: \.self) { preset in
                        presetButton(preset)
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                // Controls
                HStack(spacing: AppSpacing.xl) {
                    // Reset button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        resetTimer(to: duration)
                        didFinish = false
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 60, height: 60)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }

                    // Play / Pause
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        toggleTimer()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRunning ? AnyShapeStyle(AppColors.warning) : AnyShapeStyle(AppColors.primaryGradient))
                                .frame(width: 80, height: 80)
                                .shadow(
                                    color: (isRunning ? AppColors.warning : AppColors.gradientStart).opacity(0.4),
                                    radius: 16, x: 0, y: 8
                                )

                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                                .offset(x: isRunning ? 0 : 2)
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRunning)
                    }

                    // Dismiss shortcut
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.success)
                            .frame(width: 60, height: 60)
                            .background(AppColors.success.opacity(0.12))
                            .clipShape(Circle())
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            requestNotificationPermission()
            startTimer()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                ringAppeared = true
            }
        }
        .onDisappear {
            stopTimer()
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        }
    }

    // MARK: - Preset Button

    private func presetButton(_ seconds: Int) -> some View {
        let isActive = remaining == seconds
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            resetTimer(to: seconds)
            didFinish = false
        } label: {
            Text(presetLabel(seconds))
                .font(AppFont.caption(12))
                .foregroundStyle(isActive ? .white : .secondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(
                    isActive
                        ? AnyShapeStyle(AppColors.primaryGradient)
                        : AnyShapeStyle(Color(.systemGray5))
                )
                .clipShape(Capsule())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
        .accessibilityLabel(presetLabel(seconds))
        .accessibilityHint("\(presetLabel(seconds)) 휴식 타이머로 설정합니다")
    }

    // MARK: - Computed

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return Double(remaining) / Double(duration)
    }

    private var timeString: String {
        let min = remaining / 60
        let sec = remaining % 60
        return String(format: "%d:%02d", min, sec)
    }

    private func presetLabel(_ seconds: Int) -> String {
        if seconds >= 60 {
            let min = seconds / 60
            let sec = seconds % 60
            return sec > 0 ? "\(min):\(String(format: "%02d", sec))" : "\(min)분"
        }
        return "\(seconds)초"
    }

    // MARK: - Timer Logic

    private func toggleTimer() {
        if isRunning { stopTimer() } else { startTimer() }
    }

    private func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        scheduleNotification()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if remaining > 0 {
                    remaining -= 1
                } else {
                    stopTimer()
                    didFinish = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer(to seconds: Int) {
        stopTimer()
        duration = seconds
        remaining = seconds
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        guard remaining > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = "쉬는 시간 종료"
        content.body = "다음 세트를 시작하세요!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(remaining), repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
