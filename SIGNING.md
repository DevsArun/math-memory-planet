# 🔐 Signing Kit (ek baar karna hai, 5 min)

Amazon APK ko **re-sign NAHI** karta — isliye private release keystore zaroori hai (rejection #1 lesson). Sab kuch **GitHub Codespaces** (free, browser terminal) se hoga. Laptop par kuch install nahi.

## STEP 1 — Codespace kholo
Repo → **Code → Codespaces → Create codespace on main**. Terminal milega.

## STEP 2 — Keystore banao (RSA 4096, 10000 din)
Terminal mein paste karo:

```bash
keytool -genkeypair -v \
  -keystore mathmemoryplanet.jks \
  -alias mathmemoryplanet \
  -keyalg RSA -keysize 4096 -validity 10000
```

- **Password** puchhega (2 baar): ek strong password banao aur **kahin likh lo** (yehi `SIGNING_STORE_PASSWORD` aur `SIGNING_KEY_PASSWORD` dono ke liye use karo — simple rakhte hain, dono SAME).
- Naam/City etc. puchhe to Enter dabate jao (kids app ke liye ye fields matter nahi karte), end mein `yes`.

## STEP 3 — Base64 banao

```bash
base64 -w 0 mathmemoryplanet.jks > keystore.b64
cat keystore.b64
```
Output (ek lambi single line) **copy karo** → ye hai `SIGNING_KEYSTORE_BASE64`.

## STEP 4 — Apna cert SHA-256 note karo (CI verify isko match karega)

```bash
keytool -list -v -keystore mathmemoryplanet.jks -alias mathmemoryplanet | grep SHA256
```
Ye fingerprint **save kar lo** — CI build isse compare karta hai (galat key = build fail = safe).

## STEP 5 — GitHub Secrets daalo
Repo → **Settings → Secrets and variables → Actions → New repository secret** — 4 secrets:

| Secret | Value |
|---|---|
| `SIGNING_KEYSTORE_BASE64` | STEP 3 ki lambi line |
| `SIGNING_STORE_PASSWORD` | tumhara keystore password |
| `SIGNING_KEY_PASSWORD` | same password (same rakha tha) |
| `SIGNING_KEY_ALIAS` | `mathmemoryplanet` |

## STEP 6 — Keystore file SAFE rakho
- `mathmemoryplanet.jks` ko Codespace se **download** karke Google Drive / 2 jagah backup lo.
- Ye file kho gayi to Amazon par app **kabhi update nahi** kar paoge (naya keystore = nayi app listing).
- Kabhi bhi `.jks` ya `key.properties` ko git mein commit MAT karo (`.gitignore` mein already blocked hai).

## Kaise kaam karta hai (CI)
Workflow secrets se `android/key.properties` + `release.jks` banata hai → release APK sign hota hai → `apksigner verify --verbose --print-certs` se **V2 Signer SHA-256** tumhare keystore se match hota hai → "Android Debug" milte hi build FAIL. Isliye debug-signed APK galti se bhi Amazon nahi ja sakta.
