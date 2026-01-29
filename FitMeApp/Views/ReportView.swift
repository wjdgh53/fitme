import SwiftUI

struct ReportView: View {
    let viewModel: ReportViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    weightCard
                    statGrid
                    balanceSection
                    topExercisesSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 140)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hi, Runner!")
                    .font(AppFonts.nunito(12, weight: .heavy))
                    .foregroundColor(Color(hex: "#FF8577"))
                    .textCase(.uppercase)
                    .tracking(1)
                Text(viewModel.data.monthTitle)
                    .font(AppFonts.nunito(30, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }
            Spacer()
            AsyncImage(url: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuDQoirGpC7LV0pxmdR-Yt3Of7x4qaD5V1hok8ZG_MBHDYQE1RWw-YpmJOV_We8dfgtR-E_D-3AD7qie7JzrgaLuDfUqwNAz0h3XRwGWuV64HLzz3htuwOFenAzytepnvdkGXRZJ3QIzQRHzuXp3q92x9F5ZIa6olUWn6Ml16GtqsbUkXMCqerSuVbYug5efMXkQpwNCVUcg7UqAo_nQxR0gddv4DLR3_zy_szabgoP2o8OruRdtSR2Oqha8Z3HHbLSmlffabADvr_g")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
        }
        .padding(.top, 6)
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        MaterialSymbol(name: "monitor_weight", size: 18)
                            .foregroundColor(Color(hex: "#FF8577"))
                        Text("체중 변화")
                            .font(AppFonts.nunito(12, weight: .bold))
                            .foregroundColor(Color(hex: "#78716C"))
                    }
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(viewModel.data.weightValue)
                            .font(AppFonts.nunito(48, weight: .black))
                            .foregroundColor(Color(hex: "#3D3D3D"))
                        Text("kg")
                            .font(AppFonts.nunito(20, weight: .bold))
                            .foregroundColor(Color(hex: "#78716C"))
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        MaterialSymbol(name: "trending_down", size: 18)
                        Text(viewModel.data.weightDelta)
                            .font(AppFonts.nunito(14, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "#059669"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#6EE7B7").opacity(0.2))
                    .clipShape(Capsule())
                    Text("Nice job! 🎉")
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(Color(hex: "#FF8577"))
                }
            }

            WeightChartView()
                .frame(height: 140)

            HStack {
                Text("10.01")
                Spacer()
                Text("10.08")
                Spacer()
                Text("10.15")
                Spacer()
                Text("10.22")
                Spacer()
                Text("오늘")
                    .foregroundColor(Color(hex: "#FF8577"))
            }
            .font(AppFonts.nunito(11, weight: .bold))
            .foregroundColor(Color(hex: "#78716C").opacity(0.6))
            .padding(.top, 6)
            .overlay(Rectangle().fill(Color(hex: "#F3F4F6")).frame(height: 1), alignment: .top)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color(hex: "#FFF1F2"), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "총 운동", value: viewModel.data.totalWorkouts, unit: "회", icon: "fitness_center", color: "#FF8577")
            statCard(title: "PR 달성", value: viewModel.data.prCount, unit: "회", icon: "emoji_events", color: "#FCD34D")
            statCard(title: "총 볼륨", value: viewModel.data.volume, unit: "톤", icon: "weight", color: "#6EE7B7")
            statCard(title: "총 시간", value: viewModel.data.totalTime, unit: "시간", icon: "timer", color: "#A78BFA")
        }
    }

    private func statCard(title: String, value: String, unit: String, icon: String, color: String) -> some View {
        AnyView(
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color(hex: color).opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(MaterialSymbol(name: icon, size: 20).foregroundColor(Color(hex: color)))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(Color(hex: "#78716C"))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(AppFonts.nunito(26, weight: .black))
                            .foregroundColor(Color(hex: "#3D3D3D"))
                        Text(unit)
                            .font(AppFonts.nunito(12, weight: .bold))
                            .foregroundColor(Color(hex: "#78716C"))
                    }
                }
            }
            .padding(18)
            .frame(minHeight: 150)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color(hex: color), lineWidth: 4).opacity(0.2))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        )
    }

    private var balanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("근력 밸런스")
                    .font(AppFonts.nunito(20, weight: .heavy))
                Spacer()
                Text("Perfect Shape! ✨")
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(Color(hex: "#059669"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#6EE7B7").opacity(0.2))
                    .clipShape(Capsule())
            }

            VStack(spacing: 12) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color(hex: "#FFF1F2"), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

                    Text("어깨가 살짝 부족해요! 💪")
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#3D3D3D"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.top, 16)
                        .padding(.leading, 16)

                    RadarChartView()
                        .padding(.top, 36)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }

                VStack(spacing: 4) {
                    Text("균형잡힌 몸이에요!")
                        .font(AppFonts.nunito(14, weight: .heavy))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    Text("다음엔 어깨 운동을 더 해볼까요?")
                        .font(AppFonts.nunito(12, weight: .semibold))
                        .foregroundColor(Color(hex: "#78716C"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#FFF8F0"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var topExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상위 운동 Top 3")
                .font(AppFonts.nunito(20, weight: .heavy))
                .foregroundColor(Color(hex: "#3D3D3D"))

            VStack(spacing: 10) {
                topExerciseRow(rank: "1", title: "스쿼트", tags: ["Legs", "Barbell"], value: "3,200kg", color: "#FCD34D")
                topExerciseRow(rank: "2", title: "데드리프트", tags: ["Back"], value: "2,800kg", color: "#E5E7EB")
                topExerciseRow(rank: "3", title: "벤치프레스", tags: ["Chest"], value: "1,500kg", color: "#FFEDD5")
            }
        }
    }

    private func topExerciseRow(rank: String, title: String, tags: [String], value: String, color: String) -> some View {
        AnyView(
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: 40, height: 40)
                    .overlay(Text(rank).font(AppFonts.nunito(18, weight: .black)).foregroundColor(Color(hex: "#3D3D3D")))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.nunito(18, weight: .bold))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(AppFonts.nunito(10, weight: .bold))
                                .foregroundColor(Color(hex: "#78716C"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#FFF8F0"))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
                Spacer()
                Text(value)
                    .font(AppFonts.nunito(14, weight: .black))
                    .foregroundColor(Color(hex: "#D97706"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: color).opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#FCD34D").opacity(rank == "1" ? 0.3 : 0.1), lineWidth: rank == "1" ? 2 : 1))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
        )
    }
}

struct WeightChartView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                gridLines(height: height, width: width)
                fillArea(height: height, width: width)
                strokeLine(height: height, width: width)
                markers(height: height, width: width)
                nowTag(width: width)
            }
        }
    }

    private func gridLines(height: CGFloat, width: CGFloat) -> some View {
        ForEach([0.2, 0.5, 0.8], id: \.self) { fraction in
            Path { path in
                path.move(to: CGPoint(x: 0, y: height * fraction))
                path.addLine(to: CGPoint(x: width, y: height * fraction))
            }
            .stroke(Color(hex: "#3D3D3D").opacity(0.1), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
        }
    }

    private func fillArea(height: CGFloat, width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height * 0.7))
            path.addCurve(to: CGPoint(x: width, y: height * 0.2), control1: CGPoint(x: width * 0.3, y: height * 0.75), control2: CGPoint(x: width * 0.7, y: height * 0.3))
            path.addLine(to: CGPoint(x: width, y: height + 20))
            path.addLine(to: CGPoint(x: 0, y: height + 20))
            path.closeSubpath()
        }
        .fill(LinearGradient(colors: [Color(hex: "#FF8577").opacity(0.4), Color(hex: "#FF8577").opacity(0)], startPoint: .top, endPoint: .bottom))
    }

    private func strokeLine(height: CGFloat, width: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height * 0.7))
            path.addCurve(to: CGPoint(x: width, y: height * 0.2), control1: CGPoint(x: width * 0.3, y: height * 0.75), control2: CGPoint(x: width * 0.7, y: height * 0.3))
        }
        .stroke(Color(hex: "#FF8577"), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func markers(height: CGFloat, width: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color(hex: "#FF8577"), lineWidth: 3))
                .frame(width: 12, height: 12)
                .position(x: width * 0.43, y: height * 0.5)
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color(hex: "#FF8577"), lineWidth: 3))
                .frame(width: 12, height: 12)
                .position(x: width * 0.7, y: height * 0.3)
            Circle()
                .fill(Color(hex: "#FF8577"))
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .frame(width: 16, height: 16)
                .position(x: width, y: height * 0.2)
        }
    }

    private func nowTag(width: CGFloat) -> some View {
        Text("Now")
            .font(AppFonts.nunito(11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: "#3D3D3D"))
            .clipShape(Capsule())
            .position(x: width - 12, y: 8)
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

struct PolygonShape: Shape {
    let sides: Int
    let scale: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale
        for i in 0..<sides {
            let angle = (Double(i) * (360.0 / Double(sides)) - 90) * Double.pi / 180
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
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
