import SwiftUI
import AVKit

struct HomeDashboardView: View {
    let viewModel: HomeDashboardViewModel
    @ObservedObject private var appViewModel: AppViewModel
    
    init(viewModel: HomeDashboardViewModel, appViewModel: AppViewModel) {
        self.viewModel = viewModel
        self.appViewModel = appViewModel
    }

    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 6) {
                heroCard
                Spacer(minLength: 0)
                startWorkoutButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 0)
            
            if viewModel.data.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .task {
            await viewModel.onRefresh()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            topRow
            weeklyGoalsSection
            mascotBlock
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
    }

    private var topRow: some View {
        HStack(spacing: 10) {
            AvatarImageView(imageData: appViewModel.profileImageData,
                            imageURL: viewModel.data.profileImageURL,
                            size: 54,
                            cornerRadius: 27) {
                Circle().fill(Color.white)
            }
            Text("Hey, \(viewModel.data.userName)")
                .font(AppFonts.plusJakarta(27, weight: .bold))
                .foregroundColor(AppTheme.title)
            Spacer()
            Text(viewModel.data.rank)
                .font(AppFonts.plusJakarta(20, weight: .bold))
                .foregroundColor(AppTheme.title)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.cardGold.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(AppTheme.cardBorderGold.opacity(0.55), lineWidth: 1))
        }
        .padding(.bottom, 4)
        .motionEntry(index: 0)
    }

    private var weeklyGoalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK'S GOALS")
                .font(AppFonts.plusJakarta(11, weight: .bold))
                .foregroundColor(AppTheme.subtitle)
                .kerning(1.2)
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    if index < appViewModel.activeMissions.count {
                        let mission = appViewModel.activeMissions[index]
                        weeklyGoalCard(mission: mission)
                            .motionEntry(index: index + 1)
                    } else {
                        weeklyGoalPlaceholder
                            .motionEntry(index: index + 1)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onOpenWeeklyGoals()
        }
    }
    
    private func weeklyGoalCard(mission: Mission) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(missionDisplayText(mission))
                .font(AppFonts.plusJakarta(16, weight: .bold))
                .foregroundColor(AppTheme.title)
            Text(mission.displayTitle.uppercased())
                .font(AppFonts.nunito(10, weight: .bold))
                .foregroundColor(AppTheme.subtitle)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(10)
        .background(AppTheme.cardGold.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func missionDisplayText(_ mission: Mission) -> String {
        let progress = mission.progressValue
        let target = mission.targetValue
        switch mission.type {
        case .calories:
            return "\(progress) / \(target)kcal"
        case .minutes:
            return "\(progress) / \(target)m"
        case .sessions:
            return "\(progress)/\(target)"
        }
    }

    private var weeklyGoalPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("--")
                .font(AppFonts.plusJakarta(16, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
            Text("NEW")
                .font(AppFonts.nunito(10, weight: .bold))
                .foregroundColor(Color(hex: "#A8A29E"))
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .padding(10)
        .background(AppTheme.cardGold.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var mascotBlock: some View {
        ZStack {
            LoopingVideoView(resourceName: "moonbear", resourceType: "mp4")
                .frame(width: 340, height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .motionEntry(index: 4)
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private var startWorkoutButton: some View {
        Button(action: viewModel.onStartWorkout) {
            Text("Start Workout")
                .font(AppFonts.plusJakarta(17, weight: .bold))
                .foregroundColor(AppTheme.primaryButtonText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.primaryButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .motionPressable(haptic: true)
    }
}

private struct LoopingVideoView: UIViewRepresentable {
    let resourceName: String
    let resourceType: String

    func makeUIView(context: Context) -> UIView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceType) else {
            return view
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none

        let looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        context.coordinator.player = queuePlayer
        context.coordinator.looper = looper

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = .resizeAspect
        view.playerLayer = layer
        view.layer.addSublayer(layer)

        queuePlayer.play()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let view = uiView as? PlayerContainerView {
            view.playerLayer?.frame = view.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
    }
}

private final class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
