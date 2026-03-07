import SwiftUI

// MARK: - Shared Components

struct OnboardingOptionCard: View {
    let label: String
    let icon: String
    let isSelected: Bool
    var description: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(icon)
                    .font(.system(size: 24))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(AppFonts.nunito(16, weight: .bold))
                        .foregroundColor(AppTheme.title)
                    if let description {
                        Text(description)
                            .font(AppFonts.nunito(12, weight: .regular))
                            .foregroundColor(AppTheme.subtitle)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.primaryButton)
                        .font(.system(size: 20))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(AppTheme.muted.opacity(0.4))
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? AppTheme.primaryButton.opacity(0.1)
                    : AppTheme.elevatedSurface
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isSelected ? AppTheme.cardBorderGold : AppTheme.border.opacity(0.3),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

struct StepperCard: View {
    let value: String
    let unit: String
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 24) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(canDecrease ? AppTheme.primaryButton : AppTheme.muted.opacity(0.3))
                }
                .disabled(!canDecrease)

                VStack(spacing: 2) {
                    Text(value)
                        .font(AppFonts.quicksand(56, weight: .bold))
                        .foregroundColor(AppTheme.title)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)
                        .monospacedDigit()

                    Text(unit)
                        .font(AppFonts.nunito(14, weight: .medium))
                        .foregroundColor(AppTheme.subtitle)
                }
                .frame(minWidth: 100)

                Button(action: onIncrease) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(canIncrease ? AppTheme.primaryButton : AppTheme.muted.opacity(0.3))
                }
                .disabled(!canIncrease)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 24)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Step 1: Sex

