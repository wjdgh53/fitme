import SwiftUI

struct PersonalInfoView: View {
    @ObservedObject var viewModel: PersonalInfoViewModel

    var body: some View {
        ZStack {
            AppTheme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 8)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(AppTheme.primaryButton)
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(error)
                            .font(AppFonts.nunito(14, weight: .regular))
                            .foregroundColor(AppTheme.subtitle)
                            .multilineTextAlignment(.center)
                        Button("다시 시도") { viewModel.loadData() }
                            .font(AppFonts.nunito(15, weight: .bold))
                            .foregroundColor(AppTheme.primaryButton)
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                } else if let info = viewModel.info {
                    ScrollView {
                        VStack(spacing: 16) {
                            basicInfoSection(info)
                            experienceSection(info)
                            preferenceSection(info)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                } else {
                    Spacer()
                }
            }
        }
        .onAppear { viewModel.loadData() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if viewModel.isEditing {
                Button("취소") {
                    viewModel.isEditing = false
                }
                .font(AppFonts.nunito(15, weight: .semibold))
                .foregroundColor(AppTheme.subtitle)
                .frame(width: 52, height: 44)
            } else {
                Button(action: viewModel.onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.title)
                        .frame(width: 44, height: 44)
                }
            }

            Spacer()

            Text("내 프로필 정보")
                .font(AppFonts.quicksand(18, weight: .bold))
                .foregroundColor(AppTheme.title)

            Spacer()

            if viewModel.isEditing {
                Button(action: { viewModel.saveEdits() }) {
                    if viewModel.isSaving {
                        ProgressView().tint(AppTheme.primaryButton).frame(width: 52, height: 44)
                    } else {
                        Text("저장")
                            .font(AppFonts.nunito(15, weight: .bold))
                            .foregroundColor(AppTheme.primaryButton)
                            .frame(width: 52, height: 44)
                    }
                }
                .disabled(viewModel.isSaving)
            } else if viewModel.info != nil {
                Button(action: { viewModel.startEditing() }) {
                    Text("편집")
                        .font(AppFonts.nunito(15, weight: .bold))
                        .foregroundColor(AppTheme.primaryButton)
                        .frame(width: 52, height: 44)
                }
            } else {
                Color.clear.frame(width: 52, height: 44)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Sections

    private func basicInfoSection(_ info: PersonalInfoResponse) -> some View {
        sectionCard(title: "기본 정보", icon: "person") {
            infoRow(label: "성별", value: sexDisplay(info.birthSex))
            if viewModel.isEditing {
                editStepperRow(label: "나이", value: "\(viewModel.editAge)세",
                    onDecrease: { if viewModel.editAge > 15 { viewModel.editAge -= 1 } },
                    onIncrease: { if viewModel.editAge < 80 { viewModel.editAge += 1 } })
                editStepperRow(label: "키",
                    value: String(format: "%.1f cm", viewModel.editHeightCm),
                    onDecrease: { if viewModel.editHeightCm > 100 { viewModel.editHeightCm = max(100, viewModel.editHeightCm - 0.5) } },
                    onIncrease: { if viewModel.editHeightCm < 250 { viewModel.editHeightCm = min(250, viewModel.editHeightCm + 0.5) } })
                editStepperRow(label: "체중",
                    value: String(format: "%.1f kg", viewModel.editWeightKg),
                    onDecrease: { if viewModel.editWeightKg > 30 { viewModel.editWeightKg = max(30, viewModel.editWeightKg - 0.5) } },
                    onIncrease: { if viewModel.editWeightKg < 300 { viewModel.editWeightKg = min(300, viewModel.editWeightKg + 0.5) } })
            } else {
                infoRow(label: "나이", value: info.age.map { "\($0)세" } ?? "-")
                infoRow(label: "키", value: info.heightCm.map { String(format: "%.1f cm", $0) } ?? "-")
                infoRow(label: "체중", value: info.weightKg.map { String(format: "%.1f kg", $0) } ?? "-")
            }
        }
    }

    private func experienceSection(_ info: PersonalInfoResponse) -> some View {
        sectionCard(title: "운동 경험", icon: "fitness_center") {
            infoRow(label: "레벨", value: levelDisplay(info.experienceLevel))
            infoRow(label: "경력", value: durationDisplay(info.experienceDuration))
            infoRow(label: "주간 횟수", value: info.weeklyTrainingDays.map { "\($0)회/주" } ?? "-")
            infoRow(label: "세션 시간", value: info.preferredSessionMinutes.map { "\($0)분" } ?? "-")
        }
    }

    private func preferenceSection(_ info: PersonalInfoResponse) -> some View {
        sectionCard(title: "운동 선호", icon: "tune") {
            infoRow(label: "목표", value: goalDisplay(info.goal))
            infoRow(label: "장소", value: locationDisplay(info.preferredLocation))
            infoRow(label: "장비", value: equipmentDisplay(info.equipment))
        }
    }

    // MARK: - Reusable Components

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                MaterialSymbol(name: icon, size: 20)
                    .foregroundColor(AppTheme.primaryButton)
                Text(title)
                    .font(AppFonts.quicksand(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }
            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.nunito(14, weight: .semibold))
                .foregroundColor(AppTheme.subtitle)
            Spacer()
            Text(value)
                .font(AppFonts.nunito(15, weight: .bold))
                .foregroundColor(AppTheme.title)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .overlay(Divider().background(AppTheme.border.opacity(0.15)), alignment: .bottom)
    }

