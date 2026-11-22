# Building Ovara for Android and iOS

This explains how to turn the Godot project in `game/` into an Android package and an iOS project. The repository holds no signing material. You enter signing details on your own machine, and they stay there.

Agents cannot run these builds: they need the SDKs, a Mac and devices. Run them yourself.

## 1. Prerequisites

Install these once.

- **Godot 4.7 or newer**, the same version the project was made with. Download it from godotengine.org.
- **Export templates** for that exact version. In the Godot editor: Editor > Manage Export Templates > Download and Install. Headless exports fail without them.
- **Android:** a JDK (17 or newer) and the Android SDK with its command-line tools. Install them with Android Studio or the standalone SDK manager.
- **iOS:** a Mac with Xcode, and an Apple Developer account. Apple Silicon is needed to run the exported project on a Mac.

Check that Godot can find the Android tools: Editor > Editor Settings > Export > Android. Set the JDK path and the Android SDK path there.

## 2. Signing: keep it local

Signing details are never committed. Use one of these three ways to enter them.

1. **Editor Settings.** Editor > Editor Settings > Export > Android: set the debug and release keystore paths and their user and password.
2. **Environment variables**, for headless builds. Set these in your shell before you export:
   - `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER`, `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD`
   - `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`
3. **The export dialog.** Project > Export > Android: the keystore fields are there.

Whichever you use, Godot writes the values to `game/.godot/export_credentials.cfg`. That file is git-ignored. Keystores (`*.keystore`, `*.jks`) and provisioning profiles (`*.mobileprovision`, `*.p12`) are git-ignored too. Never move any of them into the repository, and never paste a password into a commit, a task file or a chat.

For iOS, sign in to Xcode with your Apple ID. Xcode manages the certificate and provisioning profile on your Mac.

## 3. Owner step: create the export presets

The repository does not contain `game/export_presets.cfg` yet. Its draft is in `docs/build/presets-draft.txt`. It has one Android preset and one iOS preset, and every signing field is empty.

1. Copy the draft:

   ```sh
   cp docs/build/presets-draft.txt game/export_presets.cfg
   ```

2. Open `game/export_presets.cfg` and replace each `REPLACE_com.example.ovara` with your own reverse-DNS identifier, for example `com.yourname.ovara`. Use the same identifier for Android (`package/unique_name`) and iOS (`application/bundle_identifier`).
3. Open the project once in the Godot editor, or run the first export below. Godot may rewrite the file with its own defaults. That is expected. Do not add any signing value to it.
4. Commit `game/export_presets.cfg` only after you have checked that it has no keystore path, password, team ID or profile UUID in it.

## 4. Android build

Run these from the repository root. `../export/` is relative to `game/`, so the output goes to `export/` at the top of the repository. That folder is git-ignored.

**Debug build** (for installing on your own phone):

```sh
godot --headless --path game --export-debug "Android" ../export/ovara.apk
```

**Release build** (for the Play Store):

```sh
godot --headless --path game --export-release "Android" ../export/ovara-release.aab
```

The release build uses the release keystore. If you have not set it, Godot stops with an error. Set it using one of the methods in section 2.

Install the debug APK on a phone with USB debugging on:

```sh
adb install -r ../export/ovara.apk
```

Check the result on a real phone. A desktop window is not enough.

## 5. iOS build

The iOS export writes an Xcode project. It does not write an app you can install directly.

```sh
godot --headless --path game --export-debug "iOS" ../export/ios/Ovara
```

Use `--export-release "iOS"` for a release project. Then:

1. Open the `.xcodeproj` inside `export/ios/Ovara/` in Xcode.
2. In Xcode's Signing & Capabilities, select your team. Xcode creates the provisioning profile for you.
3. Choose a real iPhone connected by cable, or an Apple Silicon Mac as the destination, and press Run.

**Simulator:** this guide does not assume that an iOS export runs in the iOS Simulator. Godot's documentation has said it is not supported. Test on a real device or on an Apple Silicon Mac. Read the current "Exporting for iOS" page in the Godot documentation before you rely on any other route.

## 6. Notes

- Use the same Godot version for every export. Mixing versions breaks templates and presets.
- The version numbers in `game/export_presets.cfg` (`version/code`, `version/name`) are yours to raise for each store upload. Store listings, age ratings and privacy policies are handled separately, by the owner.
- Nothing in this guide adds a signing file to the repository. If a step seems to need one, stop and ask the owner.
- Before a build leaves your machine, run `bash ov check` from the repository root.
