# MIGRATION_PLAN.md

## Purpose

Migrate the current "mazatalk" Flutter app from a class/era-based, alphabet-first
learning app into the topic-based, companion-driven, auto-resume adventure app
described in [version2.md](version2.md). This plan is analysis + sequencing only —
no files are changed as part of producing this document.

---

## 1. Current State Summary

- 13 Dart files total, all flat under `lib/screens/` and `lib/state/` — no
  feature folders, no service/repository layer, no Firestore integration.
- State management: a single `ChangeNotifier` (`AppSession`) backed by
  `SharedPreferences`. `flutter_riverpod` and `supabase_flutter` are declared
  in `pubspec.yaml` but **never used** anywhere in the code.
- Routing: `go_router` with 21 flat routes in `main.dart`, gated by ad-hoc
  path-set redirect logic (`_authFlowPaths`, `_childSetupPaths`, `_signupSetupPaths`).
- Auth is fully fake: hardcoded `admin@gmail.com` / `Password` check, no Firebase.
- Home experience is `MainPageScreen`, an "era" browser containing hardcoded
  alphabet/animal/counting classes — directly contradicts the new vision's
  "no home screen, always resume" requirement.
- `home_screen.dart` (1001 lines) and `therapy_and_companion.dart` (903 lines)
  are large multi-concern files mixing several unrelated screens/widgets.

---

## 2. Files to Delete

| File | Reason |
|---|---|
| `lib/screens/main_page_screen.dart` | Era/class browser — replaced by auto-resume engine, no browsing home screen in new vision. |
| `lib/screens/home_screen.dart` | Old dashboard (chat/schedule/grades tabs) — not part of new vision; `ProfileScreen`/`SettingsScreen` inside it must be extracted first (see §3) before deleting the file. |
| `lib/screens/child_select_screen.dart` | Manual child-selection screen — new flow auto-selects the active child or only supports one child profile per parent at launch. |
| `lib/screens/class_screen.dart` | Fixed 5-step "class" progression tied to the alphabet-first model — replaced by topic/lesson model. |
| `lib/screens/world_map_screen.dart` | Map browsing UI — superseded by world-generation data model + auto-resume; any reusable "map node" visuals can be salvaged into the new world-map widget (see §4), but this file as a screen-with-navigation is removed. |
| `test/widget_test.dart` | Placeholder counter smoke test, irrelevant to the real app; replace with real widget/unit tests as features land. |

**Do not delete yet (extract first):** `lib/screens/therapy_and_companion.dart`
contains `SpeechTherapyScreen`, `RobotModeScreen`, and `VillageScreen` — these
are plausible "lesson activity" modules under the new topic system and should
be split into individual files under the new structure rather than deleted.

---

## 3. Screens to Replace

| Old Screen | Replacement | Notes |
|---|---|---|
| `MainPageScreen` (home/era browser) | **Resume Engine** — no screen at all; app boot logic determines "current lesson" and routes directly into it | Core architectural change requested by version2.md. |
| `onboarding_screens.dart` → `ChildProfileScreen` + `DisabilitiesScreen` | **New onboarding flow**: name → age → visual interest-picker grid (dinosaurs, cars, trains, animals, space, princesses/fairy tales, music, ocean, art, sports) | Drop gender-based branching per version2.md's design note; disabilities step can stay as an optional later step, not blocking. |
| `WorldMapScreen` | **World Generator output screen** — renders the generated personalized lesson path/map from templates, but is entered automatically, not as a destination the user navigates "back" to as a home base | Reuse animation/visual assets if feasible; rebuild data binding against the new world-template model. |
| `ClassScreen` (5-step alphabet class flow) | **Lesson Player screen** — generic, topic-driven activity sequencer (counting/reading/colors/shapes/vocabulary/storytelling templates applied to whatever topic) | This is the single most important new screen; must be generic over topic content, not hardcoded per subject. |
| `ChildSelectScreen` | Removed / folded into onboarding — single active child auto-loads | If multi-child support is wanted later, reintroduce as a lightweight switcher, not a gate screen. |

**Screens kept largely as-is (UI reusable, wiring changes):**
- `auth_screens.dart` — keep all UI, swap fake auth for Firebase Authentication calls.
- `skin_select_screen.dart` — companion customization, fits "evolving companion" requirement directly.
- `parent_dashboard.dart` — parent-facing analytics, aligns with "parents setting up the account" target audience.

---

## 4. Models/Services That Can Be Reused

