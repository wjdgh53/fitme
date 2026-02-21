import SwiftUI

struct MyGoalsView: View {
    @ObservedObject var viewModel: MyGoalsViewModel
    @ObservedObject private var appViewModel: AppViewModel
    @State private var showTypeSheet = false
    @State private var showLimitAlert = false
    @State private var showCreateError = false
    @State private var createErrorMessage = ""
    @State private var isCreating = false
    
    init(viewModel: MyGoalsViewModel) {
        self.viewModel = viewModel
        self.appViewModel = viewModel.appViewModel
    }

    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        addButton
                        
                        if appViewModel.activeMissions.isEmpty {
                            emptyState
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
        .overlay {
            if showTypeSheet {
                aiTypePopup
            }
            if isCreating {
                loadingOverlay
            }
        }
        .alert("Active Goals Limit", isPresented: $showLimitAlert) {
            Button("OK") { }
        } message: {
            Text("You can have up to 3 active goals at a time.")
        }
        .alert("Goal Creation Failed", isPresented: $showCreateError) {
            Button("OK") { }
        } message: {
            Text(createErrorMessage)
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color.white)
                    .scaleEffect(1.2)
                Text("Creating goal...")
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(.white)
                Text("AI is setting the target")
                    .font(AppFonts.nunito(12, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(24)
            .background(AppTheme.title.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .transition(.opacity)
    }

    private var header: some View {
        HStack {
            Button(action: { viewModel.onBack() }) {
                Circle()
                    .fill(AppTheme.elevatedSurface)
                    .frame(width: 44, height: 44)
                    .overlay(MaterialSymbol(name: "arrow_back_ios_new", size: 18).foregroundColor(AppTheme.title))
                    .shadow(color: AppTheme.border.opacity(0.2), radius: 6, x: 0, y: 3)
            }
            Spacer()
            Text("My Goals")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(AppTheme.title)
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            if !appViewModel.canAddMission {
                showLimitAlert = true
                return
            }
            guard !isCreating else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                showTypeSheet = true
            }
        }) {
            HStack(spacing: 8) {
                MaterialSymbol(name: "add_circle_outline", size: 22)
                Text("Add New Goal")
                    .font(AppFonts.nunito(16, weight: .black))
            }
            .foregroundColor((!appViewModel.canAddMission || isCreating) ? AppTheme.elevatedSurface : AppTheme.primaryButtonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if !appViewModel.canAddMission || isCreating {
                    AppTheme.iconMuted.opacity(0.6)
                } else {
                    AppTheme.primaryButtonGradient
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.primaryButton.opacity(0.25), radius: 8, x: 0, y: 4)
        }
    }
    
    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Active Goals")
                    .font(AppFonts.quicksand(18, weight: .heavy))
                    .foregroundColor(AppTheme.title)
                Spacer()
                Text("\(appViewModel.activeMissions.count)/3")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(AppTheme.iconMuted)
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
                        .foregroundColor(AppTheme.title)
                    Spacer()
                    Text("\(appViewModel.completedMissions.count)")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.success)
                }
                Text("Goals you've crushed this week 🎉")
                    .font(AppFonts.nunito(13, weight: .semibold))
                    .foregroundColor(AppTheme.subtitle)
            }
            
            ForEach(appViewModel.completedMissions) { mission in
                completedMissionCard(mission: mission)
            }
        }
    }
    
    private func completedMissionCard(mission: Mission) -> some View {
        let tint = missionAccent(mission.type)

        return HStack(spacing: 14) {
            // Checkmark with type color accent
            ZStack {
                Circle()
                    .fill(AppTheme.elevatedSurface)
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(tint.opacity(0.3), lineWidth: 2)
                    .frame(width: 44, height: 44)
                MaterialSymbol(name: "check_circle", size: 20)
                    .foregroundColor(tint)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(missionTypeLabel(mission.type))
                    .font(AppFonts.nunito(15, weight: .black))
                    .foregroundColor(AppTheme.title)
                HStack(spacing: 4) {
                    Text("\(mission.targetValue)")
                        .font(AppFonts.nunito(13, weight: .black))
                        .foregroundColor(tint)
                    Text(mission.type == .sessions ? "sessions" : mission.type == .minutes ? "min" : "kcal")
                        .font(AppFonts.nunito(13, weight: .semibold))
                        .foregroundColor(AppTheme.subtitle)
                }
            }
            
            Spacer()
            
            // Points earned badge
            HStack(spacing: 4) {
                MaterialSymbol(name: "star", size: 14)
                Text("+10")
                    .font(AppFonts.nunito(13, weight: .black))
            }
            .foregroundColor(AppTheme.primaryButtonPressed)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.cardGold.opacity(0.65))
            .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(missionAccentBackground(mission.type).opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.35), lineWidth: 1.2)
                )
        )
        .shadow(color: tint.opacity(0.16), radius: 4, x: 0, y: 2)
    }

    private func missionCard(mission: Mission) -> some View {
        let tint = missionAccent(mission.type)
        let background = missionAccentBackground(mission.type)
        let iconName = missionIconName(mission.type)
        
        let percent = Int(mission.progress * 100)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: 48, height: 48)
                MaterialSymbol(name: iconName, size: 22)
                    .foregroundColor(tint)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(missionTypeLabel(mission.type))
                        .font(AppFonts.nunito(15, weight: .black))
                        .foregroundColor(AppTheme.title)
                    Spacer()
                    Text("\(mission.progressValue)/\(mission.targetValue)")
                        .font(AppFonts.nunito(14, weight: .black))
                        .foregroundColor(tint)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(AppTheme.subtleSurface.opacity(0.42))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 999)
                            .fill(tint)
                            .frame(width: geometry.size.width * CGFloat(mission.progress), height: 8)
                    }
                }
                .frame(height: 8)
                
                Text("\(percent)% complete")
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(AppTheme.iconMuted)
            }
            
            Button(action: {
                Task {
                    await viewModel.onDeleteMission(mission.id)
                }
            }) {
                Circle()
                    .fill(AppTheme.primaryButton.opacity(0.18))
                    .frame(width: 36, height: 36)
                    .overlay(
                        MaterialSymbol(name: "delete_outline", size: 18)
                            .foregroundColor(AppTheme.primaryButtonPressed)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: missionCardColors(mission.type),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(missionCardBorder(mission.type), lineWidth: 1.2)
                )
        )
        .shadow(color: tint.opacity(0.14), radius: 8, x: 0, y: 4)
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
                .foregroundColor(AppTheme.title)
            Text("Add a goal to track your progress this week")
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(AppTheme.subtitle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var aiTypePopup: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showTypeSheet = false
                    }
                }

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showTypeSheet = false
                        }
                    }) {
                        Circle()
                            .fill(AppTheme.subtleSurface.opacity(0.5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                MaterialSymbol(name: "close", size: 16)
                                    .foregroundColor(AppTheme.muted)
                            )
                    }
                }

                Text("Choose a goal type")
                    .font(AppFonts.quicksand(20, weight: .bold))
                    .foregroundColor(AppTheme.title)

                Text("AI will set the target for you")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(AppTheme.subtitle)

                VStack(spacing: 12) {
                    aiTypeButton(
                        .sessions,
                        icon: missionIconName(.sessions),
                        title: "Workout Sessions",
                        subtitle: "Track number of workouts",
                        color: missionAccent(.sessions),
                        isDisabled: isTypeActive(.sessions)
                    )
                    aiTypeButton(
                        .minutes,
                        icon: missionIconName(.minutes),
                        title: "Active Minutes",
                        subtitle: "Track exercise duration",
                        color: missionAccent(.minutes),
                        isDisabled: isTypeActive(.minutes)
                    )
                    aiTypeButton(
                        .calories,
                        icon: missionIconName(.calories),
                        title: "Calories",
                        subtitle: "Track calories burned",
                        color: missionAccent(.calories),
                        isDisabled: isTypeActive(.calories)
                    )
                }
            }
            .padding(20)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }

    private func aiTypeButton(
        _ type: MissionType,
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isDisabled: Bool
    ) -> some View {
        Button(action: {
            guard !isDisabled else { return }
            showTypeSheet = false
            isCreating = true
            Task {
                if let error = await viewModel.onCreateAISingleMission(type) {
                    createErrorMessage = error
                    showCreateError = true
                }
                isCreating = false
            }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isDisabled ? 0.08 : 0.15))
                        .frame(width: 48, height: 48)
                    MaterialSymbol(name: icon, size: 24)
                        .foregroundColor(color.opacity(isDisabled ? 0.4 : 1))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.nunito(16, weight: .black))
                        .foregroundColor(AppTheme.title)
                    Text(isDisabled ? "Already active" : subtitle)
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(isDisabled ? AppTheme.iconMuted.opacity(0.7) : AppTheme.subtitle)
                }
                Spacer()
                MaterialSymbol(name: "auto_awesome", size: 20)
                    .foregroundColor(AppTheme.primaryButton.opacity(isDisabled ? 0.3 : 1))
            }
            .padding(14)
            .background(AppTheme.surface.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isCreating || isDisabled)
    }

    private func missionAccent(_ type: MissionType) -> Color {
        switch type {
        case .calories:
            return AppTheme.primaryButton
        case .minutes:
            return Color(hex: "#5E96E6")
        case .sessions:
            return AppTheme.success
        }
    }

    private func missionCardColors(_ type: MissionType) -> [Color] {
        switch type {
        case .calories:
            return [Color(hex: "#FFE9CD"), Color(hex: "#FFD7A8")]
        case .minutes:
            return [Color(hex: "#ECF4FF"), Color(hex: "#DCEAFF")]
        case .sessions:
            return [Color(hex: "#E8FCF3"), Color(hex: "#D1F5E7")]
        }
    }

    private func missionCardBorder(_ type: MissionType) -> Color {
        switch type {
        case .calories:
            return Color(hex: "#E7B063")
        case .minutes:
            return Color(hex: "#9FC2F7")
        case .sessions:
            return Color(hex: "#84DDB8")
        }
    }

    private func missionAccentBackground(_ type: MissionType) -> Color {
        switch type {
        case .calories:
            return AppTheme.cardGold.opacity(0.35)
        case .minutes:
            return Color(hex: "#EAF3FF")
        case .sessions:
            return AppTheme.success.opacity(0.16)
        }
    }

    private func missionIconName(_ type: MissionType) -> String {
        switch type {
        case .calories:
            return "local_fire_department"
        case .minutes:
            return "bolt"
        case .sessions:
            return "emoji_events"
        }
    }

    private func isTypeActive(_ type: MissionType) -> Bool {
        appViewModel.activeMissions.contains { $0.type == type }
    }
    
}
