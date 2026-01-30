import SwiftUI

struct MyGoalsView: View {
    let viewModel: MyGoalsViewModel

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                if viewModel.data.hasMissions {
                    missionList
                    actionRow
                } else {
                    emptyState
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(MaterialSymbol(name: "arrow_back_ios_new", size: 18).foregroundColor(Color(hex: "#3D3D3D")))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            Spacer()
            Text("My Goals")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    private var missionList: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.data.missions) { mission in
                missionCard(mission: mission)
            }
        }
    }

    private func missionCard(mission: Mission) -> some View {
        let tint: String
        let background: String
        
        switch mission.type {
        case .calories:
            tint = "#FB923C"
            background = "#FFF7ED"
        case .minutes:
            tint = "#60A5FA"
            background = "#EFF6FF"
        case .sessions:
            tint = "#34D399"
            background = "#ECFDF3"
        }
        
        let percent = Int(mission.progress * 100)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(Color(hex: background))
                        .frame(width: 36, height: 36)
                    MaterialSymbol(name: mission.icon, size: 18)
                        .foregroundColor(Color(hex: tint))
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(missionTitle(mission))
                            .font(AppFonts.nunito(15, weight: .black))
                            .foregroundColor(Color(hex: "#3D3D3D"))
                        Spacer()
                        Text("\(percent)%")
                            .font(AppFonts.nunito(12, weight: .bold))
                            .foregroundColor(Color(hex: "#A8A29E"))
                    }
                    Text("\(formatted(mission.progressValue)) / \(formatted(mission.targetValue)) \(unitText(mission))")
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(Color(hex: "#78716C"))
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color(hex: "#F3F4F6"))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color(hex: tint))
                        .frame(width: geometry.size.width * CGFloat(mission.progress), height: 8)
                }
            }
            .frame(height: 8)

            Text("Ends \(endDateText(mission))")
                .font(AppFonts.nunito(11, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func missionTitle(_ mission: Mission) -> String {
        switch mission.type {
        case .calories:
            return "Burn \(formatted(mission.targetValue)) Calories"
        case .minutes:
            return "\(formatted(mission.targetValue)) Minutes Active"
        case .sessions:
            return "Complete \(formatted(mission.targetValue)) Sessions"
        }
    }
    
    private func unitText(_ mission: Mission) -> String {
        switch mission.type {
        case .calories: return "kcal"
        case .minutes: return "min"
        case .sessions: return "sessions"
        }
    }
    
    private func endDateText(_ mission: Mission) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: mission.endAt) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
        return mission.endAt
    }

    private func formatted(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.onEditGoal) {
                Text("Edit Goal")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#FF8577"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Button(action: viewModel.onViewMission) {
                Text("View Weekly Mission")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color(hex: "#F1F5F9"), lineWidth: 1))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("😴")
                .font(.system(size: 36))
            Text("No mission for this week")
                .font(AppFonts.nunito(16, weight: .black))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Text("Set a goal and start your week strong.")
                .font(AppFonts.nunito(13, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
            Button(action: viewModel.onGetQuest) {
                HStack(spacing: 6) {
                    Text("🧠")
                    Text("Get a Quest")
                        .font(AppFonts.nunito(14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color(hex: "#FF8577"))
                .clipShape(Capsule())
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