| Item | Location | Reuse plan |
|---|---|---|
| `ChildProfile` model | `lib/state/app_session.dart` | Reuse as base; extend with `interests: List<String>`, replace `completedClassIds` (flat list) with a structured `progress` map keyed by topic/lesson id, add `currentLessonId`/`currentCheckpoint` for auto-resume. |
| JSON `toJson`/`fromJson` on `ChildProfile` | same | Reuse the pattern, port it to Firestore document (de)serialization instead of `SharedPreferences`. |
| `Skin`, `SkinCatalog`, `SkinRarity` | `lib/state/skins.dart` | Reuse directly as the companion's cosmetic/unlock system — maps cleanly onto "unlockable accessories" in version2.md. |
| Coin/reward logic in `AppSession.completeClass()` | `lib/state/app_session.dart` | Reuse the reward-granting logic, rename/generalize to `completeLesson()`, trigger from the new Lesson Player. |
| Auth screen widgets (forms, validators) in `auth_screens.dart` | `lib/screens/auth_screens.dart` | Reuse UI/forms; replace the hardcoded credential check with Firebase Auth SDK calls behind a repository. |
| `SpeechTherapyScreen`/`RobotModeScreen`/`VillageScreen` widgets | `lib/screens/therapy_and_companion.dart` | Reuse as candidate "activity template" implementations once extracted into their own files and re-pointed at topic data instead of hardcoded content. |

**Not reusable / must be rebuilt:** `AppSession` itself (ChangeNotifier +
SharedPreferences) should be retired in favor of Riverpod providers backed by
Firestore — it currently has no cloud sync, no service layer, and mixes auth,
profile, and game-state concerns in one singleton.

---

## 5. New Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── router.dart                # go_router config, route guards
│   └── theme.dart                 # Material 3 theme
├── core/
│   ├── widgets/                   # shared reusable widgets (buttons, cards, loaders)
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/                  # FirebaseAuthRepository
│   │   ├── domain/                # AuthRepository interface, User entity
│   │   ├── application/           # Riverpod providers/controllers
│   │   └── presentation/          # screens: welcome, login, signup, reset, verify
│   ├── onboarding/
│   │   ├── domain/                # ChildProfile entity, Interest enum
│   │   ├── application/           # onboarding flow controller (Riverpod)
│   │   └── presentation/          # name/age screen, interest-picker grid
│   ├── world/
│   │   ├── domain/                # LessonTemplate, WorldMap, Topic entities
│   │   ├── data/                  # FirestoreWorldRepository, template generator
│   │   ├── application/           # world generation providers
│   │   └── presentation/          # generated world/map rendering widgets
│   ├── lesson/
│   │   ├── domain/                # Lesson, Activity, Checkpoint entities
│   │   ├── data/                  # FirestoreLessonRepository, progress repository
│   │   ├── application/           # resume-engine logic, lesson player controller
│   │   └── presentation/          # Lesson Player screen, activity widgets (counting, colors, vocabulary, storytelling)
│   ├── companion/
│   │   ├── domain/                # Skin/companion entities (from skins.dart)
│   │   ├── application/           # companion state providers
│   │   └── presentation/          # skin select screen, companion widget
│   └── parent/
│       └── presentation/          # parent dashboard
├── services/
│   ├── firebase_auth_service.dart
│   └── firestore_service.dart
└── shared/
    └── models/                    # cross-feature value objects if needed
