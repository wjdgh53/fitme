import SwiftUI

struct RestView: View {
    let viewModel: RestViewModel
    @State private var remainingSeconds: Int
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(viewModel: RestViewModel) {
        self.viewModel = viewModel
        _remainingSeconds = State(initialValue: viewModel.data.restSeconds)
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                VStack(spacing: 16) {
                    titleSection
                    restMediaSection
                    previousSetsSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 6)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomControls
        }
        .onReceive(timer) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            }
        }
    }

    private var header: some View {
        HStack {
            Button(action: viewModel.onBack) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(MaterialSymbol(name: "arrow_back", size: 20).foregroundColor(Color(hex: "#3D3D3D")))
                    .overlay(Circle().stroke(Color(hex: "#F0EAE4"), lineWidth: 1))
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var titleSection: some View {
        HStack {
            Text(viewModel.data.exerciseName)
                .font(AppFonts.nunito(28, weight: .heavy))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Text(viewModel.data.currentExerciseIndex)
                .font(AppFonts.nunito(18, weight: .bold))
                .foregroundColor(Color(hex: "#8B8B9B"))
        }
    }

    private var restMediaSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)

            AsyncImage(url: viewModel.data.videoURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.white
            }
            .frame(height: 190)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(Color.white.opacity(0.55).clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)))
            .overlay(
                Text(formattedTime)
                    .font(AppFonts.nunito(40, weight: .black))
                    .foregroundColor(Color(hex: "#FF8577"))
                    .monospacedDigit()
            )
            .padding(8)
        }
    }

    private var previousSetsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Set")
                Spacer()
                Text(viewModel.data.weightUnit.uppercased())
                Spacer()
                Text("Reps")
                Spacer()
                Text(" ")
            }
            .font(AppFonts.nunito(11, weight: .bold))
            .foregroundColor(Color(hex: "#A8A29E"))

            ForEach(viewModel.data.previousSets.indices, id: \.self) { index in
                let set = viewModel.data.previousSets[index]
                HStack {
                    Text("\(set.setIndex)")
                        .frame(width: 36)
                    Text(set.weight)
                        .frame(maxWidth: .infinity)
                    Text(set.reps)
                        .frame(maxWidth: .infinity)
                    MaterialSymbol(name: "check_circle", size: 20)
                        .foregroundColor(Color(hex: "#6EE7B7"))
                        .frame(width: 36)
                }
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
                .padding(.vertical, 8)
                .background(Color(hex: "#F5F5F4"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 4)
    }

    private var bottomControls: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white)
                .frame(width: 56, height: 56)
                .overlay(MaterialSymbol(name: "arrow_back", size: 26).foregroundColor(Color(hex: "#C4C4D0")))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

            Button(action: viewModel.onContinue) {
                Text("Complete Rest")
                    .font(AppFonts.nunito(18, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color(hex: "#34D399"))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: "#34D399").opacity(0.3), radius: 16, x: 0, y: 8)
            }

            Circle()
                .fill(Color.white)
                .frame(width: 56, height: 56)
                .overlay(MaterialSymbol(name: "arrow_forward", size: 26).foregroundColor(Color(hex: "#C4C4D0")))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.95).padding(.bottom, AppLayout.tabBarHeight))
        .overlay(Rectangle().fill(Color(hex: "#F0EAE4")).frame(height: 1), alignment: .top)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
