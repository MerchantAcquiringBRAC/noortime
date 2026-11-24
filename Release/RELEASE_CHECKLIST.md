# NoorTime V1.0 release checklist

Tick each item. Do not submit until every box is ticked.

## A. Must-do before TestFlight
- [ ] Codemagic `ios-build-and-test` is green (compiles, all unit tests pass)
- [ ] Optional: `ios-ui-smoke-test` is green
- [ ] Change bundle IDs in `project.yml` (`com.yourcompany...`) to your own, e.g. `com.yourname.noortime`
- [ ] Apple Developer Program account (paid) active
- [ ] Replace `adhan_short.wav` with a licensed short Adhan (< 30 s); fill in `LICENSES.md`
- [ ] Paste the Adhan Swift MIT license text and copyright line into `LICENSES.md`

## B. Test on a real iPhone (TestFlight, Phase 7)
- [ ] Fresh install: Home shows Dhaka times, no pop-up appears by itself
- [ ] Tap "Use my current location": allow, deny, and denied-then-Settings paths all behave
- [ ] Enable reminders: pop-up appears only after the tap; reminders arrive at the right time with sound
- [ ] Silent switch / Focus: understand and accept that sound may not play
- [ ] Switch language English <-> Bengali: everything changes, digits are Bengali
- [ ] Light / Dark / System theme
- [ ] Asr Hanafi <-> Shafi changes Asr time and the reminder
- [ ] Minute adjustments change the home screen and reminders
- [ ] Airplane mode: times still show
- [ ] Kill and reopen app: choices are remembered
- [ ] Large text size (Settings > Accessibility > Display & Text Size) still readable
- [ ] VoiceOver reads prayer rows and countdown sensibly

## C. Accuracy check (do not skip)
- [ ] Compare 7 days of Dhaka (and one more city) with a trusted Bangladesh timetable
      (e.g. Islamic Foundation Bangladesh). Note differences per prayer.
- [ ] Use the minute adjustments or change the default only if differences are consistent
- [ ] Until this is done, never call the times "official" or "accurate"

## D. App Store Connect
- [ ] App icon 1024x1024 (done, no alpha) - look at it on a real phone
- [ ] Screenshots: 6.7" or 6.9" iPhone (required), English and Bengali
- [ ] Name, subtitle, keywords, description: see `APP_STORE_TEXT.md`
- [ ] Privacy policy published at a public URL (e.g. GitHub Pages) from `PRIVACY_POLICY.md`; fill date and email
- [ ] Support URL (page or email contact page)
- [ ] App Privacy: Data Not Collected
- [ ] Age rating questionnaire
- [ ] Export compliance: app uses no custom encryption -> answer accordingly (`ITSAppUsesNonExemptEncryption` = NO can be added in Phase 7)
- [ ] Review notes: explain that GPS is optional and a city can be chosen; no login needed
- [ ] Audio licence proof saved

## E. Known limits to keep in the description
- Calculated times, may differ from local timetables
- Reminder sound is short; iOS Silent/Focus rules apply
- Reminders cover 12 days; open the app at least that often
