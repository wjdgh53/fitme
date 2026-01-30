import SwiftUI

struct MyGoalsView: View {
    let viewModel: MyGoalsViewModel
    @State private var showAddSheet = false
    @State private var showCustomSheet = false
    @State private var selectedMissionType: MissionType = .sessions
    @State private var targetValue: Int = 4
    @State private var isCreating = false

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
                        addButton
                        
                        if !viewModel.data.missions.isEmpty {
                            thisWeekSection
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addMissionSheet
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCustomSheet) {
            customMissionSheet
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
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
    
    private var addButton: some View {
        Button(action: { showAddSheet = true }) {
            HStack(spacing: 8) {
                MaterialSymbol(name: "add_circle", size: 22)
                Text("Add New Goal")
                    .font(AppFonts.nunito(16, weight: .black))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                viewModel.data.missions.count >= 3
                    ? Color(hex: "#D1D5DB")
                    : Color(hex: "#FF8577")
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "#FF8577").opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.data.missions.count >= 3)
    }
    
    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .font(AppFonts.quicksand(18, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("\(viewModel.data.missions.count)/3")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#A8A29E"))
            }
            
            ForEach(viewModel.data.missions) { mission in
                missionCard(mission: mission)
            }
        }
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
    
    // MARK: - Add Mission Sheet
    
    private var addMissionSheet: some View {
        VStack(spacing: 16) {
            Text("Add New Goal")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
                .padding(.top, 8)
            
            VStack(spacing: 12) {
                Button(action: {
                    showAddSheet = false
                    Task {
                        await viewModel.onCreateAIMissions()
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#EDE9FE"))
                                .frame(width: 44, height: 44)
                            MaterialSymbol(name: "auto_awesome", size: 22)
                                .foregroundColor(Color(hex: "#8B5CF6"))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI Recommend")
                                .font(AppFonts.nunito(16, weight: .black))
                                .foregroundColor(Color(hex: "#3D3D3D"))
                            Text("Let AI create 3 personalized goals")
                                .font(AppFonts.nunito(12, weight: .bold))
                                .foregroundColor(Color(hex: "#A8A29E"))
                        }
                        Spacer()
                        MaterialSymbol(name: "chevron_right", size: 20)
                            .foregroundColor(Color(hex: "#D1D5DB"))
                    }
                    .padding(14)
                    .background(Color(hex: "#FAFAFA"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                
                Button(action: {
                    showAddSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCustomSheet = true
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FEF3C7"))
                                .frame(width: 44, height: 44)
                            MaterialSymbol(name: "edit", size: 22)
                                .foregroundColor(Color(hex: "#F59E0B"))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom Goal")
                                .font(AppFonts.nunito(16, weight: .black))
                                .foregroundColor(Color(hex: "#3D3D3D"))
                            Text("Set your own target")
                                .font(AppFonts.nunito(12, weight: .bold))
                                .foregroundColor(Color(hex: "#A8A29E"))
                        }
                        Spacer()
                        MaterialSymbol(name: "chevron_right", size: 20)
                            .foregroundColor(Color(hex: "#D1D5DB"))
                    }
                    .padding(14)
                    .background(Color(hex: "#FAFAFA"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.white)
    }
    
    // MARK: - Custom Mission Sheet
    
    private var customMissionSheet: some View {
        VStack(spacing: 20) {
            Text("Create Custom Goal")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Goal Type")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#6B7280"))
                
                HStack(spacing: 10) {
                    missionTypeButton(.sessions, icon: "fitness_center", label: "Sessions")
                    missionTypeButton(.minutes, icon: "timer", label: "Minutes")
                    missionTypeButton(.calories, icon: "local_fire_department", label: "Calories")
                }
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Target Value")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#6B7280"))
                
                HStack(spacing: 16) {
                    Button(action: { targetValue = max(1, targetValue - stepValue) }) {
                        Circle()
                            .fill(Color(hex: "#F3F4F6"))
                            .frame(width: 44, height: 44)
                            .overlay(MaterialSymbol(name: "remove", size: 22).foregroundColor(Color(hex: "#6B7280")))
                    }
                    
                    Text("\(targetValue)")
                        .font(AppFonts.nunito(36, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                        .frame(minWidth: 80)
                    
                    Button(action: { targetValue += stepValue }) {
                        Circle()
                            .fill(Color(hex: "#FF8577"))
                            .frame(width: 44, height: 44)
                            .overlay(MaterialSymbol(name: "add", size: 22).foregroundColor(.white))
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(targetHint)
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#A8A29E"))
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            
            Button(action: {
                isCreating = true
                Task {
                    await viewModel.onCreateCustomMission(selectedMissionType, .medium, targetValue)
                    isCreating = false
                    showCustomSheet = false
                }
            }) {
                HStack {
                    if isCreating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Goal")
                            .font(AppFonts.nunito(16, weight: .black))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#FF8577"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isCreating)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(Color.white)
        .onChange(of: selectedMissionType) { _, _ in
            targetValue = defaultTargetValue
        }
    }
    
    private func missionTypeButton(_ type: MissionType, icon: String, label: String) -> some View {
        let isSelected = selectedMissionType == type
        let tint: String
        switch type {
        case .sessions: tint = "#34D399"
        case .minutes: tint = "#60A5FA"
        case .calories: tint = "#FB923C"
        }
        
        return Button(action: { selectedMissionType = type }) {
            VStack(spacing: 6) {
                MaterialSymbol(name: icon, size: 24)
                    .foregroundColor(isSelected ? Color(hex: tint) : Color(hex: "#9CA3AF"))
                Text(label)
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(isSelected ? Color(hex: "#3D3D3D") : Color(hex: "#9CA3AF"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color(hex: tint).opacity(0.1) : Color(hex: "#F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color(hex: tint) : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var stepValue: Int {
        switch selectedMissionType {
        case .sessions: return 1
        case .minutes: return 30
        case .calories: return 100
        }
    }
    
    private var defaultTargetValue: Int {
        switch selectedMissionType {
        case .sessions: return 4
        case .minutes: return 120
        case .calories: return 800
        }
    }
    
    private var targetHint: String {
        switch selectedMissionType {
        case .sessions: return "workout sessions this week"
        case .minutes: return "active minutes this week"
        case .calories: return "calories to burn this week"
        }
    }
}
