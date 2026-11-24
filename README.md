# NoorTime – Prayer Times & Adhan

A focused iOS prayer-time app (SwiftUI, MVVM). Built without a local Mac using GitHub + Codemagic.

## Status

**Phase 6 of 7 – testing, release preparation.**

- New: `Release/` folder (release checklist, privacy policy draft, App Store text), UI smoke tests (`NoorTimeUITests`, separate Codemagic workflow `ios-ui-smoke-test`).
- Phase 5 features below are unchanged.

- Prayer times are now calculated with [Adhan Swift](https://github.com/batoulapps/adhan-swift) 1.5.0.
- Default: Karachi method, Hanafi Asr, starting city = Dhaka.
- Tap the city name on the home screen to use GPS ("Use my current location") or pick a city.
- GPS is asked for only when you tap the button, gives one position (no tracking), and is rounded to about 1 km.
- The chosen place is saved on the phone, so it works offline after a restart.
- If GPS is off or denied, the app explains how to enable it and you can pick a city instead.
- Reminders: tap the "Prayer reminders" card on the home screen (the iOS pop-up appears only after you tap).
  Each of the five prayers can be switched on or off in Settings. Sunrise has no reminder.
- Reminders cover the next 12 days (60 reminders, under the iOS limit of 64) and are rebuilt whenever
  the app opens, the place changes, or a prayer is switched on/off. Open the app at least every 12 days.
- Reminders only use iOS local notifications. Nothing depends on background running.
- Settings has a "Play preview" button for the reminder sound.
- Settings (gear icon on the home screen):
  - Language: English, বাংলা, or same as iPhone. Changes the whole app at once, including reminder text.
    (Standard iOS parts such as the search bar's "Cancel" follow the iPhone's language.)
  - Theme: light, dark, or same as iPhone.
  - Calculation: method (Karachi default) and Asr school (Hanafi default).
  - Manual adjustments: add or subtract up to 30 minutes per prayer to match a local mosque timetable.
    Both the home screen and the reminders use the adjusted times. Everything starts at zero.
  - All choices are saved on the phone.
- In Bengali, times, dates and the countdown use Bengali digits (০-৯).
- Unit tests run automatically in the cloud build.

### IMPORTANT – the reminder sound is a placeholder

`NoorTime/Resources/Sounds/adhan_short.wav` is an original chime made for this project, **not an Adhan**.
Before release, replace it with a properly licensed short Adhan:
1. Under 30 seconds (iOS replaces longer sounds with the default sound). WAV, AIFF or CAF.
2. Keep the exact file name `adhan_short.wav` (or update `NotificationSound.swift`).
3. Write the source and license in `LICENSES.md`.

Even then, iOS decides whether the sound plays: it follows the Silent switch, Focus modes and
notification settings. The app says this in Settings. A full-length Adhan cannot play from a
closed app, so do not promise it in the App Store description.

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
  Services/            Adhan calculation, schedule, GPS, geocoding, saved place, reminder planner/scheduler
  Utilities/           time formatting, bundle helper
  ViewModels/          HomeViewModel
  Views/               Home and Settings screens
  Resources/           Assets (app icon), Cities.json, Sounds/, en/bn Localizable.strings
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
- Not covered yet: GitHub and Codemagic signing / TestFlight configuration (Phase 7).
