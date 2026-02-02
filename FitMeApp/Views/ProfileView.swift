import SwiftUI

struct ProfileView: View {
    let viewModel: ProfileViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    profileCard
                    settingsSection
                    logoutButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 140)
            }
        }
    }

    private var header: some View {
        HStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .frame(width: 48, height: 48)
                .overlay(MaterialSymbol(name: "arrow_back", size: 24).foregroundColor(Color(hex: "#3D3D3D")))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            Spacer()
            Text("My Profile")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Text("Edit")
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#FF8577"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .padding(.top, 10)
    }

    private var profileCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(Color(hex: "#FF8577"))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(3))
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(-3))
                    .overlay(
                        AsyncImage(url: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuAWpQUGB4n0IhGglX8s7RL_Kjom368cIzHm7pDIVvxKsmKRoua4qUzWAlcNXb6KRfaxZNUktl9NUU7GpfCNlB1OTscRNc20Wl93AzepaHhhjwPqT_8WIBYeR5Sfna3aaZV2TrF3SOnVG6HOmajy82UylZqcRgBl-TlIc-UoG6We9NVCZzPkuVR1Fmnc1wx2_xU4OX5sLG7cZdkTKVJ99J4guNNywBr9Z6D0AETcg9SRsWAglgV0ckWO4Q-SaQQkvYR_nN_ZYsWgRtA")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.white
                        }
                        .frame(width: 118, height: 118)
                        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                    )
                HStack(spacing: 4) {
                    MaterialSymbol(name: "check", size: 12)
                        .foregroundColor(Color(hex: "#2563EB"))
                    Text("PRO")
                        .font(AppFonts.nunito(10, weight: .bold))
                        .foregroundColor(Color(hex: "#2563EB"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#DBEAFE"))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "#FFF8F0"), lineWidth: 3))
                .offset(x: 8, y: -8)
            }

            Text("Kim Min-su")
                .font(AppFonts.quicksand(24, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Text("@minsu_fitness")
                .font(AppFonts.nunito(14, weight: .medium))
                .foregroundColor(Color(hex: "#78716C"))

            HStack(spacing: 8) {
                Text("🔥")
                Text("On a roll!")
                    .font(AppFonts.nunito(13, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                MaterialSymbol(name: "settings", size: 20)
                    .foregroundColor(Color(hex: "#FF8577"))
                Text("Settings")
                    .font(AppFonts.quicksand(18, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }

            VStack(spacing: 6) {
                settingsRow(title: "My Goals", icon: "flag", action: viewModel.onMyGoals)
                pointsRow
                settingsRow(title: "App Settings", icon: "tune", action: viewModel.onAppSettings)
                settingsRow(title: "Help Center", icon: "help", action: viewModel.onHelpCenter)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private var pointsRow: some View {
        Button(action: viewModel.onPoints) {
            HStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700").opacity(0.3), Color(hex: "#FFA500").opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(Text("🏆").font(.system(size: 22)))
                
                Text("Points")
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                
                Spacer()
                
                // Points badge
                Text("\(viewModel.totalPoints) pts")
                    .font(AppFonts.nunito(14, weight: .black))
                    .foregroundColor(Color(hex: "#FF8577"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#FF8577").opacity(0.1))
                    .clipShape(Capsule())
                
                MaterialSymbol(name: "chevron_right", size: 20)
                    .foregroundColor(Color(hex: "#78716C"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
    
    private func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: "#F1F5F9"))
                    .frame(width: 48, height: 48)
                    .overlay(MaterialSymbol(name: icon, size: 22).foregroundColor(Color(hex: "#78716C")))
                Text(title)
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                MaterialSymbol(name: "chevron_right", size: 20)
                    .foregroundColor(Color(hex: "#78716C"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var logoutButton: some View {
        Button(action: {}) {
            Text("Log Out")
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#78716C"))
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(Color(hex: "#78716C").opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
        }
    }
}
