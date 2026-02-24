import SwiftUI

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(CryptoKit)
import CryptoKit
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(UIKit)
import UIKit
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
        #if canImport(FirebaseAuth)
        guard configureFirebaseIfNeeded() else {
            isAuthenticated = false
            isGuest = false
            displayName = "User"
            email = nil
            return
        }
        #endif
        observeAuthChanges()
    }

    func getIDToken() async -> String? {
        #if canImport(FirebaseAuth)
        guard configureFirebaseIfNeeded() else { return nil }
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
        guard configureFirebaseIfNeeded() else { return }
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
        errorMessage = nil

        #if canImport(FirebaseAuth) && canImport(AuthenticationServices) && canImport(CryptoKit) && canImport(UIKit)
        guard configureFirebaseIfNeeded() else { return }

        do {
            let rawNonce = Self.randomNonceString()
            let appleCredential = try await Self.requestAppleCredential(rawNonce: rawNonce)

            guard let identityToken = appleCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8)
            else {
                throw NSError(
                    domain: "fitme.auth",
                    code: -23,
                    userInfo: [NSLocalizedDescriptionKey: "Apple identity token is missing."]
                )
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: rawNonce,
                fullName: appleCredential.fullName
            )
            try await authenticate(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        errorMessage = "Sign in with Apple requires AuthenticationServices, CryptoKit and FirebaseAuth."
        #endif
    }

    func signInWithGoogle() async {
        #if canImport(FirebaseCore) && canImport(FirebaseAuth) && canImport(GoogleSignIn) && canImport(UIKit)
        errorMessage = nil
        guard configureFirebaseIfNeeded() else { return }

        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(
                    domain: "fitme.auth",
                    code: -20,
                    userInfo: [NSLocalizedDescriptionKey: "Firebase clientID is missing. Check GoogleService-Info.plist."]
                )
            }

            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config

            guard let presenter = Self.resolvePresenter() else {
                throw NSError(
                    domain: "fitme.auth",
                    code: -21,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot find a view controller to present Google sign-in."]
                )
            }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(
                    domain: "fitme.auth",
                    code: -22,
                    userInfo: [NSLocalizedDescriptionKey: "Google ID token is missing."]
                )
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await authenticate(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        await signInWithOAuth(providerID: "google.com")
        #endif
    }

    func signOut() async {
        errorMessage = nil

        #if canImport(FirebaseAuth)
        guard configureFirebaseIfNeeded() else { return }
        do {
            #if canImport(GoogleSignIn)
            GIDSignIn.sharedInstance.signOut()
            #endif
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
        guard configureFirebaseIfNeeded() else { return }
        do {
            let credential = try await fetchOAuthCredential(providerID: providerID)
            try await authenticate(with: credential)
        } catch {
            errorMessage = error.localizedDescription
        }
        #else
        errorMessage = "Firebase Auth SDK is not linked to this app target yet."
        #endif
    }

    #if canImport(FirebaseAuth)
    private func configureFirebaseIfNeeded() -> Bool {
        guard !firebaseConfigured else { return true }

        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
                errorMessage = "GoogleService-Info.plist is missing in app target. Add it to FitMeApp target."
                return false
            }
            FirebaseApp.configure()
        }
        #endif

        firebaseConfigured = true
        return true
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

    private func authenticate(with credential: AuthCredential) async throws {
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
    }

    #if canImport(UIKit)
    private static func resolvePresenter() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                return root
            }
            if let root = scene.windows.first?.rootViewController {
                return root
            }
        }
        return nil
    }
    #endif

    #if canImport(AuthenticationServices) && canImport(CryptoKit) && canImport(UIKit)
    private static var appleSignInCoordinators: [ObjectIdentifier: AppleSignInCoordinator] = [:]

    private static func requestAppleCredential(rawNonce: String) async throws -> ASAuthorizationAppleIDCredential {
        guard let anchor = resolvePresentationAnchor() else {
            throw NSError(
                domain: "fitme.auth",
                code: -24,
                userInfo: [NSLocalizedDescriptionKey: "Cannot find a window to present Apple sign-in."]
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(rawNonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let coordinator = AppleSignInCoordinator(anchor: anchor, continuation: continuation)
            let id = ObjectIdentifier(controller)
            appleSignInCoordinators[id] = coordinator
            coordinator.onFinish = {
                appleSignInCoordinators.removeValue(forKey: id)
            }

            controller.delegate = coordinator
            controller.presentationContextProvider = coordinator
            controller.performRequests()
        }
    }

    private static func resolvePresentationAnchor() -> ASPresentationAnchor? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let key = scene.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
            if let first = scene.windows.first {
                return first
            }
        }
        return nil
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }

            randoms.forEach { random in
                if remaining == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }

        return result
    }

    private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let anchor: ASPresentationAnchor
        let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>
        var onFinish: (() -> Void)?

        init(anchor: ASPresentationAnchor, continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
            self.anchor = anchor
            self.continuation = continuation
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            anchor
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            defer { onFinish?() }
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                continuation.resume(
                    throwing: NSError(
                        domain: "fitme.auth",
                        code: -25,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected Apple credential type."]
                    )
                )
                return
            }
            continuation.resume(returning: credential)
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            defer { onFinish?() }
            continuation.resume(throwing: error)
        }
    }
    #endif

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
    private func configureFirebaseIfNeeded() -> Bool { false }

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
