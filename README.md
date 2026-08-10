# 🪐 Math Memory Planet (com.itschool.mathmemoryplanet)

Kids memory + math card games. **Paid app ($4.99), 100% offline, no ads, no IAP, no data collection.**
Flutter app → GitHub Actions build → Amazon Appstore (Fire Tablets).

---

## ⚡ Quickstart (15 min, laptop par kuch install NAHI karna)

### 1. GitHub repo banao
- github.com → **New repository** → naam: `math-memory-planet` → Private OK → **Create** (README add mat karo, empty repo).

### 2. Files upload karo
**Sabse aasan (web):**
- Is ZIP ko apne computer par extract karo.
- Repo page → **Add file → Upload files** → extracted folder ka **saara content** drag-drop karo (`.github`, `lib`, `assets`, `ci`, `icon_res`, `store`, `test` + sab files — `.gitignore` bhi).
- **Commit changes**.

**Ya Codespaces se:**
- Repo → **Code → Codespaces → Create** → terminal mein ZIP upload karke: `unzip math-memory-planet-1.0.0.zip -d .` → phir `git add -A && git commit -m "v1.0.0" && git push`.

### 3. Signing ke 4 Secrets daalo (pehli baar, 5 min)
👉 **SIGNING.md** kholo aur steps follow karo. Iske bina release APK nahi banega.
Secrets: `SIGNING_KEYSTORE_BASE64`, `SIGNING_STORE_PASSWORD`, `SIGNING_KEY_PASSWORD`, `SIGNING_KEY_ALIAS`.

### 4. Build chalao
- **Actions** tab → workflow `build-apk` → automatically push par bhi chalega.
- Green ✅ hone par neeche **2 artifacts** milenge:

| Artifact | Kiske liye |
|---|---|
| **AMAZON-UPLOAD-signed-release** | Sirf ye Amazon Appstore par upload karo ✅ |
| **APPETIZE-ONLY-debug** | Sirf testing (Appetize.io / apna tablet) — Amazon par KABHI NAHI ⛔ |

### 5. Test karo
- Appetize.io → free account → **Upload** → `app-debug.apk` → Play. (Ya apne Android tablet par `app-debug.apk` install karo.)
- Check: 7 planets khulte hain, levels chalte hain, sounds, parental gate (⚙️ → `6×8` type sawaal), portrait + landscape dono.

### 6. Amazon submission
- Build pass hone ke baad mujhe bolo — main **STEP 14** mein Console ka har screen ek-ek karke walkthrough dunga.
- Store listing text + privacy policy ready hai: **STORE_LISTING.md** / **PRIVACY_POLICY.md**.

---

## 🔁 Update rule (J12 - bahut important)
Har fix/update par `pubspec.yaml` mein version badhao: `1.0.0+1` → `1.0.1+2` (versionCode hamesha BADA hona chahiye, warna Amazon reject karega). `lib/state.dart` mein `kAppVersion` bhi same rakho.

## 🧱 Project map
```
lib/            app code (7 game modes, 210 levels, 7 languages)
test/           generator + widget tests (CI blocking)
assets/audio/   8 bundled sfx (tap/flip/match/wrong/win/star/streak/button)
icon_res/       launcher icons (5 densities) - CI android/ mein copy karta hai
store/          icon_512.png + banner_1024x500.png (Amazon listing)
ci/android/     gradle config jo CI generated shell par apply hota hai
.github/workflows/build.yml   full CI: analyze → test → build → sign-verify
```

## ⚙️ Toolchain (locked)
Flutter 3.29.0 • Java 17 • minSdk 22 • targetSdk 34 • compileSdk 36 • NDK 28.2.13676358 • plugins: sirf `shared_preferences` + `audioplayers` • zero manifest permissions • offline only.
