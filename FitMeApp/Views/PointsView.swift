import SwiftUI

struct PointsView: View {
    @ObservedObject var viewModel: PointsViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Total Points Card
                        totalPointsCard
                        
                        // Stats Grid
                        statsSection
                        
                        // Point Rules
                        rulesSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            await viewModel.loadData()
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
            Text("Points")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
    
    private var totalPointsCard: some View {
        VStack(spacing: 16) {
            // Trophy icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color(hex: "#FFD700").opacity(0.4), radius: 12, x: 0, y: 6)
                
                Text("🏆")
                    .font(.system(size: 40))
            }
            
            VStack(spacing: 4) {
                Text("Total Points")
                    .font(AppFonts.nunito(14, weight: .bold))
                    .foregroundColor(Color(hex: "#78716C"))
                
                Text("\(viewModel.data.totalPoints)")
                    .font(AppFonts.nunito(48, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                
                Text("pts")
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(Color(hex: "#A8A29E"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Breakdown")
                .font(AppFonts.quicksand(18, weight: .heavy))
                .foregroundColor(Color(hex: "#3D3D3D"))
            
            HStack(spacing: 12) {
                statCard(
                    icon: "fitness_center",
                    iconColor: "#FF8577",
                    title: "Workouts",
                    count: viewModel.data.completedWorkouts,
                    points: viewModel.data.completedWorkouts * 5,
                    unit: "× 5pts"
                )
                
                statCard(
                    icon: "flag",
                    iconColor: "#34D399",
                    title: "Missions",
                    count: viewModel.data.completedMissions,
                    points: viewModel.data.completedMissions * 10,
                    unit: "× 10pts"
                )
            }
        }
    }
    
    private func statCard(icon: String, iconColor: String, title: String, count: Int, points: Int, unit: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: iconColor).opacity(0.15))
                    .frame(width: 48, height: 48)
                MaterialSymbol(name: icon, size: 24)
                    .foregroundColor(Color(hex: iconColor))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(AppFonts.nunito(12, weight: .bold))
                    .foregroundColor(Color(hex: "#78716C"))
                
                Text("\(count)")
                    .font(AppFonts.nunito(28, weight: .black))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                
                Text(unit)
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(Color(hex: "#A8A29E"))
            }
            
            // Points earned
            Text("+\(points) pts")
                .font(AppFonts.nunito(14, weight: .black))
                .foregroundColor(Color(hex: iconColor))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: iconColor).opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to Earn Points")
                .font(AppFonts.quicksand(18, weight: .heavy))
                .foregroundColor(Color(hex: "#3D3D3D"))
            
            VStack(spacing: 10) {
                ruleRow(icon: "fitness_center", text: "Complete a workout", points: "+5")
                ruleRow(icon: "flag", text: "Complete a mission", points: "+10")
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    private func ruleRow(icon: String, text: String, points: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#F3F4F6"))
                    .frame(width: 36, height: 36)
                MaterialSymbol(name: icon, size: 18)
                    .foregroundColor(Color(hex: "#6B7280"))
            }
            
            Text(text)
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            
            Spacer()
            
            Text(points)
                .font(AppFonts.nunito(16, weight: .black))
                .foregroundColor(Color(hex: "#FF8577"))
        }
    }
}
