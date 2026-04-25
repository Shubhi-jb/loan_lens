# 🛡️ LoanLens Guardian

> **Empowering vulnerable borrowers with AI-driven fairness auditing.**

LoanLens Guardian is a voice-first, high-accessibility mobile app built for India's lending market. It uses **Google Gemini 2.5 Flash** to analyze loan documents and spoken loan offers in real-time — detecting predatory interest rates, RBI compliance violations, illegal permission requests, and algorithmic bias against marginalized communities.

---

## ✨ Key Features

- **Guardian Audit** — Instant scan of loan documents (camera or gallery) against RBI 2025/2026 digital lending guidelines
- **Voice-First Accessibility** — Describe a loan offer by speaking; the app transcribes, analyzes, and reads back the verdict in your language
- **11 Indian Languages** — Full UI and TTS support for Hindi, Marathi, Tamil, Telugu, Bengali, Gujarati, Kannada, Malayalam, Punjabi, Odia, and English
- **Bias Detection** — Identifies demographic, geographic, and employment-type proxy signals in lending terms
- **Fairness Scorecard** — Risk score from 1–10 with a detailed breakdown of violations, warnings, and an action plan
- **RBI Action Link** — Direct link to the RBI complaint portal when predatory practices are detected
- **Anonymous Audit Telemetry** — Opt-in anonymous scan data contributed to Firebase to help track predatory lending patterns

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| AI Engine | Google Gemini 2.5 Flash Lite |
| Backend | Firebase (Firestore, Remote Config, App Check) |
| Local Storage | Hive (offline-first scan history) |
| Voice Input | speech_to_text |
| Voice Output | flutter_tts |
| Secrets | flutter_dotenv |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.10.4`
- Android Studio or Xcode (for device/emulator)
- A [Google Gemini API Key](https://aistudio.google.com/app/apikey) (free tier available)
- A Firebase project with Android app registered ([setup guide](https://firebase.google.com/docs/flutter/setup))

---

### 1. Clone the repository

```bash
git clone https://github.com/shubhi-jb/loan_lens.git
cd loan_lens
```

---

### 2. Set up your environment variables

This project uses `flutter_dotenv` to load secrets. You **must** create a `.env` file in the project root — it is gitignored and will never be committed.

```bash
# In the project root (MacOS/Linux):
cp .env.example .env

# On Windows:
copy .env.example .env
```

Then open `.env` and fill in your key:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

> ⚠️ **Never commit your `.env` file.** It is listed in `.gitignore`. If you accidentally push it, rotate your Gemini API key immediately at [Google AI Studio](https://aistudio.google.com/).

---

### 3. Add Firebase configuration

This app uses Firebase (Firestore + Remote Config + App Check). The `google-services.json` file is **gitignored** for security.

1. Go to your [Firebase Console](https://console.firebase.google.com/)
2. Select your project → Project Settings → Your apps → Android app
3. Download `google-services.json`
4. Place it at `android/app/google-services.json`

> If you don't have a Firebase project yet, follow the [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview). The app will gracefully handle offline mode if Firebase is unavailable.

---

### 4. Install dependencies

```bash
flutter pub get
```

---

### 5. Run the app

```bash
flutter run
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/       # Language constants, supported locales
│   ├── services/        # Hive local storage service
│   └── theme/           # App theme, color tokens
├── features/
│   ├── analysis/        # Gemini AI analysis, result screens, scan history
│   ├── config/          # Firebase Remote Config service
│   ├── database/        # Firestore telemetry service
│   ├── home/            # Home screen, ambient UI
│   ├── onboarding/      # First-run onboarding flow
│   └── voice/           # Speech-to-text, language selection, TTS
└── main.dart
```

---

## 🔐 Security Notes

- **API keys** are loaded at runtime from `.env` via `flutter_dotenv` — not hardcoded
- **Firestore writes** only occur with explicit user opt-in (consent dialog before every scan)
- **Anonymous telemetry only** — no PII is ever written to Firestore (risk score, bias type, and app name only)
- **Firebase App Check** is configured to protect backend resources

---

## 🧪 How the Risk Scoring Works

The Gemini model applies RBI 2025/2026 digital lending guidelines:

| Score | Level | Trigger Conditions |
|---|---|---|
| 8–10 | ✅ Safe | No violations, APR < 24% |
| 5–7 | ⚠️ Moderate Risk | Minor warnings, APR 24–45% |
| 1–4 | 🚨 High Risk / Predatory | APR > 45%, illegal permissions, missing KFS, or demographic targeting |

A score of 1–4 always triggers the RBI complaint portal link and regulated loan alternatives (Mudra, PM SVANidhi).

---

## 🙌 Acknowledgements

- [Google Gemini API](https://ai.google.com/) for the AI analysis engine
- [Reserve Bank of India Digital Lending Guidelines](https://rbi.org.in/) for the compliance framework
- The Flutter and Firebase open-source communities
