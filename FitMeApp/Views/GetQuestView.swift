import SwiftUI

struct GetQuestView: View {
    let viewModel: GetQuestViewModel
    @State private var calories: Int = 1200
    @State private var minutes: Int = 150
    @State private var sessions: Int = 3
    @State private var showCalories: Bool = true
    @State private var showMinutes: Bool = true
    @State private var showSessions: Bool = true
    @State private var isLoading = false
    @State private var useAI = true

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                // Mode Selection
                HStack(spacing: 12) {
                    modeButton(title: "🧠 AI 추천", isSelected: useAI) {
                        useAI = true
                    }
                    modeButton(title: "✏️ 직접 설정", isSelected: !useAI) {
                        useAI = false
                    }
                }
                
                if useAI {
                    aiModeContent
                } else {
                    customModeContent
                }

                confirmButton

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Creating your mission...")
                        .font(AppFonts.plusJakarta(16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
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
            Text("Get a Quest")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    private func modeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(isSelected ? .white : Color(hex: "#3D3D3D"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "#FF8577") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? Color.clear : Color(hex: "#E5E7EB"), lineWidth: 1)
                )
        }
        .disabled(isLoading)
    }
    
    private var aiModeContent: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("🤖")
                    .font(.system(size: 48))
                Text("AI가 당신에게 맞는\n미션을 추천해드려요!")
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                    .multilineTextAlignment(.center)
                Text("운동 기록을 분석해서\n적절한 목표를 설정합니다")
                    .font(AppFonts.nunito(13, weight: .medium))
                    .foregroundColor(Color(hex: "#A8A29E"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    private var customModeContent: some View {
        VStack(spacing: 12) {
            if showCalories {
                goalCard(
                    title: "칼로리",
                    value: calories,
                    unit: "kcal",
                    onDecrease: { calories = max(100, calories - 100) },
                    onIncrease: { calories += 100 },
                    onDelete: { showCalories = false }
                )
            }
            if showMinutes {
                goalCard(
                    title: "운동 시간",
                    value: minutes,
                    unit: "분",
                    onDecrease: { minutes = max(10, minutes - 10) },
                    onIncrease: { minutes += 10 },
                    onDelete: { showMinutes = false }
                )
            }
            if showSessions {
                goalCard(
                    title: "세션 수",
                    value: sessions,
                    unit: "회",
                    onDecrease: { sessions = max(1, sessions - 1) },
                    onIncrease: { sessions += 1 },
                    onDelete: { showSessions = false }
                )
            }
            
            if !showCalories || !showMinutes || !showSessions {
                addGoalButton
            }
        }
    }
    
    private var addGoalButton: some View {
        Menu {
            if !showCalories {
                Button("칼로리 목표 추가") { showCalories = true }
            }
            if !showMinutes {
                Button("시간 목표 추가") { showMinutes = true }
            }
            if !showSessions {
                Button("세션 목표 추가") { showSessions = true }
            }
        } label: {
            HStack {
                MaterialSymbol(name: "add", size: 18)
                Text("목표 추가")
                    .font(AppFonts.nunito(14, weight: .bold))
            }
            .foregroundColor(Color(hex: "#FF8577"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#FFF1EE"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func goalCard(title: String, value: Int, unit: String, onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                HStack(spacing: 4) {
                    Text(formattedValue(value))
                        .font(AppFonts.nunito(18, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(AppFonts.nunito(11, weight: .bold))
                            .foregroundColor(Color(hex: "#A8A29E"))
                    }
                }
            }
            Spacer()
            Button(action: onDecrease) {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "remove", size: 18).foregroundColor(Color(hex: "#FF8577")))
            }
            .disabled(isLoading)
            Button(action: onIncrease) {
                Circle()
                    .fill(Color(hex: "#FF8577"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "add", size: 18).foregroundColor(.white))
            }
            .disabled(isLoading)
            Button(action: onDelete) {
                Circle()
                    .fill(Color(hex: "#FEE2E2"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "close", size: 16).foregroundColor(Color(hex: "#EF4444")))
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private func formattedValue(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    private var confirmButton: some View {
        Button {
            Task {
                isLoading = true
                if useAI {
                    await viewModel.onConfirmAI()
                } else {
                    // Create custom missions for enabled goals
                    if showCalories {
                        await viewModel.onConfirmCustom(.calories, .medium, calories)
                    }
                    if showMinutes {
                        await viewModel.onConfirmCustom(.minutes, .medium, minutes)
                    }
                    if showSessions {
                        await viewModel.onConfirmCustom(.sessions, .medium, sessions)
                    }
                }
                isLoading = false
            }
        } label: {
            Text(useAI ? "AI 미션 받기" : "목표 저장하기")
                .font(AppFonts.nunito(16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#FF8577"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(isLoading || (!useAI && !showCalories && !showMinutes && !showSessions))
    }
}
