# Get More Ram
A simple [StosSign](https://github.com/stossy11/StosSign) wrapper app that allows you to enable "Increased Memory Limit" for your sideloaded apps without using Xcode.

## Liquid Glass interface and app icon

The interface uses a graphite/silver visual system based on the supplied Get More Ram artwork. The artwork is installed in the iOS `AppIcon` catalog and reused in the in-app brand header. Custom cards and action buttons use SwiftUI's native `glassEffect` on iOS 26 and a system-material fallback on earlier iOS versions. Navigation bars, sheets, toggles, tab navigation, file importers, and alerts remain native SwiftUI/system UI so iOS can provide its own current appearance.

Build with Xcode 26 or newer to compile the native Liquid Glass API calls. The project keeps its existing iOS deployment target; devices older than iOS 26 use the fallback surfaces rather than native Liquid Glass.

# Anisette / Apple ID login troubleshooting

The app reads `client_info` and `user_agent` from the configured Anisette v3 server at `/v3/client_info`. These values need to match the server that generates the Anisette headers; the app no longer hard-codes a Mac client identity for every server.

If Apple sign-in fails with `-80045`, open **Settings → Anisette Server URL** and try the Windows Anisette endpoint `https://ani.jkcoxson.com` rather than a Mac-specific endpoint such as `https://mac-ani.jkcoxson.com`. Then tap **Clean Up Keychain**, force-quit and reopen the app, and try signing in once. This resets the saved Anisette provisioning identity as well as saved sign-in details. Apple can still reject some accounts or networks even with a compatible Anisette server; this change cannot guarantee that Apple will accept every login.

Use only an Anisette server you trust. Never share your Apple ID password, verification codes, or exported account JSON in bug reports.

## Anisette Client Configuration

In **Settings → Anisette Client Configuration**, you can enable independent overrides for **Client Info** and **User-Agent**. The values are saved locally with `UserDefaults`; disabling an override restores the values advertised by the selected server at `/v3/client_info`. Changing an override clears the cached client identity so the next request uses the new configuration.

**Reset Anisette State** clears the provisioned `adi.pb` and identifier without deleting the saved Apple ID credentials. **Clean Up Keychain** remains the broader reset and also clears the saved login/account state.

This project still uses a **remote Anisette v3 server** for provisioning and header retrieval. These settings are not a local/on-device ADI provisioning engine. Also, the external `StosSign` Swift package currently hard-codes the GrandSlam login `User-Agent`; the app-level override is used by this project's Anisette/provisioning requests but does not override that dependency's GrandSlam header. Full parity with SideStore's latest login workaround requires porting/updating that authentication dependency as well.

# How to use
1. Sideload this app
2. Go to settings, sign in your account that you used to sign the app you want to enable "Increased Memory Limit"
3. Go to "App IDs" page
4. Tap Refresh
5. Tap the app you want to enable "Increased Memory Limit"
6. Tap "Add Increased Memory Limit"
7. Reinstall the app from SideStore/AltStore
8. Check if you have "Increased Memory Limit"

# Credits
Stossy11 - For StosSign.
SideStore - Anisette Data fetching codes are stolen from SideStore

## Anisette client configuration and StosSign integration

Settings supports persistent Client Info and User-Agent overrides. Client Info is passed through `AnisetteData.deviceDescription`; the User-Agent override is applied to GetMoreRam's Anisette provisioning requests and, by the build-time StosSign patch, to GrandSlam login and 2FA requests.

For local builds, resolve packages and apply the patch before building:

```sh
xcodebuild -resolvePackageDependencies -project GetMoreRam.xcodeproj -scheme GetMoreRam
./scripts/patch-stossign.sh
```

The GitHub Actions build workflow applies this patch automatically. This repository still uses a remote Anisette v3 server for provisioning; it does not yet include SideStore's complete on-device Anisette/ODA backend, so this is not full feature parity with SideStore.

## Explicit Increased Memory entitlement logging

When **Add Increased Memory Limit** is pressed, the app now prints a structured diagnostic block to the Xcode console and the in-app Server Response panel. It records the App ID resource, bundle identifier, team ID, requested Developer Services capability (`INCREASED_MEMORY_LIMIT`), the associated entitlement key (`com.apple.developer.kernel.increased-memory-limit`), and the current `features`/`entitlements` values exposed by the StosSign model. Success and failure are logged separately, including the detailed error on failure.

Important distinction: `INCREASED_MEMORY_LIMIT` is the Developer Services capability identifier sent in the API request; `com.apple.developer.kernel.increased-memory-limit` is the entitlement key associated with the capability. The current StosSign `AppID` model initializes `entitlements` as an empty array and does not decode the final signed app entitlements, so the log explicitly labels that field as model data rather than claiming it reflects the signed binary. Verify the final provisioning profile and signed app separately when needed.

## App identity and appearance

- App bundle identifier: `com.iamgasgass.getmoreram` (Debug and Release).
- The shared `AppGlassBackground` uses a near-black graphite palette so Liquid Glass surfaces remain subtle against a darker background.
