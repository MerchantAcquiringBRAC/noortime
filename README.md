# NoorTime – Prayer Times & Adhan

A focused iOS prayer-time app (SwiftUI, MVVM). Built without a local Mac using GitHub + Codemagic.

## Status

**Phase 3 of 7 – GPS and manual city selection.**

- Prayer times are now calculated with [Adhan Swift](https://github.com/batoulapps/adhan-swift) 1.5.0.
- Default: Karachi method, Hanafi Asr, starting city = Dhaka.
- Tap the city name on the home screen to use GPS ("Use my current location") or pick a city.
- GPS is asked for only when you tap the button, gives one position (no tracking), and is rounded to about 1 km.
- The chosen place is saved on the phone, so it works offline after a restart.
- If GPS is off or denied, the app explains how to enable it and you can pick a city instead.
- Unit tests run automatically in the cloud build.

> These are **calculated** times, not an official timetable. They have not yet been compared
> with a Bangladesh local timetable, so do not describe them as officially accurate.

## What you do from your iPhone vs. what needs a cloud Mac

| Task | Where |
|---|---|
| Read code, create GitHub repo, upload files | iPhone (Safari / GitHub app) |
| Connect repo to Codemagic, start builds | iPhone (Safari) |
| Compile the app and run tests (needs Xcode) | Codemagic cloud Mac |
| Install on your iPhone for testing | TestFlight (Phase 7, needs Apple Developer account) |

## Beginner steps (build and test)

1. Create a **private** repository on github.com named `noortime` (or reuse the Phase 1 one).
2. Upload the contents of this folder, **replacing** the Phase 1 files. Keep the folder structure.
3. Sign in to codemagic.io with GitHub and add the repository.
4. Choose the **codemagic.yaml** configuration and start the `ios-build-and-test` workflow.
5. Green build = the code compiles and all tests pass. Red build: open the log, copy the error text and send it to me.

## Project layout

```
project.yml            XcodeGen recipe (the .xcodeproj is generated in the cloud)
codemagic.yaml         cloud build + test recipe
NoorTime/
  App/                 app entry point
  Core/DesignSystem/   colours, spacing, card style
  Models/              Prayer, City, PrayerLocation, calculation settings
  Services/            Adhan calculation, schedule, GPS (CoreLocation), geocoding, saved place
  Utilities/           time formatting, bundle helper
  ViewModels/          HomeViewModel
  Views/               Home and Settings screens
  Resources/           Assets (app icon), Cities.json, en/bn Localizable.strings
NoorTimeTests/         unit tests
```

## Adding a country or city later

Add an entry to `NoorTime/Resources/Cities.json` (name in English and Bengali, country code,
latitude, longitude, IANA time zone). No code changes are needed.

## Notes

- Bundle ID `com.yourcompany.noortime` is a placeholder; change it in `project.yml` before TestFlight.
- No secrets (certificates, keys, passwords) belong in this repository.
- Privacy: NoorTime has no server. To show a city name for GPS, iOS itself may send the rounded
  coordinate to Apple's map service (this is stated in the app).
- Not covered yet: notifications and Adhan sound (Phase 4),
  settings, language switch, themes (Phase 5).
