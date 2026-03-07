import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ReportView: View {
    let viewModel: WeeklyReportDetailViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color.white.opacity(0.62), AppTheme.appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    mascot
                    titleSection
                    statGrid
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 140)
                .padding(.top, 2)
            }
            .refreshable {
                await viewModel.onRefresh()
            }
        }
        .task {
            await viewModel.onRefresh()
        }
    }

    @ViewBuilder
    private var mascot: some View {
#if canImport(UIKit)
        if let uiImage = UIImage(named: "hooray_bear") ?? UIImage(named: "bear-hero") {
            Image(uiImage: uiImage)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 224, height: 166)
        } else {
            MaterialSymbol(name: "pets", size: 88, style: .rounded)
                .foregroundColor(AppTheme.accentGold)
                .frame(height: 166)
        }
#else
        Image("hooray_bear")
            .resizable()
            .renderingMode(.original)
            .scaledToFit()
            .frame(width: 224, height: 166)
#endif
    }

    private var titleSection: some View {
        VStack(spacing: 0) {
            Text(currentWeekTitle)
                .font(AppFonts.quicksand(70, weight: .black))
                .foregroundColor(Color(hex: "#000000"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("HI, RUNNER!")
                .font(AppFonts.quicksand(52, weight: .black))
                .foregroundColor(Color(hex: "#F2977A"))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .offset(y: -8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, -4)
        .padding(.bottom, -2)
    }
    
    private var currentWeekTitle: String {
        weekLabel(for: viewModel.data.report.periodStart)
    }

    private var statGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
            spacing: 14
        ) {
            statCard(
                title: "총 운동 (회)",
                value: "\(viewModel.data.report.totalWorkouts)",
                icon: "fitness_center",
                iconColor: Color(hex: "#111111")
            )
            statCard(
                title: "총 칼로리 (kcal)",
                value: formatNumber(viewModel.data.report.totalCalories),
                icon: "local_fire_department",
                iconColor: Color(hex: "#F08B74")
            )
            statCard(
                title: "총 시간 (분)",
                value: "\(viewModel.data.report.totalMinutes)",
                icon: "timer",
                iconColor: Color(hex: "#111111")
            )
            statCard(
                title: "평균 시간 (분)",
                value: "\(viewModel.data.report.averageMinutes)",
                icon: "monitoring",
                iconColor: Color(hex: "#111111")
            )
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func statCard(title: String, value: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "#000000"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(AppFonts.nunito(15, weight: .black))
                .foregroundColor(Color(hex: "#000000"))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            MaterialSymbol(name: icon, size: 52, style: .rounded)
                .foregroundColor(iconColor)
                .frame(height: 50)
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, minHeight: 156)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(AppTheme.cardGold.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(AppTheme.cardBorderGold.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: AppTheme.accentGold.opacity(0.14), radius: 10, x: 0, y: 4)
        )
    }

    private func weekLabel(for startDate: String) -> String {
        guard let date = dateFromString(startDate) else { return "주간 리포트" }
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let weekOfMonth = calendar.component(.weekOfMonth, from: date)
        return "\(month)월 \(weekOfMonth)주차"
    }

    private func dateFromString(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: value)
    }
}

struct RadarChartView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius: CGFloat = size / 2 - 20
            ZStack {
                polygonPath(center: center, radius: radius, scale: 1.0)
                    .stroke(Color(hex: "#E5E7EB"), lineWidth: 2)
                polygonPath(center: center, radius: radius, scale: 0.66)
                    .stroke(Color(hex: "#E5E7EB").opacity(0.6), lineWidth: 2)
                polygonPath(center: center, radius: radius, scale: 0.33)
                    .stroke(Color(hex: "#E5E7EB").opacity(0.3), lineWidth: 2)
                axesPath(center: center, radius: radius)
                    .stroke(Color(hex: "#E5E7EB"), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                radarFill(radius: radius)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 220)
    }

    private func polygonPath(center: CGPoint, radius: CGFloat, scale: CGFloat) -> Path {
        var path = Path()
        for index in 0..<6 {
            let angle = (Double(index) * 60 - 90) * Double.pi / 180
            let x = center.x + CGFloat(cos(angle)) * radius * scale
            let y = center.y + CGFloat(sin(angle)) * radius * scale
            let point = CGPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    private func axesPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for index in 0..<6 {
            path.move(to: center)
            let angle = (Double(index) * 60 - 90) * Double.pi / 180
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            let point = CGPoint(x: x, y: y)
            path.addLine(to: point)
        }
        return path
    }

    private func radarFill(radius: CGFloat) -> some View {
        RadarFillShape(points: [0.75, 0.6, 0.85, 0.7, 0.55, 0.65])
            .fill(LinearGradient(colors: [Color(hex: "#6EE7B7").opacity(0.7), Color(hex: "#FF8577").opacity(0.7)], startPoint: .top, endPoint: .bottom))
            .overlay(
                RadarFillShape(points: [0.75, 0.6, 0.85, 0.7, 0.55, 0.65])
                    .stroke(Color(hex: "#3D3D3D"), lineWidth: 3)
            )
            .frame(width: radius * 2, height: radius * 2)
    }
}

struct RadarFillShape: Shape {
    let points: [CGFloat]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for i in 0..<points.count {
            let angle = (Double(i) * 60 - 90) * Double.pi / 180
            let value = points[i]
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius * value,
                                y: center.y + CGFloat(sin(angle)) * radius * value)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