    private func editStepperRow(label: String, value: String, onDecrease: @escaping () -> Void, onIncrease: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.nunito(14, weight: .semibold))
                .foregroundColor(AppTheme.subtitle)
            Spacer()
            HStack(spacing: 12) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primaryButton)
                }
                Text(value)
                    .font(AppFonts.nunito(15, weight: .bold))
                    .foregroundColor(AppTheme.title)
                    .frame(minWidth: 70, alignment: .center)
                    .contentTransition(.numericText())
                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primaryButton)
                }
            }
        }
        .padding(.vertical, 10)
        .overlay(Divider().background(AppTheme.border.opacity(0.15)), alignment: .bottom)
    }

    // MARK: - Display Helpers

    private func sexDisplay(_ raw: String?) -> String {
        switch raw {
        case "male": return "남성"
        case "female": return "여성"
        case "prefer_not_to_say": return "밝히지 않음"
        default: return "-"
        }
    }

    private func levelDisplay(_ raw: String?) -> String {
        switch raw {
        case "beginner": return "초보자"
        case "intermediate": return "중급자"
        case "advanced": return "고급자"
        default: return "-"
        }
    }

    private func durationDisplay(_ raw: String?) -> String {
        switch raw {
        case "less_than_6m": return "6개월 미만"
        case "6m_to_1y": return "6개월~1년"
        case "1y_to_3y": return "1~3년"
        case "over_3y": return "3년 이상"
        default: return "-"
        }
    }

    private func goalDisplay(_ raw: String?) -> String {
        switch raw {
        case "hypertrophy": return "근비대"
        case "strength": return "근력"
        case "fat_loss": return "다이어트"
        case "fitness": return "건강"
        case "balance": return "균형"
        default: return "-"
        }
    }

    private func locationDisplay(_ raw: String?) -> String {
        switch raw {
        case "home": return "홈 트레이닝"
        case "gym": return "헬스장"
        case "hybrid": return "둘 다"
        default: return "-"
        }
    }

    private func equipmentDisplay(_ items: [String]?) -> String {
        guard let items = items, !items.isEmpty else { return "-" }
        let map: [String: String] = [
            "barbell": "바벨",
            "dumbbell": "덤벨",
            "cable": "케이블",
            "machine": "머신",
            "kettlebell": "케틀벨",
            "resistance_band": "밴드",
            "pull_up_bar": "풀업바",
            "bodyweight": "맨몸"
        ]
        return items.compactMap { map[$0] ?? $0 }.joined(separator: ", ")
    }
}
