import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    let viewModel: ProfileViewModel
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var connectivity = ConnectivityStatus()
    @State private var showsWatchGuide = false

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isSelectingPhoto = false
    @State private var showsPhotoErrorAlert = false
    @State private var photoErrorMessage = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    profileCard
                    connectedSection
                    accountSection
                    settingsSection
                    logoutButton
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 140)
            }
        }
        .onAppear { connectivity.refresh() }
        .onChange(of: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            isSelectingPhoto = true
            Task {
                defer {
                    isSelectingPhoto = false
                    self.selectedPhotoItem = nil
                }
                do {
                    guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                        photoErrorMessage = "Couldn't load that photo. Please try another one."
                        showsPhotoErrorAlert = true
                        return
                    }
                    guard let image = UIImage(data: data) else {
                        photoErrorMessage = "That photo format isn't supported. Please try another one."
                        showsPhotoErrorAlert = true
                        return
                    }
                    let normalized = image.fitMe_downscaled(maxDimension: 720)
                    guard let saved = normalized.jpegData(compressionQuality: 0.86) else {
                        photoErrorMessage = "Couldn't process that photo. Please try another one."
                        showsPhotoErrorAlert = true
                        return
                    }
                    do {
                        try viewModel.setProfileImageData(saved)
                    } catch {
                        photoErrorMessage = "Couldn't save your profile photo. Please try again."
                        showsPhotoErrorAlert = true
                    }
                } catch {
                    photoErrorMessage = "Couldn't access your photo library. Please check permissions and try again."
                    showsPhotoErrorAlert = true
                    return
                }
            }
        }
        .alert("Couldn't update photo", isPresented: $showsPhotoErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(photoErrorMessage)
        }
    }

    private var header: some View {
        HStack {
            Text("My Profile")
                .font(AppFonts.quicksand(20, weight: .bold))
                .foregroundColor(AppTheme.title)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 2)
    }

    private var profileCard: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(AppTheme.primaryButton)
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(3))
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(AppTheme.elevatedSurface)
                    .frame(width: 118, height: 118)
                    .rotationEffect(.degrees(-3))
                    .overlay(
                        ZStack {
                            AvatarImageView(imageData: viewModel.profileImageData,
                                            imageURL: nil,
                                            size: 118,
                                            cornerRadius: 36) {
                                RoundedRectangle(cornerRadius: 36, style: .continuous)
                                    .fill(AppTheme.subtleSurface.opacity(0.35))
                                    .overlay(
                                        MaterialSymbol(name: "person", size: 44)
                                            .foregroundColor(AppTheme.muted)
                                    )
                            }
                            if isSelectingPhoto {
                                Color.white.opacity(0.65)
                                ProgressView()
                            }
                        }
                    )

                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.elevatedSurface)
                            .frame(width: 38, height: 38)
                            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 3)
                        Circle()
                            .fill(AppTheme.primaryButton)
                            .frame(width: 32, height: 32)
                        MaterialSymbol(name: "photo_camera", size: 18)
                            .foregroundColor(.white)
                    }
                    .contentShape(Circle())
                }
                .offset(x: 14, y: 96)
                HStack(spacing: 4) {
                    MaterialSymbol(name: "check", size: 12)
                        .foregroundColor(AppTheme.primaryButtonPressed)
                    Text("PRO")
                        .font(AppFonts.nunito(10, weight: .bold))
                        .foregroundColor(AppTheme.primaryButtonPressed)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppTheme.cardGold.opacity(0.45))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(AppTheme.appBackground, lineWidth: 3))
                .offset(x: 8, y: -8)
            }

            Text(authManager.displayName)
                .font(AppFonts.quicksand(24, weight: .bold))
                .foregroundColor(AppTheme.title)
            Text(authManager.isGuest ? "@guest" : (authManager.email ?? "@member"))
                .font(AppFonts.nunito(14, weight: .medium))
                .foregroundColor(AppTheme.subtitle)
        }
        .padding(.top, -4)
    }

    private var settingsSection: some View {
            VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                MaterialSymbol(name: "settings", size: 20)
                    .foregroundColor(AppTheme.primaryButton)
                Text("Settings")
                    .font(AppFonts.quicksand(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }

            VStack(spacing: 6) {
                settingsRow(title: "My Goals", icon: "flag", action: viewModel.onMyGoals)
                pointsRow
                settingsRow(title: "App Settings", icon: "tune", action: viewModel.onAppSettings)
                settingsRow(title: "Help Center", icon: "help", action: viewModel.onHelpCenter)
            }
            .padding(12)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                MaterialSymbol(name: "verified_user", size: 20)
                    .foregroundColor(AppTheme.primaryButton)
                Text("Account")
                    .font(AppFonts.quicksand(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }

            VStack(spacing: 6) {
                if authManager.isGuest {
                    settingsRow(title: "Protect with Apple", icon: "apple", action: {
                        Task { await authManager.signInWithApple() }
                    })
                    settingsRow(title: "Protect with Google", icon: "mail", action: {
                        Task { await authManager.signInWithGoogle() }
                    })
                } else {
                    connectedRow(title: "Member account", icon: "check_circle", isConnected: true)
                }
            }
            .padding(12)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                MaterialSymbol(name: "link", size: 20)
                    .foregroundColor(AppTheme.primaryButton)
                Text("Connected")
                    .font(AppFonts.quicksand(18, weight: .bold))
                    .foregroundColor(AppTheme.title)
            }

            VStack(spacing: 6) {
                connectedRow(
                    title: "Apple Health",
                    icon: "favorite",
                    isConnected: connectivity.isAppleHealthConnected,
                    action: {
                        connectivity.requestAppleHealthAuthorization()
                    }
                )
                connectedRow(
                    title: "Apple Watch",
                    icon: "watch",
                    isConnected: connectivity.isAppleWatchConnected,
                    action: {
                        showsWatchGuide = true
                        connectivity.refresh()
                    }
                )
            }
            .padding(12)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
        }
    }

    private var pointsRow: some View {
        Button(action: viewModel.onPoints) {
            HStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.cardGold.opacity(0.55), AppTheme.accentGold.opacity(0.42)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(Text("🏆").font(.system(size: 22)))
                
                Text("Points")
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(AppTheme.title)
                
                Spacer()
                
                MaterialSymbol(name: "chevron_right", size: 20)
                    .foregroundColor(AppTheme.muted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
    
    private func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.cardGold.opacity(0.3))
                    .frame(width: 48, height: 48)
                    .overlay(MaterialSymbol(name: icon, size: 22).foregroundColor(AppTheme.muted))
                Text(title)
                    .font(AppFonts.nunito(16, weight: .bold))
                    .foregroundColor(AppTheme.title)
                Spacer()
                MaterialSymbol(name: "chevron_right", size: 20)
                    .foregroundColor(AppTheme.muted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppTheme.elevatedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func connectedRow(title: String, icon: String, isConnected: Bool) -> some View {
        let statusText = isConnected ? "Connected" : "Not Connected"
        let statusColor = isConnected ? AppTheme.success : AppTheme.primaryButton
        let statusBackground = isConnected ? AppTheme.success.opacity(0.16) : AppTheme.primaryButton.opacity(0.16)

        return HStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardGold.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(MaterialSymbol(name: icon, size: 22).foregroundColor(AppTheme.muted))
            Text(title)
                .font(AppFonts.nunito(16, weight: .bold))
                .foregroundColor(AppTheme.title)
            Spacer()
            Text(statusText)
                .font(AppFonts.nunito(12, weight: .black))
                .foregroundColor(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusBackground)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func connectedRow(
        title: String,
        icon: String,
        isConnected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                connectedRow(title: title, icon: icon, isConnected: isConnected)
                if !isConnected {
                    MaterialSymbol(name: "chevron_right", size: 20)
                        .foregroundColor(AppTheme.muted)
                }
            }
        }
        .disabled(isConnected)
        .alert("Connect Apple Watch", isPresented: $showsWatchGuide) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open the Watch app and complete pairing to enable sync.")
        }
    }

    private var logoutButton: some View {
        Button(action: {
            Task { await authManager.signOut() }
        }) {
            Text("Log Out")
                .font(AppFonts.nunito(14, weight: .bold))
                .foregroundColor(AppTheme.muted)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .overlay(Capsule().stroke(AppTheme.muted.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4])))
        }
    }
}

private extension UIImage {
    func fitMe_downscaled(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: floor(size.width * scale), height: floor(size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
