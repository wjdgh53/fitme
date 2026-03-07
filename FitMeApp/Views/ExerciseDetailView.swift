import SwiftUI

struct ExerciseDetailView: View {
    let viewModel: ExerciseDetailViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroSection
                    infoGrid
                    howToSection
                    musclesSection
                    suggestionsSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 200)
            }

            startButton
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack(spacing: 12) {
                ZStack(alignment: .top) {
                    AsyncImage(url: viewModel.data.heroURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.white
                    }
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                    .overlay(LinearGradient(colors: [Color.white, Color.white.opacity(0.1), Color.clear], startPoint: .bottom, endPoint: .top))

                    HStack {
                        Button(action: viewModel.onBack) {
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 48, height: 48)
                                .overlay(MaterialSymbol(name: "arrow_back", size: 24).foregroundColor(Color(hex: "#3D3D3D")))
                        }
                        Spacer()
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 48, height: 48)
                            .overlay(MaterialSymbol(name: "favorite", size: 24).foregroundColor(Color(hex: "#FF8577")))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        pill(text: "Strength", color: "#FF8577", textColor: .white, rotation: -2)
                        pill(text: "120 cal", color: "#FCD34D", textColor: Color(hex: "#3D3D3D"), rotation: 1, icon: "local_fire_department")
                        pill(text: "15 min", color: "#6EE7B7", textColor: .white, rotation: -1, icon: "timer")
                    }
                    Text(viewModel.data.title)
                        .font(AppFonts.quicksand(28, weight: .heavy))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                        .multilineTextAlignment(.center)
                    Text(viewModel.data.description)
                        .font(AppFonts.nunito(15, weight: .medium))
                        .foregroundColor(Color(hex: "#78716C"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private func pill(text: String, color: String, textColor: Color, rotation: Double, icon: String? = nil) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
                MaterialSymbol(name: icon, size: 18)
            }
            Text(text)
        }
        .font(AppFonts.nunito(14, weight: .bold))
        .foregroundColor(textColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: color))
        .clipShape(Capsule())
        .rotationEffect(.degrees(rotation))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    private var infoGrid: some View {
        HStack(spacing: 12) {
            infoCard(title: "Barbell", icon: "fitness_center", color: "#3B82F6")
            infoCard(title: "Compound", icon: "grid_view", color: "#A855F7")
            infoCard(title: "Chest", icon: "monitor_heart", color: "#FF8577")
            infoCard(title: "Push", icon: "accessibility_new", color: "#F59E0B")
        }
    }

    private func infoCard(title: String, icon: String, color: String) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color(hex: color).opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(MaterialSymbol(name: icon, size: 22).foregroundColor(Color(hex: color)))
            Text(title)
                .font(AppFonts.quicksand(11, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var howToSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#FF8577"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "info", size: 18).foregroundColor(.white))
                    .rotationEffect(.degrees(3))
                Text("How to do it")
                    .font(AppFonts.quicksand(20, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }

            VStack(alignment: .leading, spacing: 18) {
                stepRow(number: "1", title: "Get Ready", body: "Lie back on the bench. Grip the bar wide, lift it off the rack, and hold it steady above you.", color: "#FF8577")
                stepRow(number: "2", title: "Lower Slowly", body: "Breathe in and lower the bar slowly until it gently touches the middle of your chest.", color: "#6EE7B7")
                stepRow(number: "3", title: "Push it Up!", body: "Pause briefly, then breathe out as you push the bar back up. Use those chest muscles!", color: "#FCD34D")
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color(hex: "#F8FAFC"), lineWidth: 2))
        }
    }

    private func stepRow(number: String, title: String, body: String, color: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 32, height: 32)
                .overlay(Text(number).font(AppFonts.nunito(14, weight: .bold)).foregroundColor(color == "#FCD34D" ? Color(hex: "#3D3D3D") : .white))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.quicksand(16, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text(body)
                    .font(AppFonts.nunito(13, weight: .medium))
                    .foregroundColor(Color(hex: "#78716C"))
            }
        }
    }

    private var musclesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "#6EE7B7"))
                    .frame(width: 32, height: 32)
                    .overlay(MaterialSymbol(name: "body_system", size: 18).foregroundColor(.white))
                    .rotationEffect(.degrees(-2))
                Text("Muscles Working")
                    .font(AppFonts.quicksand(20, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
            }

            VStack(spacing: 10) {
                muscleRow(title: "Chest Muscles", subtitle: "Main Focus", progress: 0.9, color: "#FF8577")
                muscleRow(title: "Shoulders", subtitle: "Supporting", progress: 0.6, color: "#6EE7B7")
                muscleRow(title: "Triceps", subtitle: "Supporting", progress: 0.45, color: "#FCD34D")
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color(hex: "#F8FAFC"), lineWidth: 2))
        }
    }

    private func muscleRow(title: String, subtitle: String, progress: Double, color: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white)
                .frame(width: 48, height: 48)
                .overlay(MaterialSymbol(name: "body_system", size: 24).foregroundColor(subtitle == "Main Focus" ? Color(hex: color) : Color(hex: "#78716C")))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.quicksand(14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Text(subtitle)
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(subtitle == "Main Focus" ? Color(hex: color) : Color(hex: "#78716C"))
                    .padding(.horizontal, subtitle == "Main Focus" ? 8 : 0)
                    .padding(.vertical, subtitle == "Main Focus" ? 2 : 0)
                    .background(subtitle == "Main Focus" ? Color(hex: color).opacity(0.1) : Color.clear)
                    .clipShape(Capsule())
            }
            Spacer()
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "#E5E7EB"))
                    .frame(width: 60, height: 8)
                Capsule()
                    .fill(Color(hex: color))
                    .frame(width: 60 * progress, height: 8)
            }
        }
        .padding(10)
        .background(Color(hex: "#F8FAFC"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Try These Too!")
                    .font(AppFonts.quicksand(20, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                Spacer()
                Text("View all")
                    .font(AppFonts.nunito(11, weight: .bold))
                    .foregroundColor(Color(hex: "#FF8577"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#FF8577").opacity(0.1))
                    .clipShape(Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    suggestionCard(title: "Incline Dumbbell", subtitle: "Chest builder", tag: "Strength", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBsqDRaMg7FTR_LGT_9JzcroYrQXb67PIV5t9yyEPbzu3q8nrKbiJ8dPR2HzUD6j_1junsxezQXD8719kxNEVMPE2hEOIpfpsAfIwrUZmO_iEGfXo1Pzdhq33CIU19yirzLs4qAgcU9vfoqYtRzbCNIAkd6mxl6_6JxtPKGEbCFZsduCCi18u7fKIQa-KGOuTdgZAyEpcHKEU-OVALjFs2-UoAUWvWiOPs6_oaQiNnfz8-n1L2q0pfjr2o6o-2wFxH89O6jWjLkxWY")!)
                    suggestionCard(title: "Classic Push Ups", subtitle: "Bodyweight fun", tag: "Basics", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuBdVXhM9DdRQuJuW9ErzImxX1-yBNGMf-kWWN_d_tzPZAAxAC__EML_U3sgu30YwAtoPWWuf-Im8aH7gX2utpQnuVW4yoWRNhocMy8lbIzUMJoPxBkCRlDQZwllaETGNR6UzttNo5L1JxIIcu-ExxM1bSiolkPrraClDOAThn-wnEM_zILlFNUOI5lxRLRDyuW8gq_Mw83bx13FPWEeHHBTrWPiNv0mErnodLmxb6Uo0oeM0alRT18_NIFdnJQH25f6RzSycW5S8dw")!)
                    suggestionCard(title: "Cable Crossover", subtitle: "Sculpting", tag: "Isolation", imageURL: URL(string: "https://lh3.googleusercontent.com/aida-public/AB6AXuCIfYF7KYpMuFyeU7EkqVIxYBMV-ABJkWsvKzOrdupLVperM_qyktI3JMGcUA1SZoVNxLKa6zgUf8_VIsOCSIeGHCJUnVJxt8f3VgdjlyrqNRbYrJc6jAI4OmfRDW6jYK6fAMmQYsieI2GVqvzOFQI0hwQzO1PgCqNIjYHzN4TaIOu1eD2SRIBu0FItz1xYPnZNzFyUxQsm116q__m9WLYC3I8qhpGdjXLS2bXGIyWrUdDC6T1E7xGkBT4Dk4Q5zH2MOyMb-UIf9cI")!)
                }
            }
        }
    }

    private func suggestionCard(title: String, subtitle: String, tag: String, imageURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.white
                }
                .frame(width: 176, height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white, lineWidth: 2))

                Text(tag)
                    .font(AppFonts.nunito(10, weight: .bold))
                    .foregroundColor(Color(hex: "#3D3D3D"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(8)
            }
            Text(title)
                .font(AppFonts.quicksand(14, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Text(subtitle)
                .font(AppFonts.nunito(12, weight: .medium))
                .foregroundColor(Color(hex: "#78716C"))
        }
        .frame(width: 176)
    }

    private var startButton: some View {
        VStack(spacing: 0) {
            Button(action: viewModel.onStart) {
                HStack(spacing: 8) {
                    MaterialSymbol(name: "play_circle", size: 22)
                    Text("Start Workout!")
                        .font(AppFonts.quicksand(18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "#3D3D3D"))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color(hex: "#1F2937"), lineWidth: 4).offset(y: 2))
                .shadow(color: Color(hex: "#FF8577").opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
        .padding(.bottom, AppLayout.tabBarHeight - 6)
    }
}
