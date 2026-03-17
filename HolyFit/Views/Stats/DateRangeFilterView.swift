import SwiftUI

struct DateRangeFilterView: View {
    @Binding var selected: StatsViewModel.DateRange

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(StatsViewModel.DateRange.allCases) { range in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selected = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(AppFont.caption(13))
                            .fontWeight(selected == range ? .bold : .medium)
                            .foregroundStyle(selected == range ? .white : .secondary)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                Group {
                                    if selected == range {
                                        AnyView(AppColors.primaryGradient)
                                    } else {
                                        AnyView(Color(.systemGray5))
                                    }
                                }
                            )
                            .clipShape(Capsule())
                            .shadow(
                                color: selected == range ? AppColors.gradientStart.opacity(0.3) : .clear,
                                radius: 5, x: 0, y: 2
                            )
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: selected)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }
}