```

This follows the Clean Architecture layering requested in version2.md
(`domain` = entities/interfaces, `data` = Firestore implementations,
`application` = Riverpod controllers/providers, `presentation` = widgets/screens),
applied per feature instead of per technical layer globally.

---

## 6. Step-by-Step Implementation Order

1. **Wire up Firebase** — add `firebase_core`, `firebase_auth`,
   `cloud_firestore` to `pubspec.yaml`; initialize in `main.dart`; configure
   Android app (`google-services.json`).
2. **Introduce Riverpod properly** — remove `AppSession` ChangeNotifier
   pattern, set up `ProviderScope`, create an `authStateProvider` consuming
   Firebase Auth streams.
3. **Migrate auth screens** — keep `auth_screens.dart` UI, point it at a new
   `AuthRepository` (Firebase-backed) instead of the hardcoded check; verify
   login/signup/reset/verify flows end-to-end.
4. **Build new onboarding flow** — child name/age screen + visual interest
   grid (replace `DisabilitiesScreen`-first ordering; make disabilities
   optional/later); persist `ChildProfile` to Firestore.
5. **Define world/lesson data model** — `Topic`, `LessonTemplate`, `Lesson`,
   `Activity`, `Checkpoint` entities + Firestore schema; seed a small set of
   reusable templates (counting, colors, shapes, vocabulary, storytelling)
   parameterized by topic.
6. **Build world generator** — given a child's interests + templates, produce
   a personalized lesson path; persist generated world to Firestore.
7. **Build Lesson Player (replaces `ClassScreen`)** — generic activity
   sequencer driven by the lesson/activity model, reusing reward/coin logic
   from old `completeClass()`.
8. **Build the resume engine** — on app launch, after auth, read
   `currentLessonId`/`currentCheckpoint` from the child's Firestore doc and
   route directly into the Lesson Player; this replaces `MainPageScreen` as
   the home destination.
9. **Migrate companion/skins** — port `skins.dart` and `SkinSelectScreen`
   into `features/companion/`, wire unlocks to lesson completion rewards.
10. **Re-point therapy/robot/village screens** — extract from
    `therapy_and_companion.dart`, adapt as activity templates inside
    `features/lesson/presentation/`, or keep as standalone parent-facing
    modules if they don't fit the topic model.
11. **Migrate parent dashboard** — point analytics at real Firestore progress
    data instead of placeholder numbers.
12. **Delete deprecated files** — remove `main_page_screen.dart`,
    `home_screen.dart`, `child_select_screen.dart`, `class_screen.dart`,
    `world_map_screen.dart` once their replacements are verified working.
13. **Update router** — rebuild `go_router` config in `app/router.dart`
    around: auth gate → onboarding gate → resume engine (no home route).
14. **Add tests** — replace placeholder `widget_test.dart` with real tests
    covering resume logic, world generation, and lesson completion.

---

## 7. Risks That Could Break the App

- **No service/repository layer exists today** — introducing Firestore and
  Riverpod simultaneously is a large surface area; sequence step 1–3 carefully
  and validate auth alone before touching onboarding/world data, or auth
  regressions will be hard to isolate from data-layer bugs.
- **`AppSession` is a singleton consumed by almost every screen** — removing
  it in one shot will break every screen at once; migrate consumers
  incrementally behind Riverpod providers, or keep a thin adapter during
  transition.
- **Hardcoded auth (`admin@gmail.com`/`Password`) may be used for current
  manual testing/demo** — confirm no one depends on it before ripping it out.
- **`go_router` redirect logic is currently ad-hoc path-set based** — the new
  three-gate flow (auth → onboarding → resume) must replicate all the
  guarantees the old `_authFlowPaths`/`_childSetupPaths` logic provided
  (e.g., preventing authenticated users from seeing login screens), or users
  could get stuck/looped.
- **`completedClassIds` (flat list) → structured progress map** is a breaking
  data shape change — if any persisted `SharedPreferences` data exists on
  real devices, there's no migration path defined yet; decide whether to
  wipe local state on upgrade or write a one-time migrator.
- **Therapy/robot/village screens have unclear fit** in the new topic model —
  if they're kept as-is without re-pointing to topic data, they'll be visually
  inconsistent with the rest of the app; needs an explicit decision (port vs.
  cut) before step 10, not deferred indefinitely.
- **World generation determinism** — if lesson paths are randomly generated
  per child without a stored seed/snapshot, regenerating on every launch could
  silently change a child's path and break resume (lesson IDs referenced in
  progress might not exist in a freshly regenerated world). The generated
  world must be persisted once and reused, not recomputed.
- **Supabase dependency is unused dead weight** — leaving `supabase_flutter`
  in `pubspec.yaml` while adding Firebase risks confusion/conflicts (e.g.
  duplicate initialization patterns); remove it early, not as cleanup at the end.
- **Large file splits (`home_screen.dart`, `therapy_and_companion.dart`)**
  risk losing working code if extraction isn't done carefully — extract into
  new files and verify each screen still renders before deleting the original
  monolith file.
- **No existing tests** mean regressions in auth/navigation/progress logic
  won't be caught automatically until step 14; manual verification is
  required after each major step (3, 7, 8, 13 especially).

---

## 8. Open Decisions to Confirm Before Implementation

- Single-child-per-parent vs. multi-child support (affects whether
  `ChildSelectScreen` is deleted outright or rebuilt as a lightweight switcher).
- Whether `SpeechTherapyScreen`/`RobotModeScreen`/`VillageScreen` are kept,
  adapted, or cut from the new vision (version2.md doesn't mention them).
- Whether to wipe existing local `SharedPreferences` data on upgrade or write
  a migration path into Firestore.
