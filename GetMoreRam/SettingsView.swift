//
//  SettingsView.swift
//  GetMoreRam
//
//  Created by s s on 2025/3/14.
//

import SwiftUI
import UniformTypeIdentifiers
import StosSign_API
import StosSign_Auth
import StosSign_Common

struct SettingsView: View {
    @State var email = ""
    @State var teamId = ""
    @StateObject var viewModel: LoginViewModel
    @EnvironmentObject private var sharedModel: SharedModel

    @State private var errorShow = false
    @State private var errorInfo = ""
    @State private var importResultShow = false
    @State private var importResultInfo = ""
    @State private var isImportingSideStoreAccount = false
    @State private var confirmResetAnisette = false

    // Persisted like SideStore's user-customization preferences.
    @AppStorage("AnisetteUseCustomClientInfo") private var useCustomClientInfo = false
    @AppStorage("AnisetteCustomClientInfo") private var customClientInfo = ""
    @AppStorage("AnisetteUseCustomUserAgent") private var useCustomUserAgent = false
    @AppStorage("AnisetteCustomUserAgent") private var customUserAgent = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        settingsIntro
                        accountCard
                        anisetteServerCard
                        anisetteClientCard
                        maintenanceCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    .padding(.bottom, 36)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onChange(of: sharedModel.anisetteServerURL) { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            AnisetteDataHelper.shared.url = URL(string: trimmed)
            AnisetteDataHelper.shared.resetClientInfo()
        }
        .onChange(of: useCustomClientInfo) { _ in
            AnisetteDataHelper.shared.resetClientInfo()
        }
        .onChange(of: customClientInfo) { _ in
            AnisetteDataHelper.shared.resetClientInfo()
        }
        .onChange(of: useCustomUserAgent) { _ in
            AnisetteDataHelper.shared.resetClientInfo()
        }
        .onChange(of: customUserAgent) { _ in
            AnisetteDataHelper.shared.resetClientInfo()
        }
        .confirmationDialog("Reset Anisette State?", isPresented: $confirmResetAnisette, titleVisibility: .visible) {
            Button("Reset Anisette State", role: .destructive) {
                Keychain.shared.adiPb = nil
                Keychain.shared.identifier = nil
                AnisetteDataHelper.shared.resetClientInfo()
                errorInfo = "Anisette provisioning state reset. Your saved Apple ID credentials were not changed."
                errorShow = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears the saved Anisette provisioning identity only. It does not delete your saved Apple ID credentials or account session.")
        }
        .alert("Error", isPresented: $errorShow) {
            Button("OK".loc) { }
        } message: {
            Text(errorInfo)
        }
        .alert("SideStore Account", isPresented: $importResultShow) {
            Button("OK".loc) { }
        } message: {
            Text(importResultInfo)
        }
        .fileImporter(
            isPresented: $isImportingSideStoreAccount,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            importSideStoreAccount(result)
        }
        .sheet(isPresented: $viewModel.loginModalShow, onDismiss: {
            viewModel.cancelAuthentication()
        }) {
            loginModal
                .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.teamSelectionShow) {
            teamSelectionView
                .presentationDetents([.medium, .large])
        }
    }

    private var settingsIntro: some View {
        HStack(spacing: 15) {
            Image("GetMoreRamMark")
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.22), radius: 11, x: 0, y: 5)

            VStack(alignment: .leading, spacing: 5) {
                Text("GET MORE RAM")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(1.8)
                    .foregroundStyle(.secondary)
                Text("Control center")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text("Account, Anisette and app preferences")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 28, borderOpacity: 0.18)
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassSectionHeading(
                title: "Account",
                subtitle: sharedModel.isLogin ? "Connected developer account" : "Connect your Apple developer account",
                symbol: sharedModel.isLogin ? "person.crop.circle.badge.checkmark" : "person.crop.circle"
            )

            if sharedModel.isLogin {
                detailRow(title: "Apple ID", value: email.isEmpty ? (sharedModel.account?.appleID ?? "—") : email, symbol: "envelope")
                Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)
                detailRow(title: "Team ID", value: teamId.isEmpty ? (sharedModel.team?.identifier ?? "—") : teamId, symbol: "person.3")

