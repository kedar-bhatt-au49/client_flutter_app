# Releasing a New Version (In-App Update Runbook)

This app updates itself from **GitHub Releases** of the public repository
`kedar-bhatt-au49/client_flutter_app`. Tagging a version builds a signed APK in
GitHub Actions, publishes it as a Release, and every installed app detects it on
next launch (or from **Settings → App Updates → Check for Updates**).

---

## 1. One-time setup

### 1.1 Required GitHub Secrets

Add these under **Repository → Settings → Secrets and variables → Actions → New repository secret**.
Values are never committed and never shown in this file.

| Secret | What it is | How to produce it |
|---|---|---|
| `KEYSTORE_B64` | Base64 of the Android signing keystore (`.jks`) | see below |
| `KEYSTORE_PASSWORD` | Keystore (store) password | you set it when creating/exporting the keystore |
| `KEY_PASSWORD` | Key password | usually identical to the store password |
| `KEY_ALIAS` | Key alias inside the keystore | e.g. `androiddebugkey` for the current debug keystore |
| `GOOGLE_SERVICES_JSON_B64` | Base64 of `android/app/google-services.json` | see below |

> **Upgrade-continuity rule:** `KEYSTORE_B64` must be the **same certificate**
> that signed the APK currently installed on the phones. Android refuses to
> install an update signed by a different key (`App not installed`).
> The builds on the phones today were signed with the local **debug key**, so
> the current setup intentionally reuses it (see §3).

Produce a Base64 secret (PowerShell):

```powershell
# Keystore (the debug keystore currently used for releases)
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("$env:USERPROFILE\.android\debug.keystore")
) | Set-Clipboard   # paste into KEYSTORE_B64

# google-services.json
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("client_flutter_app\android\app\google-services.json")
) | Set-Clipboard   # paste into GOOGLE_SERVICES_JSON_B64
```

For the current debug keystore the values are the Android defaults:
`KEYSTORE_PASSWORD=android`, `KEY_PASSWORD=android`, `KEY_ALIAS=androiddebugkey`.
Verify with:

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android
```

### 1.2 Confirm the local build signs with the same key

`android/app/build.gradle.kts` signs releases with `android/key.properties` when
present, and falls back to the debug key otherwise. Local machines have no
`key.properties`, so local release builds use `~/.android/debug.keystore` — the
same certificate uploaded as `KEYSTORE_B64`. That is what keeps local builds and
CI builds cross-installable.

---

## 2. Publishing the next version

```powershell
# 1. Bump the version in pubspec.yaml  (versionName+buildNumber)
#    e.g.  version: 1.0.1+2

# 2. Commit
git add pubspec.yaml
git commit -m "Release v1.0.1"

# 3. Tag it (tag must start with "v"; it becomes the release/version name)
git tag v1.0.1

# 4. Push the commit and the tag
git push origin main
git push origin v1.0.1
```

Then automatically:

5. GitHub Actions (`.github/workflows/release.yml`) builds a **signed** release APK.
6. A **GitHub Release** is created for the tag with the APK attached
   (`global-solar-2.0-v1.0.1.apk`).
7. Installed apps detect `1.0.1` and show the update dialog.

The tag name must match the `versionName` in `pubspec.yaml` (e.g. tag `v1.0.1`
↔ `version: 1.0.1+n`), because the app reads the version from the tag.

---

## 3. How release signing works

- `pubspec.yaml` `version:` → Flutter Gradle plugin → `versionName`/`versionCode`.
- At build time `android/app/build.gradle.kts` loads `android/key.properties`
  (generated on CI from the secrets) and signs the release build with it.
- If `key.properties` is absent (developer machine), it falls back to the debug
  signing config so `flutter build apk` keeps working with no setup.
- **Never** change the signing key once users have installed an APK — a change
  forces every device to uninstall and reinstall manually.

---

## 4. How the in-app updater works

- On launch (`MainShell`) and on demand (**Settings → App Updates**) the app calls
  the GitHub Releases API for this repository and compares the tag to the
  installed `versionName`.
- If a strictly newer release with a `.apk` asset exists, it offers to download
  and install.
- The APK is downloaded over **HTTPS** into the app cache, then handed to
  Android's package installer. Android always shows its own confirmation —
  there is **no silent install**.

### Security properties

- The repository is **public**, so the app needs **no token** — nothing secret is
  embedded in the APK. (A token would be extractable by anyone and would grant
  repository access.)
- Only `https://github.com/<this-repo>/releases/download/...` download URLs are
  accepted; anything else is refused.
- TLS certificate verification is Dart's default (enabled) and is never
  disabled. GitHub's redirect to its own CDN is followed over TLS.
- Only two permissions were added: `INTERNET` (download) and
  `REQUEST_INSTALL_PACKAGES` (hand the APK to the installer).

---

## 5. Verifying the update flow

| Scenario | How to check |
|---|---|
| A — No update | Install `1.0.1`, publish `1.0.1` → Settings shows "latest version" |
| B — Update available | Install `1.0.0`, publish `1.0.1` → dialog appears |
| C — GitHub unavailable | Turn off network, open app → app opens normally, no crash |
| D — Download fails | Interrupt the network mid-download → error dialog with **Retry** |
| E — Unknown sources off | Disable "Install unknown apps" for the app → app guides to Settings |
| F — Successful update | `1.0.0` → `1.0.1`, same package id + cert → installs as an update, data kept |

---

## 6. Limitations

- The GitHub API is queried **unauthenticated**, so it is rate-limited to ~60
  requests/hour per IP. The app checks once per launch plus manual checks — well
  within the limit.
- If the repository is ever made **private**, the token-free updater stops
  working. The only safe options are to keep it public or move release hosting
  elsewhere — do **not** embed a token in the app.
- The downloaded APK lives in the app cache; Android may clear it, but the
  install is immediate.
- Some OEM Android skins label the "Install unknown apps" screen differently.
- An OS-level package-installer security dialog is always shown; that is by
  design and cannot be bypassed.
- iOS is not covered by this mechanism (Android APK updates only).
