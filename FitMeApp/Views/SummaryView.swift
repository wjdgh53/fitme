import SwiftUI

struct SummaryView: View {
    let viewModel: SummaryViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Animation
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 64))
                    Text("Workout Complete!")
                        .font(AppFonts.nunito(28, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    Text("Great job! You crushed it!")
                        .font(AppFonts.nunito(16, weight: .semibold))
                        .foregroundColor(Color(hex: "#78716C"))
                }
                .padding(.top, 48)
                
                // Summary Stats
                if let plan = viewModel.data.plan {
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            statCard(icon: "timer", value: "\(plan.estimatedMinutes)", unit: "min", color: "#60A5FA")
                            statCard(icon: "local_fire_department", value: "\(plan.estimatedCalories)", unit: "kcal", color: "#FF8577")
                        }
                        
                        HStack(spacing: 20) {
                            statCard(icon: "fitness_center", value: "\(plan.exercises.count)", unit: "exercises", color: "#34D399")
                            statCard(icon: "repeat", value: "\(totalSets(plan))", unit: "sets", color: "#A78BFA")
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Done Button
                Button(action: viewModel.onFinish) {
                    Text("Done")
                        .font(AppFonts.nunito(18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FF8577"))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func totalSets(_ plan: WorkoutPlan) -> Int {
        plan.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    private func statCard(icon: String, value: String, unit: String, color: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: color).opacity(0.1))
                    .frame(width: 48, height: 48)
                MaterialSymbol(name: icon, size: 24)
                    .foregroundColor(Color(hex: color))
            }
            VStack(spacing: 2) {
                Text(value)
                    .font(AppFonts.nunito(24, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text(unit)
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#78716C"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