                GlassStatusPill(title: "Signed in", symbol: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Button {
                    viewModel.loginModalShow = true
                } label: {
                    Label("Sign in with Apple ID", systemImage: "person.badge.key.fill")
                }
                .buttonStyle(LiquidGlassButtonStyle(prominent: true))

                Button {
                    isImportingSideStoreAccount = true
                } label: {
                    Label("Import SideStore Account", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 28)
    }

    private var anisetteServerCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            GlassSectionHeading(
                title: "Anisette Server",
                subtitle: "Choose the remote service used to retrieve Anisette data.",
                symbol: "network"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("SERVER URL")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                GlassTextFieldSurface {
                    TextField("https://ani.jkcoxson.com", text: $sharedModel.anisetteServerURL)
                        .font(.system(.subheadline, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .accessibilityLabel("Anisette Server URL")
                }
            }

            Text("The server must support the Anisette v3 API. Unless overridden below, Client Info and User-Agent should match the identity advertised by this server.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 28)
    }

    private var anisetteClientCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassSectionHeading(
                title: "Client Configuration",
                subtitle: "Fine-tune the identity sent with Anisette and Apple sign-in requests.",
                symbol: "slider.horizontal.3"
            )

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $useCustomClientInfo) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Customize Client Info")
                            .font(.subheadline.weight(.semibold))
                        Text("Override the server-provided client identity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.white)

                if useCustomClientInfo {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CLIENT INFO")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $customClientInfo)
                            .font(.system(.footnote, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                            .padding(8)
                            .overlay(alignment: .topLeading) {
                                if customClientInfo.isEmpty {
                                    Text("<PC> <Windows;6.2(0,0);9200> <com.apple.AuthKit/1 (com.apple.iTunes/12.12.4.1)>")
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 16)
                                        .padding(.leading, 13)
                                        .allowsHitTesting(false)
                                }
                            }
                            .accessibilityLabel("Custom Anisette Client Info")
                            .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.11)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Rectangle().fill(Color.white.opacity(0.10)).frame(height: 1)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $useCustomUserAgent) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Customize User-Agent")
                            .font(.subheadline.weight(.semibold))
                        Text("Override the user agent used for authentication")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.white)

                if useCustomUserAgent {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("USER-AGENT")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(.secondary)
                        GlassTextFieldSurface {
                            TextField("akd/1.0 CFNetwork/808.1.4", text: $customUserAgent, axis: .vertical)
                                .font(.system(.footnote, design: .monospaced))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .lineLimit(2...4)
                                .accessibilityLabel("Custom Anisette User-Agent")
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    useCustomClientInfo = false
                    useCustomUserAgent = false
                    customClientInfo = ""
                    customUserAgent = ""
                }
                AnisetteDataHelper.shared.resetClientInfo()
            } label: {
                Label("Use Server Defaults", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(LiquidGlassButtonStyle())
            .disabled(!useCustomClientInfo && !useCustomUserAgent && customClientInfo.isEmpty && customUserAgent.isEmpty)

            Text("Client Info must match the Anisette server and the identity it provisions. Incorrect values can cause Apple sign-in to fail. Changes are saved on this device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 28)
        .animation(.easeInOut(duration: 0.20), value: useCustomClientInfo)
        .animation(.easeInOut(duration: 0.20), value: useCustomUserAgent)
    }

    private var maintenanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            GlassSectionHeading(
                title: "Maintenance",
                subtitle: "Troubleshoot provisioning or remove locally stored credentials.",
                symbol: "wrench.and.screwdriver"
            )

            Button {
                confirmResetAnisette = true
            } label: {
                Label("Reset Anisette State", systemImage: "arrow.counterclockwise.icloud")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidGlassButtonStyle())

            Button(role: .destructive) {
                cleanUp()
            } label: {
                Label("Clean Up Keychain", systemImage: "key.slash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Text("Reset Anisette State clears only the provisioning identity. Clean Up Keychain also removes saved Apple ID credentials and the active account session. If you use SideStore, you can import an account export from its settings.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 28)
    }

    private func detailRow(title: String, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var loginModal: some View {
        NavigationStack {
            ZStack {
                AppGlassBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image("GetMoreRamMark")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                                }
                            Text(viewModel.needVerificationCode ? "Verify it's you" : "Sign in")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text(viewModel.needVerificationCode
                                 ? "Enter the verification code from a trusted device."
                                 : "Use your Apple ID to access your developer teams.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .liquidGlassCard(cornerRadius: 28)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("APPLE ID")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .tracking(1.1)
                                .foregroundStyle(.secondary)
                            GlassTextFieldSurface {
                                TextField("name@example.com", text: $viewModel.appleID)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .textContentType(.username)
                                    .disabled(viewModel.isLoginInProgress)
                            }

                            Text("PASSWORD")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .tracking(1.1)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                            GlassTextFieldSurface {
                                SecureField("Apple ID password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .disabled(viewModel.isLoginInProgress)
                            }

                            if viewModel.needVerificationCode {
                                Text("VERIFICATION CODE")
                                    .font(.system(.caption2, design: .rounded, weight: .bold))
                                    .tracking(1.1)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                GlassTextFieldSurface {
                                    TextField("6-digit code", text: $viewModel.verificationCode)
                                        .keyboardType(.numberPad)
                                        .textContentType(.oneTimeCode)
                                        .disabled(viewModel.isVerificationCodeSubmitting)
                                }
                            }

                            Button {
                                Task { await loginButtonClicked() }
                            } label: {
                                HStack(spacing: 9) {
                                    if viewModel.isLoginInProgress || viewModel.isVerificationCodeSubmitting {
                                        ProgressView().tint(.white)
                                    }
                                    Text(viewModel.needVerificationCode ? "Verify & Continue" : "Continue")
                                }
                            }
                            .buttonStyle(LiquidGlassButtonStyle(prominent: true))
                            .disabled(continueButtonDisabled)
                            .padding(.top, 8)
                        }
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 28)

                        VStack(alignment: .leading, spacing: 10) {
                            GlassSectionHeading(title: "Authentication Log", subtitle: "Diagnostic details for troubleshooting.", symbol: "terminal")
                            ScrollView(.vertical) {
                                Text(viewModel.logs.isEmpty ? "Waiting for the sign-in process to begin…" : viewModel.logs)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(viewModel.logs.isEmpty ? Color.secondary : Color.primary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .topLeading)
                            }
                            .frame(maxHeight: 240)
                        }
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 28)
                    }
                    .padding(18)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Apple Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        viewModel.cancelAuthentication()
                        viewModel.loginModalShow = false
                    }
                }
            }
        }
        .onAppear {
            if let savedEmail = Keychain.shared.appleIDEmailAddress,
               let savedPassword = Keychain.shared.appleIDPassword {
                viewModel.appleID = savedEmail
                viewModel.password = savedPassword
            }
        }
    }

