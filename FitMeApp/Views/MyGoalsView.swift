import SwiftUI

struct MyGoalsView: View {
    @ObservedObject var viewModel: MyGoalsViewModel
    @ObservedObject private var appViewModel: AppViewModel
    @State private var isCreating = false
    
    init(viewModel: MyGoalsViewModel) {
        self.viewModel = viewModel
        self.appViewModel = viewModel.appViewModel
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        if appViewModel.activeMissions.isEmpty {
                            emptyState
                            generateButton
                        } else {
                            thisWeekSection
                        }
                        
                        if !appViewModel.completedMissions.isEmpty {
                            completedSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: { viewModel.onBack() }) {
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
    
    private var generateButton: some View {
        Button(action: {
            isCreating = true
            Task {
                await appViewModel.createAIMissions()
                isCreating = false
            }
        }) {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .tint(.white)
                } else {
                    MaterialSymbol(name: "auto_awesome", size: 22)
                }
                Text(isCreating ? "Generating..." : "Generate Weekly Goals")
                    .font(AppFonts.nunito(16, weight: .black))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#FF8577"))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "#FF8577").opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(isCreating)
    }
    
    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active Goals")
                    .font(AppFonts.quicksand(18, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("\(appViewModel.activeMissions.count)/3")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#A8A29E"))
            }
            
            ForEach(appViewModel.activeMissions) { mission in
                missionCard(mission: mission)
            }
        }
    }
    
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Completed")
                        .font(AppFonts.quicksand(18, weight: .heavy))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    Spacer()
                    Text("\(appViewModel.completedMissions.count)")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(Color(hex: "#34D399"))
                }
                Text("Goals you've crushed this week 🎉")
                    .font(AppFonts.nunito(13, weight: .semibold))
                    .foregroundColor(Color(hex: "#A8A29E"))
            }
            
            ForEach(appViewModel.completedMissions) { mission in
                completedMissionCard(mission: mission)
            }
        }
    }
    
    private func completedMissionCard(mission: Mission) -> some View {
        let tint: String
        let iconName: String
        
        switch mission.type {
        case .calories:
            tint = "#FB923C"
            iconName = "local_fire_department"
        case .minutes:
            tint = "#60A5FA"
            iconName = "timer"
        case .sessions:
            tint = "#34D399"
            iconName = "fitness_center"
        }

        return HStack(spacing: 14) {
            // Checkmark with type color accent
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(Color(hex: tint).opacity(0.3), lineWidth: 2)
                    .frame(width: 44, height: 44)
                MaterialSymbol(name: "check", size: 20)
                    .foregroundColor(Color(hex: tint))
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(missionTypeLabel(mission.type))
                    .font(AppFonts.nunito(15, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                HStack(spacing: 4) {
                    Text("\(mission.targetValue)")
                        .font(AppFonts.nunito(13, weight: .black))
                        .foregroundColor(Color(hex: tint))
                    Text(mission.type == .sessions ? "sessions" : mission.type == .minutes ? "min" : "kcal")
                        .font(AppFonts.nunito(13, weight: .semibold))
                        .foregroundColor(Color(hex: "#78716C"))
                }
            }
            
            Spacer()
            
            // Points earned badge
            HStack(spacing: 4) {
                MaterialSymbol(name: "star", size: 14)
                Text("+10")
                    .font(AppFonts.nunito(13, weight: .black))
            }
            .foregroundColor(Color(hex: "#F59E0B"))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: "#FEF3C7"))
            .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: "#34D399").opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func missionCard(mission: Mission) -> some View {
        let tint: String
        let background: String
        let iconName: String
        
        switch mission.type {
        case .calories:
            tint = "#FB923C"
            background = "#FFF7ED"
            iconName = "local_fire_department"
        case .minutes:
            tint = "#60A5FA"
            background = "#EFF6FF"
            iconName = "timer"
        case .sessions:
            tint = "#34D399"
            background = "#ECFDF3"
            iconName = "fitness_center"
        }
        
        let percent = Int(mission.progress * 100)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: background))
                    .frame(width: 48, height: 48)
                MaterialSymbol(name: iconName, size: 22)
                    .foregroundColor(Color(hex: tint))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(missionTypeLabel(mission.type))
                        .font(AppFonts.nunito(15, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    Spacer()
                    Text("\(mission.progressValue)/\(mission.targetValue)")
                        .font(AppFonts.nunito(14, weight: .black))
                        .foregroundColor(Color(hex: tint))
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
                
                Text("\(percent)% complete")
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(Color(hex: "#A8A29E"))
            }
            
            Button(action: {
                Task {
                    await viewModel.onDeleteMission(mission.id)
                }
            }) {
                Circle()
                    .fill(Color(hex: "#FEE2E2"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        MaterialSymbol(name: "delete", size: 18)
                            .foregroundColor(Color(hex: "#EF4444"))
                    )
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func missionTypeLabel(_ type: MissionType) -> String {
        switch type {
        case .calories: return "Calories"
        case .minutes: return "Active Minutes"
        case .sessions: return "Workout Sessions"
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🎯")
                .font(.system(size: 48))
            Text("No goals yet")
                .font(AppFonts.nunito(18, weight: .black))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Text("Add a goal to track your progress this week")
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
}
