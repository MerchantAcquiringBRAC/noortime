# NoorTime – Prayer Times & Adhan

A focused iOS prayer-time app (SwiftUI, MVVM). Built without a local Mac using GitHub + Codemagic.

## Status

**Phase 1 of 7 – project setup and home screen UI.**
Prayer times shown are *sample values only*. Real calculation (Adhan Swift 1.5.0) is Phase 2.

## What you do from your iPhone vs. what needs a cloud Mac

| Task | Where |
|---|---|
| Read code, create GitHub repo, upload files | iPhone (Safari / GitHub app) |
| Connect repo to Codemagic, start builds | iPhone (Safari) |
| Compile the app (needs Xcode) | Codemagic cloud Mac |
| Install on your iPhone for testing | TestFlight (Phase 7, needs Apple Developer account) |

## Beginner steps (first build check)

1. Create a **private** repository on github.com named `noortime`.
2. Upload the contents of this folder (keep the folder structure: `NoorTime/`, `project.yml`, `codemagic.yaml`, `.gitignore`, `README.md`).
3. Sign in to codemagic.io with GitHub and add the `noortime` repository.
4. Choose the **codemagic.yaml** configuration and start the `ios-build-check` workflow.
5. A green build means the code compiles. A red build: open the log and send me the error text.

## Project layout

```
project.yml            XcodeGen recipe (the .xcodeproj is generated in the cloud)
codemagic.yaml         cloud build recipe
NoorTime/
  App/                 app entry point
  Core/DesignSystem/   colours, spacing, card style
  Models/              Prayer, PrayerEntry, NotificationStatus
  Utilities/           time formatting
  ViewModels/          HomeViewModel
  Views/Home, Settings screens
  Resources/           Assets, en/bn Localizable.strings
```

## Notes

- Bundle ID `com.yourcompany.noortime` is a placeholder; change it in `project.yml` before TestFlight.
- No secrets (certificates, keys, passwords) belong in this repository.
- Prayer times are calculations, not an official timetable, until verified against local sources.