    private var teamSelectionView: some View {
        NavigationStack {
            ZStack {
                AppGlassBackground()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Choose a team")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                            Text("Select the developer team that Get More Ram should use.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .liquidGlassCard(cornerRadius: 26)

                        ForEach(Array(viewModel.availableTeams.enumerated()), id: \.offset) { _, team in
                            Button {
                                selectTeam(team)
                            } label: {
                                HStack(spacing: 14) {
                                    GlassIconBadge(symbol: "person.3.fill", size: 46)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(team.name)
                                            .font(.system(.headline, design: .rounded, weight: .semibold))
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)
                                        Text("\(team.identifier) · \(teamTypeDescription(team.type))")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .liquidGlassCard(cornerRadius: 22)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Choose Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", role: .cancel) {
                        cancelTeamSelection()
                    }
                }
            }
        }
    }

    func loginButtonClicked() async {
        do {
            if viewModel.needVerificationCode {
                viewModel.submitVerificationCode()
                return
            }
            
            let result = try await viewModel.authenticate()
            if result {
                await MainActor.run {
                    viewModel.loginModalShow = false
                    email = sharedModel.account!.appleID
                    teamId = ""
                }

                if viewModel.availableTeams.count == 1,
                   let team = viewModel.availableTeams.first {
                    await MainActor.run {
                        selectTeam(team)
                    }
                } else {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await MainActor.run {
                        viewModel.teamSelectionShow = true
                    }
                }
            }
            
        } catch is CancellationError {
            return
        } catch {
            errorInfo = error.detailedDescription
            errorShow = true
        }
    }

    private var continueButtonDisabled: Bool {
        if viewModel.needVerificationCode {
            return viewModel.isVerificationCodeSubmitting ||
                viewModel.verificationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        return viewModel.isLoginInProgress
    }
    
    func cleanUp() {
        Keychain.shared.adiPb = nil
        Keychain.shared.identifier = nil
        Keychain.shared.appleIDPassword = nil
        Keychain.shared.appleIDEmailAddress = nil
        AnisetteDataHelper.shared.resetClientInfo()
        sharedModel.session = nil
        sharedModel.account = nil
        sharedModel.team = nil
        sharedModel.isLogin = false
        viewModel.availableTeams = []
        viewModel.teamSelectionShow = false
        email = ""
        teamId = ""
    }
    
    func importSideStoreAccount(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                throw "No file selected."
            }
            
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            let data = try Data(contentsOf: url)
            let account = try SideStoreAccountImporter.importAccount(from: data)
            
            viewModel.appleID = account.email
            viewModel.password = account.password
            sharedModel.session = nil
            sharedModel.account = nil
            sharedModel.team = nil
            sharedModel.isLogin = false
            viewModel.availableTeams = []
            viewModel.teamSelectionShow = false
            email = account.email
            teamId = ""
            importResultInfo = "Imported \(account.email).\nTap \"Sign In\" to continue."
            importResultShow = true
        } catch {
            errorInfo = error.detailedDescription
            errorShow = true
        }
    }
    
    func selectTeam(_ team: Team) {
        sharedModel.team = team
        sharedModel.isLogin = true
        email = sharedModel.account?.appleID ?? email
        teamId = team.identifier
        viewModel.availableTeams = []
        viewModel.teamSelectionShow = false
    }
    
    func cancelTeamSelection() {
        viewModel.availableTeams = []
        viewModel.teamSelectionShow = false
        sharedModel.session = nil
        sharedModel.account = nil
        sharedModel.team = nil
        sharedModel.isLogin = false
        email = ""
        teamId = ""
    }
    
    func teamTypeDescription(_ type: TeamType) -> String {
        switch type {
        case .free:
            return "Free"
        case .individual:
            return "Individual"
        case .organization:
            return "Organization"
        case .unknown:
            return "Unknown"
        }
    }
    
}
