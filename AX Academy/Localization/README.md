# Localization & Audio Scaffold Pipeline

This directory contains the string tables (`*.lproj/Localizable.strings`) and
placeholder audio manifests used by AX Academy.

## Adding a new locale
1. Duplicate `Base.lproj/Localizable.strings` into `<locale>.lproj/Localizable.strings`.
2. Translate each key while keeping the placeholders (such as `%d` or `%@`) intact.
3. Add an audio manifest `Localization/Audio/<locale>.json` mapping scaffold keys
   to audio file names. Drop the audio assets into the app bundle using the same
   filenames when recordings are ready.
4. Update `project.pbxproj` (or Swift Package manifest) to include the new
   string table and audio files in the app target.
5. Run `xcodebuild -scheme "AX Academy" -destination 'platform=iOS Simulator,name=iPhone 15'` to verify builds.

## Audio scaffolds
`AudioScaffoldRepository` reads the manifests and falls back to English if a
locale-specific recording is not present. This allows the team to roll out new
voiceovers incrementally without blocking the UI translation work.
