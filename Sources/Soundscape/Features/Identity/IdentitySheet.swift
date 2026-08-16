import SwiftUI
import GoogleSignIn
import AuthenticationServices

struct IdentitySheet: View {
    @Environment(LocaleManager.self) private var localeManager
    let session: IdentitySession
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .login
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var error: AppError?

    enum Mode: String, CaseIterable, Identifiable {
        case login = "login"
        case register = "register"
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .login: loc(.identityLogin)
            case .register: loc(.identityRegister)
            }
        }
    }

    var body: some View {
        let locale = localeManager.current

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(
                        eyebrow: loc(.identityEyebrow),
                        title: loc(.identityTitle),
                        detail: loc(.identityDetail)
                    )
                    HStack(spacing: 28) {
                        ForEach(Mode.allCases) { option in
                            Button {
                                mode = option
                            } label: {
                                VStack(spacing: 9) {
                                    Text(option.displayName)
                                        .font(.subheadline.weight(mode == option ? .semibold : .regular))
                                        .foregroundStyle(mode == option ? SoundscapeTheme.ink : SoundscapeTheme.secondaryInk)
                                    Rectangle()
                                        .fill(mode == option ? SoundscapeTheme.ink : .clear)
                                        .frame(height: 2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(SoundscapeTheme.line.opacity(0.7)).frame(height: 0.75)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        emailField
                        if mode == .register {
                            field(title: loc(.identityUsername), text: $name, secure: false)
                        }
                        field(title: loc(.identityPassword), text: $password, secure: true)
                        if let error {
                            Text(error.userMessage)
                                .font(.footnote)
                                .foregroundStyle(SoundscapeTheme.accent)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .soundscapeSurface(cornerRadius: SoundscapeTheme.controlRadius, shadow: false)
                                .accessibilityLabel("\(loc(.errorGeneric)) \(error.userMessage)")
                        }
                        Button {
                            Task { await submit() }
                        } label: {
                            HStack {
                                if isSubmitting { ProgressView().tint(SoundscapeTheme.paperRaised) }
                                Text(mode == .login ? loc(.identityLoginButton) : loc(.identityRegisterButton))
                            }
                        }
                        .buttonStyle(PrimaryActionStyle())
                        .disabled(isSubmitting)
                        .accessibilityIdentifier("identity-submit")

                        googleSignInButton
                        appleSignInButton
                    }
                }
                .padding(SoundscapeTheme.screenPadding)
            }
            .soundscapeScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(loc(.libraryClose)) { dismiss() }
                }
            }
        }
        .environment(\.locale, Locale(identifier: locale.rawValue))
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                handleAppleSignIn(authorization)
            case .failure(let error):
                self.error = .transport(error.localizedDescription)
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 46)
        .clipShape(RoundedRectangle(cornerRadius: SoundscapeTheme.controlRadius))
        .accessibilityIdentifier("apple-signin")
    }

    private var googleSignInButton: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle().fill(SoundscapeTheme.line.opacity(0.5)).frame(height: 1)
                Text(loc(.identityOrContinueWith))
                    .font(.caption)
                    .foregroundStyle(SoundscapeTheme.secondaryInk)
                Rectangle().fill(SoundscapeTheme.line.opacity(0.5)).frame(height: 1)
            }

            Button {
                startGoogleSignIn()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 20))
                    Text(loc(.identityGoogleSignIn))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(SoundscapeTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .soundscapeSurface(cornerRadius: SoundscapeTheme.controlRadius, shadow: false)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)
            .accessibilityIdentifier("google-signin")
        }
    }

    private func startGoogleSignIn() {
        guard let rootViewController = rootViewController() else {
            error = .invalidRequest(loc(.errorTryAgain))
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        ) { result, signInError in
            if let signInError {
                self.error = .transport(signInError.localizedDescription)
                return
            }
            guard let idToken = result?.user.idToken?.tokenString else {
                self.error = .invalidRequest(loc(.errorServerDataUnrecognized))
                return
            }
            Task { @MainActor in
                await handleGoogleToken(idToken)
            }
        }
    }

    private func handleAppleSignIn(_ authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let authorizationCodeData = credential.authorizationCode,
              let authorizationCode = String(data: authorizationCodeData, encoding: .utf8) else {
            self.error = .invalidRequest(loc(.errorServerDataUnrecognized))
            return
        }
        Task { @MainActor in
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                try await session.appleLogin(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode,
                    fullName: credential.fullName
                )
                dismiss()
            } catch let appError as AppError {
                error = appError
            } catch let underlyingError {
                error = .transport(String(describing: type(of: underlyingError)))
            }
        }
    }

    private func handleGoogleToken(_ token: String) async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await session.googleLogin(idToken: token)
            dismiss()
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
    }

    private var emailField: some View {
        SoundscapeField(title: loc(.identityEmail)) {
            TextField(loc(.identityEmail), text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private func field(title: String, text: Binding<String>, secure: Bool) -> some View {
        SoundscapeField(title: title) {
            if secure {
                SecureField(title, text: text)
                    .textContentType(.password)
            } else {
                TextField(title, text: text)
                    .textContentType(.name)
            }
        }
    }

    private func submit() async {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedEmail.isEmpty else {
            error = .invalidRequest(loc(.errorEmailRequired))
            return
        }
        guard password.count >= 6 else {
            error = .invalidRequest(loc(.errorPasswordTooShort))
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            switch mode {
            case .login: try await session.login(email: normalizedEmail, password: password)
            case .register:
                try await session.register(
                    name: normalizedName.isEmpty ? nil : normalizedName,
                    email: normalizedEmail,
                    password: password
                )
            }
            dismiss()
        } catch let appError as AppError {
            error = appError
        } catch let underlyingError {
            error = .transport(String(describing: type(of: underlyingError)))
        }
    }

    private func rootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let root = window.rootViewController else {
            return nil
        }
        return root
    }
}
