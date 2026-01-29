import SwiftUI

struct HelpCenterView: View {
    let viewModel: HelpCenterViewModel

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F0")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                VStack(spacing: 8) {
                    Text("Help Center")
                        .font(AppFonts.nunito(18, weight: .black))
                        .foregroundColor(Color(hex: "#3D3D3D"))
                    Text("We’re building this space with FAQs, guides, and support.")
                        .font(AppFonts.nunito(13, weight: .bold))
                        .foregroundColor(Color(hex: "#A8A29E"))
                        .multilineTextAlignment(.center)
                }
                .padding(18)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
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
            Text("Help Center")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(Color(hex: "#3D3D3D"))
            Spacer()
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
}
