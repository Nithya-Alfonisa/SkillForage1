# SkillForge AI

An adaptive AI-powered technical learning platform built with Flutter (Dart, Material 3).

**Learning loop:** Goal selection → LearningState → activity (lesson / SQL visualizer) → adaptive quiz → score and feedback → mastery update → next recommendation.

## Build status

This source was written in an environment with no Flutter SDK, no Android SDK and blocked
downloads, so **it has not been compiled, analysed, tested or built there**. Follow the steps
below on a machine with Flutter to produce the APK.

## Build the APK

```bash
# 1. install Flutter (stable) + Android Studio / Android SDK, then:
cd skillforge_ai
bash setup.sh                 # generates android/ for your Flutter version, adds INTERNET permission
flutter analyze
flutter test
flutter build apk --release   # -> build/app/outputs/flutter-apk/app-release.apk
```

The release APK is signed with the debug key by default (fine for demos and sideloading).
For Play Store distribution configure a real keystore.

### Enabling Gemini (optional)

The app works fully without it, using the built-in rule-based engine. To enable Gemini, pass a key at build or run time. It is never stored in source:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
flutter build apk --release --dart-define=GEMINI_API_KEY=YOUR_KEY
# optional: --dart-define=GEMINI_MODEL=<model name>   (default: gemini-2.5-flash)
```

Keys compiled into an APK can be extracted. Use a restricted key, or proxy requests through your own backend, for anything public.

## Structure

```
lib/
  main.dart
  theme.dart
  models/        learning_state, learning_activity, quiz_question, quiz_result
  data/          content_repository (skills, lessons, 54 questions)
  services/      ai_service (abstract), gemini_ai_service, adaptive_learning_service,
                 join_engine, quiz_session
  state/         app_controller (ChangeNotifier)
  features/      onboarding, workspace, visualizer, quiz
  widgets/       shared cards, chips, AI banner
test/            unit + widget tests
```

## Adaptive rules (all deterministic)

| Quiz score | Mastery | Difficulty | Weakness / strength |
|---|---|---|---|
| ≥ 80% | +0.20 | steps up | topic → strengths, advances to next topic |
| 50–79% | +0.08 | unchanged | two mediocre attempts in a row → weakness |
| < 50% | −0.05 | steps down | topic → weaknesses |

Recommendation: mastery < 0.4 → revision (visualizer or lesson) on the weakest topic; 0.4–0.7 → practice quiz; ≥ 0.7 → advanced quiz / next topic.

## Demo flow

Select **SQL & Databases** → workspace shows the recommendation → open **Visualizer** → toggle INNER / LEFT JOIN (tap a student row to inspect it) → **JOIN quiz** → results show mastery change, difficulty change, strengths/weaknesses and the next recommendation.

## No local install? Build in the cloud (GitHub Actions)

1. Create a new GitHub repository and upload the contents of this folder (including the hidden `.github` folder).
2. Open the **Actions** tab, choose **Build APK**, and click **Run workflow** (it also runs on every push to `main`).
3. When the run finishes, open it and download the **skillforge-ai-apk** artifact. It contains `app-release.apk`.
4. Copy the APK to your Android phone and install it (allow "install unknown apps" when prompted).

The workflow runs `flutter analyze`, `flutter test` and the release build, so the Actions log shows real analyze/test results.
