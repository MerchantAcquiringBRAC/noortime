# Install NoorTime without TestFlight (third-party sideloading)

Honest limits: with a FREE Apple ID the app stops opening after **7 days** and must be re-installed/refreshed;
max 3 apps; you need a **Windows PC or Mac** for AltStore/Sideloadly. Apple does not allow installing an app from a file on iPhone alone.

1. Codemagic > run workflow `ios-unsigned-ipa` > download `NoorTime.ipa` from the build's Artifacts.
2. On a PC/Mac install **Sideloadly** (sideloadly.io) or **AltStore** (altstore.io). Follow their official steps.
3. Connect iPhone by cable, trust the computer, enable Developer Mode (Settings > Privacy & Security > Developer Mode).
4. Choose NoorTime.ipa, sign in with your Apple ID (use a spare one if you prefer), press Start.
5. iPhone: Settings > General > VPN & Device Management > trust your Apple ID.
6. Refresh every 7 days (AltStore can auto-refresh on the same Wi-Fi as the computer).

Never give your Apple ID password to unknown "signing" websites.
