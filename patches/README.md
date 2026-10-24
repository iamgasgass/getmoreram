# StosSign integration patch

`StosSign` is consumed as a Swift Package Manager dependency, not stored in this repository. The script `scripts/patch-stossign.py` patches the resolved package checkout before compilation so the persisted GetMoreRam `AnisetteCustomUserAgent` setting is used for both GrandSlam login and the 2FA request. When disabled or empty, upstream defaults are retained.

After changing the StosSign dependency revision, inspect `Sources/StosSign_Auth/Authentication.swift` and update the expected anchors in the script if upstream has changed. Run after resolving packages and before compiling:

```sh
xcodebuild -resolvePackageDependencies -project GetMoreRam.xcodeproj -scheme GetMoreRam
./scripts/patch-stossign.sh
```

This is a source patch for the external package, not a vendored fork. The CI workflow runs it automatically. It does not implement SideStore's on-device Anisette/ODA provisioning backend; this project still provisions through a compatible remote Anisette v3 service.