struct SexStepView: View {
    @Binding var selectedSex: BirthSex?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(BirthSex.allCases, id: \.self) { sex in
                    OnboardingOptionCard(
                        label: sex.displayLabel,
                        icon: sex.icon,
                        isSelected: selectedSex == sex,
                        action: { selectedSex = sex }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Step 2: Age

struct AgeStepView: View {
    @Binding var age: Int

    var body: some View {
        VStack(spacing: 20) {
            StepperCard(
                value: "\(age)",
                unit: "세",
                canDecrease: age > 15,
                canIncrease: age < 80,
                onDecrease: { if age > 15 { age -= 1 } },
                onIncrease: { if age < 80 { age += 1 } }
            )
            Text("15세 이상 80세 이하")
                .font(AppFonts.nunito(12, weight: .regular))
                .foregroundColor(AppTheme.muted)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Step 3: Body Stats

struct BodyStatsStepView: View {
    @Binding var heightCm: Double
    @Binding var weightKg: Double

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Height
                VStack(alignment: .leading, spacing: 8) {
                    Text("키")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                    HStack {
                        Button(action: { if heightCm > 100 { heightCm = max(100, heightCm - 0.5) } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(heightCm > 100 ? AppTheme.primaryButton : AppTheme.muted.opacity(0.3))
                        }
                        .disabled(heightCm <= 100)

                        Spacer()

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", heightCm))
                                .font(AppFonts.quicksand(36, weight: .bold))
                                .foregroundColor(AppTheme.title)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: heightCm)
                            Text("cm")
                                .font(AppFonts.nunito(16, weight: .medium))
                                .foregroundColor(AppTheme.subtitle)
                        }

                        Spacer()

                        Button(action: { if heightCm < 250 { heightCm = min(250, heightCm + 0.5) } }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(heightCm < 250 ? AppTheme.primaryButton : AppTheme.muted.opacity(0.3))
                        }
                        .disabled(heightCm >= 250)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
                    )
                }

                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    Text("체중")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                    HStack {
                        Button(action: { if weightKg > 30 { weightKg = max(30, weightKg - 0.5) } }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(weightKg > 30 ? AppTheme.primaryButton : AppTheme.muted.opacity(0.3))
                        }
                        .disabled(weightKg <= 30)

                        Spacer()

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", weightKg))
                                .font(AppFonts.quicksand(36, weight: .bold))
                                .foregroundColor(AppTheme.title)
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: weightKg)
                            Text("kg")
                                .font(AppFonts.nunito(16, weight: .medium))
                                .foregroundColor(AppTheme.subtitle)
                        }

                        Spacer()

                        Button(action: { if weightKg < 300 { weightKg = min(300, weightKg + 0.5) } }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(weightKg < 300 ? AppTheme.primaryButton : AppTheme.muted.opacity(0.3))
                        }
                        .disabled(weightKg >= 300)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Step 4: Experience

struct ExperienceStepView: View {
    @Binding var selectedLevel: ExperienceLevel?
    @Binding var selectedDuration: ExperienceDuration?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Level
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동 수준")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                    HStack(spacing: 10) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Button(action: { selectedLevel = level }) {
                                Text(level.displayLabel)
                                    .font(AppFonts.nunito(14, weight: .bold))
                                    .foregroundColor(selectedLevel == level ? .white : AppTheme.title)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedLevel == level
                                            ? AnyView(AppTheme.primaryButtonGradient)
                                            : AnyView(AppTheme.elevatedSurface)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(
                                                selectedLevel == level ? Color.clear : AppTheme.border.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.15), value: selectedLevel)
                        }
                    }
                }

                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("운동 기간")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ExperienceDuration.allCases, id: \.self) { duration in
                            Button(action: { selectedDuration = duration }) {
                                Text(duration.displayLabel)
                                    .font(AppFonts.nunito(13, weight: .bold))
                                    .foregroundColor(selectedDuration == duration ? .white : AppTheme.title)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedDuration == duration
                                            ? AnyView(AppTheme.primaryButtonGradient)
                                            : AnyView(AppTheme.elevatedSurface)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(
                                                selectedDuration == duration ? Color.clear : AppTheme.border.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.15), value: selectedDuration)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Step 5: Goal

struct GoalStepView: View {
    @Binding var selectedGoal: WorkoutGoal?

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(WorkoutGoal.allCases, id: \.self) { goal in
                    Button(action: { selectedGoal = goal }) {
                        VStack(spacing: 10) {
                            Text(goal.icon)
                                .font(.system(size: 32))
                            Text(goal.displayLabel)
                                .font(AppFonts.nunito(15, weight: .bold))
                                .foregroundColor(AppTheme.title)
                            Text(goal.description)
                                .font(AppFonts.nunito(11, weight: .regular))
                                .foregroundColor(AppTheme.subtitle)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 10)
                        .background(
                            selectedGoal == goal
                                ? AppTheme.primaryButton.opacity(0.1)
                                : AppTheme.elevatedSurface
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    selectedGoal == goal ? AppTheme.cardBorderGold : AppTheme.border.opacity(0.3),
                                    lineWidth: selectedGoal == goal ? 1.5 : 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeOut(duration: 0.15), value: selectedGoal)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Step 6: Location

struct LocationStepView: View {
    @Binding var selectedLocation: WorkoutLocation?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(WorkoutLocation.allCases, id: \.self) { loc in
                    OnboardingOptionCard(
                        label: loc.displayLabel,
                        icon: loc.icon,
                        isSelected: selectedLocation == loc,
                        action: { selectedLocation = loc }
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Step 7: Equipment

private let equipmentOptions: [(id: String, label: String, icon: String)] = [
    ("bodyweight",      "맨몸",    "🤸"),
    ("dumbbell",        "덤벨",    "💪"),
    ("kettlebell",      "케틀벨",  "🔔"),
    ("resistance_band", "밴드",    "🔗"),
    ("pull_up_bar",     "철봉",    "🏃"),
    ("jump_rope",       "줄넘기",  "🪢"),
]

struct EquipmentStepView: View {
    @Binding var selectedEquipment: Set<String>

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("집에 있는 기구를 선택하세요")
                    .font(AppFonts.nunito(12, weight: .regular))
                    .foregroundColor(AppTheme.muted)
                    .padding(.bottom, 4)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(equipmentOptions, id: \.id) { item in
                        Button(action: {
                            if selectedEquipment.contains(item.id) {
                                selectedEquipment.remove(item.id)
                            } else {
                                selectedEquipment.insert(item.id)
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(item.icon)
                                    .font(.system(size: 26))
                                Text(item.label)
                                    .font(AppFonts.nunito(14, weight: .bold))
                                    .foregroundColor(AppTheme.title)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedEquipment.contains(item.id)
                                    ? AppTheme.primaryButton.opacity(0.12)
                                    : AppTheme.elevatedSurface
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        selectedEquipment.contains(item.id) ? AppTheme.cardBorderGold : AppTheme.border.opacity(0.3),
                                        lineWidth: selectedEquipment.contains(item.id) ? 1.5 : 1
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.15), value: selectedEquipment.contains(item.id))
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Step 8: Schedule

struct ScheduleStepView: View {
    @Binding var weeklyDays: Int
    @Binding var sessionMinutes: Int

    let sessionOptions = [20, 35, 50]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weekly days
                VStack(alignment: .leading, spacing: 10) {
                    Text("주간 운동 횟수")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                    StepperCard(
                        value: "\(weeklyDays)",
                        unit: "회 / 주",
                        canDecrease: weeklyDays > 1,
                        canIncrease: weeklyDays < 7,
                        onDecrease: { if weeklyDays > 1 { weeklyDays -= 1 } },
                        onIncrease: { if weeklyDays < 7 { weeklyDays += 1 } }
                    )
                }

                // Session duration
                VStack(alignment: .leading, spacing: 10) {
                    Text("세션 시간")
                        .font(AppFonts.nunito(14, weight: .bold))
                        .foregroundColor(AppTheme.subtitle)
                    HStack(spacing: 10) {
                        ForEach(sessionOptions, id: \.self) { minutes in
                            Button(action: { sessionMinutes = minutes }) {
                                VStack(spacing: 4) {
                                    Text("\(minutes)")
                                        .font(AppFonts.quicksand(24, weight: .bold))
                                        .foregroundColor(sessionMinutes == minutes ? .white : AppTheme.title)
                                    Text("분")
                                        .font(AppFonts.nunito(12, weight: .medium))
                                        .foregroundColor(sessionMinutes == minutes ? .white.opacity(0.85) : AppTheme.subtitle)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    sessionMinutes == minutes
                                        ? AnyView(AppTheme.primaryButtonGradient)
                                        : AnyView(AppTheme.elevatedSurface)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            sessionMinutes == minutes ? Color.clear : AppTheme.border.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .animation(.easeOut(duration: 0.15), value: sessionMinutes)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
