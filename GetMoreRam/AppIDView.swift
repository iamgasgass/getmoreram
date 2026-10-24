//
//  AppIDView.swift
//  GetMoreRam
//
//  Created by s s on 2025/3/15.
//

import SwiftUI

struct AppIDEditView: View {
    @StateObject var viewModel: AppIDModel
    @State private var errorShow = false
    @State private var errorInfo = ""
    @State private var isUpdating = false

    var body: some View {
        ZStack {
            AppGlassBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        GlassSectionHeading(
                            title: "App ID",
                            subtitle: "Grant the increased memory capability to this identifier.",
                            symbol: "app.badge.checkmark"
                        )

                        VStack(alignment: .leading, spacing: 7) {
                            Text("BUNDLE IDENTIFIER")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .tracking(1.1)
                                .foregroundStyle(.secondary)
                            Text(viewModel.bundleID)
                                .font(.system(.body, design: .monospaced, weight: .medium))
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.10)

                        Button {
                            Task { await addIncreasedMemoryLimit() }
                        } label: {
                            HStack(spacing: 10) {
                                if isUpdating {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "memorychip")
                                }
                                Text(isUpdating ? "Updating Capability…" : "Add Increased Memory Limit")
                            }
                        }
                        .buttonStyle(LiquidGlassButtonStyle(prominent: true))
                        .disabled(isUpdating)
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 28)

                    VStack(alignment: .leading, spacing: 12) {
                        GlassSectionHeading(
                            title: "Server Response",
                            subtitle: "The latest response from Apple's developer services.",
                            symbol: "terminal"
                        )

                        Text(viewModel.result.isEmpty ? "No request has been made yet." : viewModel.result)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(viewModel.result.isEmpty ? Color.secondary : Color.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                            .padding(14)
                            .liquidGlassCard(cornerRadius: 18, borderOpacity: 0.10)
                    }
                    .padding(18)
                    .liquidGlassCard(cornerRadius: 28)
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle(viewModel.bundleID)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $errorShow) {
            Button("OK".loc) { }
        } message: {
            Text(errorInfo)
        }
    }

    private func addIncreasedMemoryLimit() async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }

        do {
            try await viewModel.addIncreasedMemory()
        } catch {
            errorInfo = error.detailedDescription
            errorShow = true
        }
    }
}

struct AppIDView: View {
    @StateObject var viewModel: AppIDViewModel
    @EnvironmentObject private var sharedModel: SharedModel

    @State private var errorShow = false
    @State private var errorInfo = ""
    @State private var isRefreshing = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppGlassBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroCard

                        if !sharedModel.isLogin {
                            signInNotice
                        }

                        if viewModel.appIDs.isEmpty {
                            emptyState
                        } else {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Available App IDs")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Spacer()
                                GlassStatusPill(title: "\(viewModel.appIDs.count) total", symbol: "square.stack.3d.up.fill")
                            }
                            .padding(.horizontal, 2)

                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.appIDs, id: \.self) { appID in
                                    NavigationLink {
                                        AppIDEditView(viewModel: appID)
                                    } label: {
                                        HStack(spacing: 14) {
                                            GlassIconBadge(symbol: "app.dashed", size: 48)
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text(appID.bundleID)
                                                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.leading)
                                                Text("Manage memory capability")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer(minLength: 4)
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding(14)
                                        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                        .liquidGlassCard(cornerRadius: 22, borderOpacity: 0.11)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button {
                            Task { await refreshButtonClicked() }
                        } label: {
                            HStack(spacing: 10) {
                                if isRefreshing {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text(isRefreshing ? "Refreshing App IDs…" : (viewModel.appIDs.isEmpty ? "Load App IDs" : "Refresh App IDs"))
                            }
                        }
                        .buttonStyle(LiquidGlassButtonStyle(prominent: true))
                        .disabled(isRefreshing)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("App IDs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await refreshButtonClicked() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .disabled(isRefreshing)
                    .accessibilityLabel("Refresh App IDs")
                }
            }
            .alert("Error", isPresented: $errorShow) {
                Button("OK".loc) { }
            } message: {
                Text(errorInfo)
            }
        }
    }

    private var heroCard: some View {
        HStack(spacing: 16) {
            Image("GetMoreRamMark")
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                }
                .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 7) {
                Text("GET MORE RAM")
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                Text("Memory,\nunlocked.")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Manage App ID capabilities")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 30, borderOpacity: 0.18)
    }

    private var signInNotice: some View {
        HStack(alignment: .top, spacing: 13) {
            GlassIconBadge(symbol: "person.crop.circle.badge.exclamationmark", size: 46)
            VStack(alignment: .leading, spacing: 5) {
                Text("Sign in to get started")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Text("Open Settings to sign in with your Apple ID or import an existing SideStore account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 24)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 74, height: 74)
                .background(Circle().fill(Color.white.opacity(0.055)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))

            Text(sharedModel.isLogin ? "No App IDs loaded" : "Your App IDs live here")
                .font(.system(.headline, design: .rounded, weight: .bold))

            Text(sharedModel.isLogin
                 ? "Refresh to load the App IDs associated with your selected team."
                 : "After signing in and choosing a team, refresh to load your App IDs.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 22)
        .liquidGlassCard(cornerRadius: 28)
    }

    private func refreshButtonClicked() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await viewModel.fetchAppIDs()
        } catch {
            errorInfo = error.detailedDescription
            errorShow = true
        }
    }
}
