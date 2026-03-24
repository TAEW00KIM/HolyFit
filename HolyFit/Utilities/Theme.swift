import SwiftUI

// MARK: - Color System — Black / Red

enum AppColors {
    // Primary gradient - 크림슨 에너지
    static let gradientStart = Color(hex: "E63946")  // 크림슨
    static let gradientEnd = Color(hex: "FF2D55")    // 핫 핑크 레드
    static let primaryGradient = LinearGradient(
        colors: [gradientStart, gradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Accent colors
    static let accent = Color(hex: "E63946")
    static let accentLight = Color(hex: "FF4D6A")

    // Semantic colors
    static let success = Color(hex: "34C759")       // iOS 그린
    static let warning = Color(hex: "FF9F0A")       // 앰버
    static let danger = Color(hex: "FF453A")        // 시스템 레드
    static let info = Color(hex: "64D2FF")          // 시안

    // UI accent (misc)
    static let themePurple = Color(hex: "6C5CE7")   // 테마 설정 아이콘

    // Chart colors
    static let chartBlue = Color(hex: "0A84FF")
    static let chartGreen = Color(hex: "30D158")
    static let chartRed = Color(hex: "FF453A")
    static let chartOrange = Color(hex: "FF9F0A")
    static let chartPurple = Color(hex: "BF5AF2")

    // Macro colors
    static let calories = Color(hex: "FF453A")
    static let protein = Color(hex: "0A84FF")
    static let carbs = Color(hex: "FF9F0A")
    static let fat = Color(hex: "BF5AF2")

    // Adaptive surface colors (light/dark mode)
    static let surface = Color(.systemBackground)
    static let surfaceElevated = Color(.secondarySystemBackground)
    static let surfaceHighlight = Color(.tertiarySystemBackground)

    // Adaptive text colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Muscle group colors — vibrant on dark
    static func muscleGroupColor(_ group: MuscleGroup) -> Color {
        switch group {
        case .chest: return Color(hex: "FF453A")
        case .back: return Color(hex: "0A84FF")
        case .shoulders: return Color(hex: "FF9F0A")
        case .legs: return Color(hex: "30D158")
        case .biceps: return Color(hex: "BF5AF2")
        case .triceps: return Color(hex: "FF6482")
        case .core: return Color(hex: "FFD60A")
        case .fullBody: return Color(hex: "64D2FF")
        case .cardio: return Color(hex: "32D74B")
        }
    }
}

// MARK: - Typography

enum AppFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }
    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
    static func mono(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
    static func stat(_ size: CGFloat = 36) -> Font {
        .system(size: size, weight: .black, design: .default)
    }
}

// MARK: - Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 100
}

// MARK: - Dark Card Modifier

struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.lg

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GradientCard: ViewModifier {
    var colors: [Color] = [AppColors.gradientStart, AppColors.gradientEnd]
    var cornerRadius: CGFloat = AppRadius.lg

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: colors.first?.opacity(0.4) ?? .clear, radius: 16, x: 0, y: 8)
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = AppRadius.lg) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func gradientCard(colors: [Color] = [AppColors.gradientStart, AppColors.gradientEnd], cornerRadius: CGFloat = AppRadius.lg) -> some View {
        modifier(GradientCard(colors: colors, cornerRadius: cornerRadius))
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
