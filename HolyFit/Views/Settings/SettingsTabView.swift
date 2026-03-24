import SwiftUI

struct SettingsTabView: View {
    @AppStorage("defaultRestTimer") private var defaultRestTimer: Int = AppConstants.defaultRestTimerSeconds
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    @AppStorage("healthKitEnabled") private var healthKitEnabled: Bool = false
    @AppStorage("rpeMode") private var rpeMode: String = "off"

    @Environment(HealthKitManager.self) private var healthKitManager

    @State private var bodyMass: Double? = nil
    @State private var stepCount: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Profile header card
                    headerCard

                    // Workout section
                    settingsSection(title: "운동 설정", icon: "dumbbell.fill", iconColor: AppColors.gradientStart) {
                        NavigationLink {
                            RestTimerPickerView(selection: $defaultRestTimer)
                        } label: {
                            SettingsRowContent(
                                icon: "timer",
                                iconColor: AppColors.info,
                                label: "기본 쉬는 시간",
                                value: restTimerLabel(defaultRestTimer),
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.horizontal, AppSpacing.md)

                        HStack(spacing: AppSpacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                    .fill(AppColors.warning)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "gauge.medium")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            Text("RPE 기록")
                                .font(AppFont.body(15))

                            Spacer()

                            Picker("", selection: $rpeMode) {
                                Text("끄기").tag("off")
                                Text("세트별").tag("set")
                                Text("세션").tag("session")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 195)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm + 2)
                    }

                    // Display section
                    settingsSection(title: "화면 설정", icon: "paintbrush.fill", iconColor: AppColors.warning) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(AppColors.themePurple)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                            Text("테마")
                                .font(AppFont.body(15))

                            Spacer()

                            Picker("", selection: $appearanceMode) {
                                Text("시스템").tag("auto")
                                Text("라이트").tag("light")
                                Text("다크").tag("dark")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                    }

                    // Health section
                    healthSection

