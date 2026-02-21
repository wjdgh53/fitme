import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

@main
struct FitMeApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootGateView()
                .environmentObject(appViewModel)
                .environmentObject(authManager)
                .task {
                    await APIClient.shared.setTokenProvider {
                        await authManager.getIDToken()
                    }
                }
                .task(id: authManager.displayName) {
                    appViewModel.userName = authManager.displayName
                }
        }
    }
}

private struct RootGateView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                AppRootView()
            } else {
                LoginView()
            }
        }
    }
}

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isGuest = false
    @Published private(set) var displayName = "User"
    @Published private(set) var email: String?
    @Published var errorMessage: String?

    #if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    #endif

    private var firebaseConfigured = false
    private var localGuestToken: String?

    init() {
        start()
    }

    deinit {
        #if canImport(FirebaseAuth)
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
        #endif
    }

    func start() {
        configureFirebaseIfNeeded()
        observeAuthChanges()
    }

    func getIDToken() async -> String? {
        #if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else { return nil }
        return await withCheckedContinuation { continuation in
            user.getIDToken(completion: { token, _ in
                continuation.resume(returning: token)
            })
        }
        #else
        return localGuestToken
        #endif
    }

    func signInGuest() async {
        errorMessage = nil

        #if canImport(FirebaseAuth)
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
                Auth.auth().signInAnonymously { result, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let result else {
                        continuation.resume(throwing: NSError(domain: "fitme.auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing auth result"]))
                        return
                    }
                    continuation.resume(returning: result)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        localGuestToken = UUID().uuidString
        isAuthenticated = true
        isGuest = true
        displayName = "Guest"
        #endif
    }

    func signInWithApple() async {
        await signInWithOAuth(providerID: "apple.com")
    }

    func signInWithGoogle() async {
        await signInWithOAuth(providerID: "google.com")
    }

    func signOut() async {
        errorMessage = nil

        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        localGuestToken = nil
        isAuthenticated = false
        isGuest = false
        displayName = "User"
        email = nil
        #endif
    }

    private func signInWithOAuth(providerID: String) async {
        errorMessage = nil

        #if canImport(FirebaseAuth)
        do {
            let credential = try await fetchOAuthCredential(providerID: providerID)

            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                do {
                    _ = try await link(user: currentUser, with: credential)
                    return
                } catch {
                    let nsError = error as NSError
                    if nsError.code != AuthErrorCode.credentialAlreadyInUse.rawValue {
                        throw error
                    }
                }
            }

            _ = try await signIn(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        errorMessage = "Firebase Auth SDK is not linked to this app target yet."
        #endif
    }

    #if canImport(FirebaseAuth)
    private func configureFirebaseIfNeeded() {
        guard !firebaseConfigured else { return }

        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif

        firebaseConfigured = true
    }

    private func observeAuthChanges() {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.apply(user: user)
        }
    }

    private func apply(user: User?) {
        guard let user else {
            isAuthenticated = false
            isGuest = false
            displayName = "User"
            email = nil
            return
        }

        isAuthenticated = true
        isGuest = user.isAnonymous
        displayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? user.displayName!
            : (user.isAnonymous ? "Guest" : "Member")
        email = user.email

        Task { [weak self] in
            guard let self else { return }
            do {
                let me = try await APIClient.shared.getMe()
                await MainActor.run {
                    if let backendName = me.profile.displayName, !backendName.isEmpty {
                        self.displayName = backendName
                    }
                    self.email = me.profile.email ?? self.email
                }
            } catch {
                // Keep Firebase-derived profile when backend profile is not available yet.
            }
        }
    }

    private func fetchOAuthCredential(providerID: String) async throws -> AuthCredential {
        let provider = OAuthProvider(providerID: providerID)

        if providerID == "apple.com" {
            provider.scopes = ["email", "name"]
        }

        return try await withCheckedThrowingContinuation { continuation in
            provider.getCredentialWith(nil) { credential, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let credential else {
                    continuation.resume(throwing: NSError(domain: "fitme.auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing OAuth credential"]))
                    return
                }
                continuation.resume(returning: credential)
            }
        }
    }

    private func signIn(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: NSError(domain: "fitme.auth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing sign-in result"]))
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }

    private func link(user: User, with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            user.link(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: NSError(domain: "fitme.auth", code: -4, userInfo: [NSLocalizedDescriptionKey: "Missing link result"]))
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
    #else
    private func configureFirebaseIfNeeded() {}

    private func observeAuthChanges() {
        isAuthenticated = false
        isGuest = false
        displayName = "User"
        email = nil
    }
    #endif
}

private struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        ZStack {
            AppTheme.appBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Welcome to FitMe")
                    .font(AppFonts.quicksand(30, weight: .bold))
                    .foregroundColor(AppTheme.title)

                Text("Sign in to sync your workouts across devices.")
                    .font(AppFonts.nunito(15, weight: .medium))
                    .foregroundColor(AppTheme.subtitle)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button("Continue with Apple") {
                    Task { await authManager.signInWithApple() }
                }
                .buttonStyle(LoginPrimaryButtonStyle())

                Button("Continue with Google") {
                    Task { await authManager.signInWithGoogle() }
                }
                .buttonStyle(LoginSecondaryButtonStyle())

                Button("Continue as Guest") {
                    Task { await authManager.signInGuest() }
                }
                .buttonStyle(LoginGhostButtonStyle())

                if let errorMessage = authManager.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(AppFonts.nunito(13, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

private struct LoginPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.nunito(16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? AppTheme.primaryButtonPressed : AppTheme.primaryButton)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct LoginSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.nunito(16, weight: .bold))
            .foregroundColor(AppTheme.title)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.elevatedSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

private struct LoginGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.nunito(14, weight: .bold))
            .foregroundColor(AppTheme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.muted.opacity(0.4), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}
