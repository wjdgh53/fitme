import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ReportListView: View {
    let viewModel: ReportListViewModel
    @State private var hasAnimatedReportList = false

    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if viewModel.data.reports.isEmpty {
                        emptyState
                    } else {
                        reportList
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, AppLayout.tabBarHeight + 24)
            }
            .refreshable {
                await viewModel.onRefresh()
            }
        }
        .task {
            await viewModel.onRefresh()
        }
    }

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 2) {
                Text("주간 리포트")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(AppTheme.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("Weekly summary")
                    .font(AppFonts.nunito(15, weight: .bold))
                    .foregroundColor(AppTheme.subtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 136)

            bearHeaderArt
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .motionEntry(index: 0)
    }

    private var bearHeaderArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.cardGold.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.cardBorderGold.opacity(0.65), lineWidth: 1)
                )

            bearImage
                .frame(width: 124, height: 92)
        }
        .frame(width: 130, height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.accentGold.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var bearImage: some View {
#if canImport(UIKit)
        if let uiImage = UIImage(named: "hooray_bear") ?? UIImage(named: "bear-hero") {
            Image(uiImage: uiImage)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
        } else {
            MaterialSymbol(name: "pets", size: 34, style: .rounded)
                .foregroundColor(AppTheme.accentGold)
        }
#else
        Image("hooray_bear")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
#endif
    }

    private var reportList: some View {
        VStack(spacing: 24) {
            ForEach(Array(viewModel.data.reports.enumerated()), id: \.element.id) { index, report in
                reportCard(report)
                    .motionPressable(haptic: false)
                    .motionEntry(index: min(index + 1, 8), enabled: !hasAnimatedReportList && index < 8)
                    .onAppear {
                        if index == min(viewModel.data.reports.count - 1, 7) {
                            hasAnimatedReportList = true
                        }
                    }
            }
        }
    }

    private func reportCard(_ report: WeeklyReport) -> some View {
        Button(action: { viewModel.onSelectReport(report) }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.cardGold.opacity(0.82))
                    MaterialSymbol(name: "pets", size: 34, style: .rounded)
                        .foregroundColor(AppTheme.accentGold)
                }
                .frame(width: 62, height: 62)
                .overlay(Circle().stroke(AppTheme.cardBorderGold.opacity(0.7), lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    Text(weekLabel(for: report.periodStart))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(AppTheme.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(dateRangeText(start: report.periodStart, end: report.periodEnd))
                        .font(AppFonts.nunito(15, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(report.totalWorkouts)회 • \(formatNumber(report.totalCalories))kcal")
                        .font(AppFonts.nunito(16, weight: .black))
                        .foregroundColor(AppTheme.accentGold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("총 \(report.totalMinutes)분")
                        .font(AppFonts.nunito(16, weight: .black))
                        .foregroundColor(AppTheme.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 17)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(AppTheme.cardGold.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(AppTheme.cardBorderGold, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            MaterialSymbol(name: "pets", size: 56, style: .rounded)
                .foregroundColor(AppTheme.primaryButton)
            Text("주간 리포트가 없어요")
                .font(AppFonts.nunito(18, weight: .bold))
                .foregroundColor(AppTheme.title)
            Text("운동을 기록하면 주간 리포트가 생성돼요")
                .font(AppFonts.nunito(14, weight: .medium))
                .foregroundColor(AppTheme.subtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppTheme.subtleSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1.5)
                )
        )
        .motionEntry(index: 1)
    }

    private func weekLabel(for startDate: String) -> String {
        guard let date = dateFromString(startDate) else { return "주간 리포트" }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let weekOfMonth = calendar.component(.weekOfMonth, from: date)
        return "\(month)월 \(weekOfMonth)주차"
    }

    private func dateRangeText(start: String, end: String) -> String {
        guard let startDate = dateFromString(start), let endDate = dateFromString(end) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let startText = formatter.string(from: startDate)
        let endText = formatter.string(from: endDate)
        return "\(startText) - \(endText)"
    }

    private func dateFromString(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: value)
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
