# Building Ovara for Android and iOS

This explains how to turn the Godot project in `game/` into an Android package and an iOS project. The repository holds no signing material. You enter signing details on your own machine, and they stay there.

Agents cannot run these builds: they need the SDKs, a Mac and devices. Run them yourself.

## 1. Prerequisites

Install these once.

- **Godot 4.7 or newer**, the same version the project was made with. Download it from godotengine.org.
- **Export templates** for that exact version. In the Godot editor: Editor > Manage Export Templates > Download and Install. Headless exports fail without them.
- **Android:** a JDK 17 and the Android SDK with its command-line tools. Install them with Android Studio or the standalone SDK manager.
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

## 3. The export presets

`game/export_presets.cfg` holds two presets: `Android` and `iOS`. The bundle id is `com.ovara.game` for both (`package/unique_name` on Android, `application/bundle_identifier` on iOS). Every signing field in the file is empty. Do not add a keystore path, password, Apple team id or profile id to it, and do not commit one.

Godot may rewrite the file with its own defaults when you open the project. Before you commit, check that it still holds no signing value.

## 4. Android build

Run these from the repository root. `../build/` is relative to `game/`, so the output goes to `build/` at the top of the repository. That folder is git-ignored.

**Debug build** (for installing on your own phone):

```sh
godot --headless --path game --export-debug "Android" ../build/ovara.apk
```

**Release build** (for the Play Store):

```sh
godot --headless --path game --export-release "Android" ../build/ovara-release.aab
```

The release build uses the release keystore. If you have not set it, Godot stops with an error. Set it using one of the methods in section 2.

Install the debug APK on a phone with USB debugging on:

```sh
adb install -r ../build/ovara.apk
```

Check the result on a real phone. A desktop window is not enough.

## 5. iOS build

The iOS export writes an Xcode project. It does not write an app you can install directly.

```sh
godot --headless --path game --export-debug "iOS" ../build/ios/Ovara
```

Use `--export-release "iOS"` for a release project. Then:

1. Open the `.xcodeproj` inside `build/ios/Ovara/` in Xcode.
2. In Xcode's Signing & Capabilities, select your team. Xcode creates the provisioning profile for you.
3. Choose a real iPhone connected by cable, or an Apple Silicon Mac as the destination, and press Run.

**Simulator:** this guide does not assume that an iOS export runs in the iOS Simulator. Godot's documentation has said it is not supported. Test on a real device or on an Apple Silicon Mac. Read the current "Exporting for iOS" page in the Godot documentation before you rely on any other route.

## 6. Notes

- Use the same Godot version for every export. Mixing versions breaks templates and presets.
- The version numbers in `game/export_presets.cfg` (`version/code`, `version/name`) are yours to raise for each store upload. Store listings, age ratings and privacy policies are handled separately, by the owner.
- Nothing in this guide adds a signing file to the repository. If a step seems to need one, stop and ask the owner.
- Before a build leaves your machine, run `bash ov check` from the repository root.

## 7. What only the owner can do

Workers cannot do any of these. You must:

- Install Godot, the export templates, the JDK 17, the Android SDK and Xcode.
- Create and hold the Android keystore, and hold the Apple team id and Apple Developer account.
- Enter signing details in Editor Settings or the `GODOT_ANDROID_KEYSTORE_*` variables, on your machine only.
- Sign the builds and upload them to the stores.
- Run the builds on real phones and look at the result.