                    // Data section
                    settingsSection(title: "데이터", icon: "externaldrive.fill", iconColor: AppColors.success) {
                        NavigationLink {
                            DataManagementView()
                        } label: {
                            SettingsRowContent(
                                icon: "externaldrive.fill",
                                iconColor: AppColors.danger,
                                label: "데이터 관리",
                                value: nil,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Profile section
                    settingsSection(title: "프로필", icon: "person.fill", iconColor: AppColors.protein) {
                        NavigationLink {
                            MyProfileView()
                        } label: {
                            SettingsRowContent(
                                icon: "person.fill",
                                iconColor: AppColors.protein,
                                label: "내 정보",
                                value: nil,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Info section
                    settingsSection(title: "정보", icon: "info.circle.fill", iconColor: AppColors.info) {
                        NavigationLink {
                            AboutView()
                        } label: {
                            SettingsRowContent(
                                icon: "info.circle.fill",
                                iconColor: AppColors.info,
                                label: "앱 정보",
                                value: nil,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Version footer
                    Text("HolyFit v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                        .font(AppFont.caption(12))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.bottom, AppSpacing.md)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, 2)
                .padding(.bottom, AppSpacing.lg)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Health section

    @ViewBuilder
    private var healthSection: some View {
        settingsSection(title: "건강 앱 연동", icon: "heart.fill", iconColor: AppColors.danger) {
            // Toggle row
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                        .fill(AppColors.danger)
                        .frame(width: 32, height: 32)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text("건강 앱 연동")
                    .font(AppFont.body(15))
                    .foregroundStyle(.primary)

                Spacer()

                if healthKitEnabled && healthKitManager.isAuthorized {
                    Text("연동됨")
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColors.success)
                } else if healthKitEnabled && !healthKitManager.isAuthorized {
                    Text("권한 필요")
                        .font(AppFont.caption(12))
                        .foregroundStyle(AppColors.danger)
                }

                Toggle("", isOn: $healthKitEnabled)
                    .labelsHidden()
                    .tint(AppColors.danger)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm + 4)
            .onChange(of: healthKitEnabled) { _, enabled in
                if enabled {
                    Task {
                        let granted = await healthKitManager.requestAuthorization()
                        if !granted {
                            healthKitEnabled = false
                        } else {
                            await loadHealthData()
                        }
                    }
                }
            }

            if healthKitEnabled && healthKitManager.isAvailable {
                Divider().padding(.horizontal, AppSpacing.md)

                // Body weight row
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColors.info)
                            .frame(width: 32, height: 32)
                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("체중")
                        .font(AppFont.body(15))
                        .foregroundStyle(.primary)

                    Spacer()

                    if let mass = bodyMass {
                        Text(String(format: "%.1f kg", mass))
                            .font(AppFont.body(15))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("데이터 없음")
                            .font(AppFont.body(15))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + 4)

                Divider().padding(.horizontal, AppSpacing.md)

                // Step count row
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                            .fill(AppColors.success)
                            .frame(width: 32, height: 32)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("오늘 걸음 수")
                        .font(AppFont.body(15))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(stepCount > 0 ? "\(stepCount) 걸음" : "데이터 없음")
                        .font(AppFont.body(15))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + 4)
            }

            if healthKitEnabled && !healthKitManager.isAvailable {
                Divider().padding(.horizontal, AppSpacing.md)

                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.warning)
                    Text("이 기기에서는 건강 앱을 사용할 수 없습니다")
                        .font(AppFont.caption(13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm + 4)
            }
        }
        .task {
            if healthKitEnabled && healthKitManager.isAvailable {
                healthKitManager.checkAuthorizationStatus()
                await loadHealthData()
            }
        }
    }

    private func loadHealthData() async {
        async let mass = healthKitManager.readBodyMass()
        async let steps = healthKitManager.readStepCount(for: Date())
        bodyMass = await mass
        stepCount = await steps
    }

    // MARK: - Header card

    private var headerCard: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGradient)
                    .frame(width: 56, height: 56)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("HolyFit")
                    .font(AppFont.heading(18))
                    .foregroundStyle(.primary)
                Text("헬스루틴 + 식단 관리")
                    .font(AppFont.caption(13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .glassCard()
    }

    // MARK: - Section builder

    @ViewBuilder
    private func settingsSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(AppFont.caption(12))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.secondaryLabel))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, AppSpacing.xs)

            VStack(spacing: 0) {
                content()
            }
            .glassCard(cornerRadius: AppRadius.xl)
        }
    }

    // MARK: - Helpers

    private func restTimerLabel(_ seconds: Int) -> String {
        if seconds >= 60 {
            let min = seconds / 60
            let sec = seconds % 60
            return sec > 0 ? "\(min)분 \(sec)초" : "\(min)분"
        }
        return "\(seconds)초"
    }

    private func appearanceLabel(_ mode: String) -> String {
        switch mode {
        case "light": return "라이트"
        case "dark": return "다크"
        default: return "자동"
        }
    }
}

// MARK: - Settings Row (tappable wrapper)

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            SettingsRowContent(
                icon: icon,
                iconColor: iconColor,
                label: label,
                value: value,
                showChevron: true
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row Content

struct SettingsRowContent: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String?
    let showChevron: Bool

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Colored icon circle (iOS Settings style)
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(label)
                .font(AppFont.body(15))
                .foregroundStyle(.primary)

            Spacer()

            if let value {
                Text(value)
                    .font(AppFont.body(15))
                    .foregroundStyle(.secondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Rest Timer Picker View

struct RestTimerPickerView: View {
    @Binding var selection: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(AppConstants.restTimerPresets, id: \.self) { seconds in
                Button {
                    selection = seconds
                    dismiss()
                } label: {
                    HStack {
                        Text(label(seconds))
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection == seconds {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("기본 쉬는 시간")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func label(_ seconds: Int) -> String {
        if seconds >= 60 {
            let min = seconds / 60
            let sec = seconds % 60
            return sec > 0 ? "\(min)분 \(sec)초" : "\(min)분"
        }
        return "\(seconds)초"
    }
}

// MARK: - Appearance Picker View

struct AppearancePickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let options: [(String, String, String)] = [
        ("auto",  "자동",   "circle.lefthalf.filled"),
        ("light", "라이트", "sun.max.fill"),
        ("dark",  "다크",   "moon.fill"),
    ]

    var body: some View {
        List {
            ForEach(options, id: \.0) { tag, label, icon in
                Button {
                    selection = tag
                    dismiss()
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        Text(label)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection == tag {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppColors.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("테마 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}
