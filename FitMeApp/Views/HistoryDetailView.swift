import SwiftUI

struct HistoryDetailView: View {
    let viewModel: HistoryDetailViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    summaryGrid
                    aiNote
                    exerciseSection
                    tricepsSection
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 160)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .overlay(MaterialSymbol(name: "arrow_back_ios_new", size: 20).foregroundColor(Color(hex: "#3D3D3D")))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
            Spacer()
            Text(viewModel.data.dateTitle)
                .font(AppFonts.nunito(20, weight: .heavy))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Button(action: {}) {
                Text("Edit")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#FF8577"))
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 6)
    }

    private var summaryGrid: some View {
        HStack(spacing: 12) {
            summaryCard(title: "Time", value: viewModel.data.time, unit: "m", icon: "timer", color: "#60A5FA")
            summaryCard(title: "Volume", value: viewModel.data.volume, unit: "t", icon: "fitness_center", color: "#6EE7B7")
            summaryCard(title: "Sets", value: viewModel.data.sets, unit: "", icon: "format_list_bulleted", color: "#A78BFA")
        }
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, color: String) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hex: color).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(MaterialSymbol(name: icon, size: 22).foregroundColor(Color(hex: color)))
            Text(title.uppercased())
                .font(AppFonts.nunito(10, weight: .bold))
                .tracking(1)
                .foregroundColor(Color(hex: "#78716C"))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppFonts.nunito(20, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.nunito(12, weight: .bold))
                        .foregroundColor(Color(hex: "#78716C"))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private var aiNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "#FCD34D"))
                .frame(width: 48, height: 48)
                .overlay(MaterialSymbol(name: "sentiment_very_satisfied", size: 28).foregroundColor(.white))
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("FitCoach AI")
                        .font(AppFonts.nunito(12, weight: .black))
                        .foregroundColor(Color(hex: "#FF8577"))
                    MaterialSymbol(name: "auto_awesome", size: 16)
                        .foregroundColor(Color(hex: "#FF8577"))
                }
                Text(viewModel.data.aiNote)
                    .font(AppFonts.nunito(13, weight: .bold))
                    .foregroundColor(Color(hex: "#78716C"))
                    .lineSpacing(2)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .padding(.top, 8)
    }

    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chest Day")
                    .font(AppFonts.nunito(20, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("3 exercises")
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(Color(hex: "#FF8577"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FF8577").opacity(0.1))
                    .clipShape(Capsule())
            }
            exerciseCard(title: "Bench Press", badge: "BEST", tag: "Barbell • Compound", sets: [("60", "12"), ("65", "10"), ("70", "8")])
            exerciseCard(title: "Incline DB Press", badge: nil, tag: "Dumbbell • Upper Chest", sets: [("25", "12"), ("28", "10")])
        }
    }

    private var tricepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Triceps")
                    .font(AppFonts.nunito(20, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("2 exercises")
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(Color(hex: "#7C3AED"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#E9D5FF"))
                    .clipShape(Capsule())
            }
            exerciseCard(title: "Cable Pushdown", badge: nil, tag: "Cable • Isolation", sets: [("30", "15")])
        }
    }

    private func exerciseCard(title: String, badge: String?, tag: String, sets: [(String, String)]) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#FFF8F0"))
                    .frame(width: 56, height: 56)
                    .overlay(MaterialSymbol(name: "exercise", size: 24).foregroundColor(Color(hex: "#FF8577")))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(AppFonts.nunito(18, weight: .bold))
                            .foregroundColor(Color(hex: "#3D3D3D"))
                        if let badge = badge {
                            Text(badge)
                                .font(AppFonts.nunito(9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#FCD34D"))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    Text(tag)
                        .font(AppFonts.nunito(11, weight: .bold))
                        .foregroundColor(Color(hex: "#A8A29E"))
                }
                Spacer()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Set")
                    Spacer()
                    Text("Kg")
                    Spacer()
                    Text("Reps")
                    Spacer()
                    Text(" ")
                }
                .font(AppFonts.nunito(11, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))

                ForEach(sets.indices, id: \.self) { index in
                    let set = sets[index]
                    HStack {
                        Text("\(index + 1)")
                            .frame(width: 36)
                        Text(set.0)
                            .frame(maxWidth: .infinity)
                        Text(set.1)
                            .frame(maxWidth: .infinity)
                        MaterialSymbol(name: "check_circle", size: 20)
                            .foregroundColor(Color(hex: "#6EE7B7"))
                            .frame(width: 36)
                    }
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                    .padding(.vertical, 8)
                    .background(Color(hex: index == 2 && badge != nil ? "#FF8577" : "#F5F5F4").opacity(index == 2 && badge != nil ? 0.1 : 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.onShare) {
                HStack(spacing: 6) {
                    MaterialSymbol(name: "share", size: 18)
                    Text("Share")
                        .font(AppFonts.nunito(16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#FF8577"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color(hex: "#FF8577").opacity(0.25), radius: 10, x: 0, y: 5)
            }

            Button(action: viewModel.onHome) {
                HStack(spacing: 6) {
                    MaterialSymbol(name: "home", size: 18)
                    Text("Home")
                        .font(AppFonts.nunito(16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#22C55E"))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color(hex: "#22C55E").opacity(0.25), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.top, 4)
    }
}
