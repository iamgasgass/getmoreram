//
//  AppIDViewModel.swift
//  GetMoreRam
//
//  Created by s s on 2025/3/15.
//
import SwiftUI
import StosSign_API
import StosSign_Auth
import StosSign_Common

class AppIDModel : ObservableObject, Hashable {
    static func == (lhs: AppIDModel, rhs: AppIDModel) -> Bool {
        return lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    var appID: AppID
    @Published var bundleID: String
    @Published var result: String = ""
    
    init(appID: AppID) {
        self.appID = appID
        bundleID = appID.bundleIdentifier
    }
    
    /// Capability requested from Apple's Developer Services for this App ID.
    /// The capability identifier is not itself the entitlement key embedded in an app.
    private enum MemoryEntitlementRequest {
        static let capabilityID = "INCREASED_MEMORY_LIMIT"
        static let entitlementKey = "com.apple.developer.kernel.increased-memory-limit"
    }

    func addIncreasedMemory() async throws {
        guard let team = DataManager.shared.model.team, let session = DataManager.shared.model.session else {
            throw "Please Login First"
        }

        let log = makeEntitlementRequestLog()
        print(log)
        result = log + "\n\n[REQUEST] Sending capability update to Apple Developer Services…"

        do {
            let updatedAppID = try await AppleAPI.shared.updateAppID(
                appID,
                capabilities: [MemoryEntitlementRequest.capabilityID],
                team: team,
                session: session
            )

            let success = """
            [RESULT] AppleAPI.updateAppID completed successfully.
            App ID: \(updatedAppID.name) (\(updatedAppID.identifier))
            Bundle ID: \(updatedAppID.bundleIdentifier)
            Requested capability: \(MemoryEntitlementRequest.capabilityID)
            Entitlement key associated with this capability: \(MemoryEntitlementRequest.entitlementKey)
            Note: success means the API accepted the capability update; verify the final signed app's provisioning profile/entitlements separately.
            """
            print(success)
            result += "\n\n" + success
        } catch {
            let failure = """

            [ERROR] Apple Developer Services rejected or failed the capability update.
            Capability: \(MemoryEntitlementRequest.capabilityID)
            Entitlement key associated with this capability: \(MemoryEntitlementRequest.entitlementKey)
            Error: \(error.detailedDescription)
            """
            print(failure)
            result += failure
            throw error
        }
    }

    private func makeEntitlementRequestLog() -> String {
        let sortedFeatures = appID.features.keys.sorted().map { key in
            "  - \(key) = \(String(describing: appID.features[key]!))"
        }
        let featuresText = sortedFeatures.isEmpty ? "  (none reported by StosSign model)" : sortedFeatures.joined(separator: "\n")
        let entitlementText = appID.entitlements.isEmpty
            ? "  (empty in current StosSign AppID model; this is not proof that the signed app has no entitlements)"
            : appID.entitlements.sorted().map { "  - \($0)" }.joined(separator: "\n")

        return """
        ========== GetMoreRam Entitlement Request ==========
        App name: \(appID.name)
        App ID resource ID: \(appID.identifier)
        Bundle identifier: \(appID.bundleIdentifier)
        Team ID: \(DataManager.shared.model.team?.identifier ?? "(unavailable)")

        REQUESTED APPLE DEVELOPER CAPABILITY
          Capability ID sent to Apple: \(MemoryEntitlementRequest.capabilityID)
          Associated entitlement key: \(MemoryEntitlementRequest.entitlementKey)
          Requested value: enabled (true)
          API: AppleAPI.updateAppID(... capabilities: [\(MemoryEntitlementRequest.capabilityID)])

        CURRENT APP ID DATA (as decoded by StosSign)
        Features:
        \(featuresText)
        Entitlements field:
        \(entitlementText)

        IMPORTANT
          The capability ID above is what this app requests from Developer Services.
          It is not a direct readout of the final app binary's signed entitlements.
          The final entitlement must be checked in the generated provisioning profile / signed app.
        ===================================================
        """
    }
    
}

class AppIDViewModel : ObservableObject {
    @Published var appIDs : [AppIDModel] = []
    
    func fetchAppIDs() async throws {
        guard let team = DataManager.shared.model.team, let session = DataManager.shared.model.session else {
            throw "Please Login First"
        }
        
        let ids = try await AppleAPI.shared.fetchAppIDsForTeam(team: team, session: session)
        await MainActor.run {
            appIDs.removeAll()
            for id in ids {
                appIDs.append(AppIDModel(appID: id))
            }
        }
    }
}
