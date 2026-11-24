# GitHub + Codemagic + TestFlight guide (from an iPhone, no Mac)

Never put certificates, `.p8` keys, passwords or tokens in GitHub. The `.gitignore` blocks common ones.

## Part 1 – GitHub
1. github.com > New repository > name `noortime` > **Private** > Create.
2. Upload the project folder contents (keep the folders). Upload in a few batches if needed.
   `.xcodeproj` is not needed; it is generated in the cloud.
3. Commit with the message from the phase.

## Part 2 – Codemagic (build + test)
1. codemagic.io > sign in with GitHub > Add application > choose `noortime`.
2. Choose **codemagic.yaml** as the configuration.
3. Start workflow `ios-build-and-test`. Green = compiles + tests pass.

## Part 3 – Apple side (needs the paid Apple Developer Program)
1. developer.apple.com > Certificates, Identifiers & Profiles > Identifiers > **+** > App IDs > App.
   Bundle ID (Explicit): your own, e.g. `com.yourname.noortime`. Description: NoorTime.
2. Edit `project.yml` (3 places: app, tests, UI tests, all starting with the same prefix) and
   `codemagic.yaml` (`bundle_identifier`) to match. Keep them identical.
3. appstoreconnect.apple.com > Apps > **+** New App: iOS, name NoorTime, language English,
   Bundle ID = the one above, SKU any text (e.g. `noortime1`).
4. In the app page > App Information, copy the **Apple ID** (a number). Put it in `codemagic.yaml`
   at `APP_STORE_APPLE_ID` (it is not a secret).
5. App Store Connect > Users and Access > Integrations > App Store Connect API > generate a key
   (access: **App Manager**). Download the `.p8` file once. Keep it private. Note Issuer ID and Key ID.

## Part 4 – Connect Apple to Codemagic
1. Codemagic > Teams > Personal account (or team) > Integrations > App Store Connect > Connect.
2. Name it exactly **NoorTime-ASC**. Upload the `.p8`, enter Issuer ID and Key ID.
3. Codemagic creates the signing certificate and profile for you (automatic signing in the workflow).

## Part 5 – Send a build to TestFlight
1. Push the changed files to GitHub.
2. Start workflow `ios-testflight`. It sets a new build number, signs, builds and uploads.
3. After about 10-30 minutes, App Store Connect > TestFlight > the build appears (Apple "processing").
4. Add yourself as an Internal Tester, install the TestFlight app on your iPhone, install NoorTime.
5. Run the real-phone tests in `RELEASE_CHECKLIST.md` section B.

## Common errors
| Error | Meaning / fix |
|---|---|
| `integration NoorTime-ASC not found` | Integration name differs. Use exactly `NoorTime-ASC`. |
| `No matching profiles` / bundle id error | Bundle ID in `project.yml` and `codemagic.yaml` differ, or the App ID is not created. |
| `The bundle version must be higher` | Build number clash. The workflow auto-increments; check `APP_STORE_APPLE_ID` is right. |
| Build number stays 1 | `APP_STORE_APPLE_ID` still `0000000000`. |
| Missing compliance | Already answered by `ITSAppUsesNonExemptEncryption: false`. |
| 401 / key error | Wrong Issuer ID / Key ID / `.p8`, or key access too low. Create an App Manager key. |

## Before App Store review
Finish `RELEASE_CHECKLIST.md`. Real Adhan with a licence, accuracy check and privacy policy URL are required for honesty and review.
