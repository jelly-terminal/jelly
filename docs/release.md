# Jelly: Release and Updates

Jelly ships outside the App Store as a notarized DMG on GitHub Releases and updates itself with Sparkle.

```
git tag vX.Y.Z ─▶ GitHub Actions (macos-26)
                    archive + export (Developer ID) ─▶ DMG ─▶ sign ─▶ notarize ─▶ staple
                    generate_appcast (EdDSA) ─▶ appcast.xml
                  ─▶ GitHub Release: notes + DMG + appcast.xml
Installed Jelly ─▶ Sparkle ─▶ releases/latest/download/appcast.xml ─▶ DMG
```

## Cutting a release

1. Commit with conventional prefixes (`feat:`, `fix:`, `perf:`, `refactor:`, `build:`, `docs:`). Commit subjects become the release notes, so write them as short user-readable sentences.
2. Push `main`.
3. `git tag v0.1.0 && git push origin v0.1.0`.

Tags with a `-` (`v0.1.0-beta.1`) become pre-releases. The workflow refuses tags that aren't on `main`.

## Versions

- `MARKETING_VERSION` = the tag without `v`. This is what users see.
- `CURRENT_PROJECT_VERSION` = the workflow run number. **Sparkle compares this one**, so it must always increase.

## Sparkle setup

- Package: `https://github.com/sparkle-project/Sparkle`, up to next major from 2.9.0.
- Keys go in `Config/Jelly-Info.plist`, merged via `INFOPLIST_FILE`. Xcode silently drops custom `INFOPLIST_KEY_SU*` build settings.

| Key | Value |
|---|---|
| `SUFeedURL` | `https://github.com/mxvsh/Jelly/releases/latest/download/appcast.xml` |
| `SUPublicEDKey` | printed by `generate_keys` |
| `SUEnableAutomaticChecks` | `true` |

- Jelly is **not sandboxed**, so `SUEnableInstallerLauncherService` and the `-spks` / `-spki` mach-lookup exceptions are not needed.
- Check the keys landed: `plutil -p Jelly.app/Contents/Info.plist | grep '"SU'`.

### EdDSA keys (once)

```fish
set GK build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
$GK --account jelly
$GK --account jelly -x ~/Documents/jelly.key
gh secret set SPARKLE_PRIVATE_KEY -R mxvsh/Jelly < ~/Documents/jelly.key
rm ~/Documents/jelly.key
```

Put the printed public key in `SUPublicEDKey`. **Back up the private key.** If it's lost, existing installs can never verify another update.

## GitHub secrets

| Secret | What |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Developer ID Application cert + key as `.p12`, base64 |
| `P12_PASSWORD` | Password chosen when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | Any random string |
| `APPLE_TEAM_ID` | 10-character team ID |
| `APPLE_ID` | Developer account email |
| `APPLE_APP_SPECIFIC_PASSWORD` | From account.apple.com |
| `SPARKLE_PRIVATE_KEY` | From `generate_keys -x` |

```fish
base64 -i ~/Documents/Certificates.p12 | gh secret set BUILD_CERTIFICATE_BASE64 -R mxvsh/Jelly
gh secret set P12_PASSWORD -R mxvsh/Jelly
gh secret set APPLE_TEAM_ID --body TEAMID -R mxvsh/Jelly
openssl rand -hex 16 | gh secret set KEYCHAIN_PASSWORD -R mxvsh/Jelly
gh secret set APPLE_ID -R mxvsh/Jelly
gh secret set APPLE_APP_SPECIFIC_PASSWORD -R mxvsh/Jelly
rm ~/Documents/Certificates.p12
```

The certificate must be **Developer ID Application** (`security find-identity -v -p codesigning`).

## Known pitfalls

| Symptom | Fix |
|---|---|
| `future Xcode project file format` on CI | The project is `objectVersion = 110` (Xcode 27); the workflow downgrades it to 77 before building. |
| Build fails for the runner's SDK | Keep `MACOSX_DEPLOYMENT_TARGET = 26.0`. |
| `Validate plug-in "SwiftTermBuildInfoPlugin"` fails | Pass `-skipPackagePluginValidation` to `xcodebuild` (the Makefile and workflow do). |
| `missing Metal Toolchain` | `xcodebuild -downloadComponent MetalToolchain` (the workflow does this). |
| Update check does nothing | `SUPublicEDKey` is empty; the updater only starts once the key is set. |
| Update feed 404s | `releases/latest` skips pre-releases. Publish a full release first. |
| No update offered | `CURRENT_PROJECT_VERSION` didn't increase. |
| Tag run never starts | The workflow was invalid at that commit. Fix, push `main`, recreate the tag. |

## Before the first release

1. All seven secrets set (`gh secret list`).
2. App icon in place, version shown correctly in About.
3. Tag `v0.1.0-beta.1` to prove signing, notarization and the appcast.
4. Tag two full releases (`v0.1.0`, `v0.1.1`) and update from one to the other to prove Sparkle end to end.
