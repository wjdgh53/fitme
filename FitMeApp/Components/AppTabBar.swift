import SwiftUI

struct AppTabBar: View {
    let selectedTab: AppTab
    let isDisabled: Bool
    let onSelect: (AppTab) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(colors: [AppColors.cream.opacity(0.95), AppColors.cream.opacity(0)], startPoint: .bottom, endPoint: .top))
                .frame(height: 14)
            HStack {
                tabButton(title: "Home", icon: "home", tab: .home)
                tabButton(title: "Report", icon: "bar_chart", tab: .report)
                tabButton(title: "History", icon: "monitoring", tab: .history)
                tabButton(title: "Profile", icon: "person", tab: .profile)
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .background(AppColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: -6)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .opacity(isDisabled ? 0.4 : 1)
        .grayscale(isDisabled ? 1 : 0)
        .allowsHitTesting(!isDisabled)
    }

    private func tabButton(title: String, icon: String, tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: { onSelect(tab) }) {
            VStack(spacing: 4) {
                MaterialSymbol(name: icon, size: 26)
                    .foregroundColor(isSelected ? AppColors.peach : AppColors.textSub)
                Text(title)
                    .font(AppFonts.nunito(10, weight: .bold))
                    .foregroundColor(isSelected ? AppColors.peach : AppColors.textSub)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
