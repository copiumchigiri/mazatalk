# PROJECT_V3.md — Full Working App Update

> **Implementation status (2026-07-18): all 8 phases COMPLETE.**
> Real local auth with session restore and per-account children · full
> 48-lesson curriculum (6 units) · Duolingo-style path home with chests ·
> tap-to-answer lesson player with mistake requeue + TTS · all 8 activity
> types · daily streaks · practice mode · parent gate, real-data dashboard,
> settings. 47 automated tests green, `flutter analyze` clean.
> Pre-v3 backup: `../Backup July17/`.

## Purpose

Take the current v2 codebase (clean architecture, Riverpod, local persistence,
fake auth) and turn it into a **fully working app** with:

1. **Real, persistent sign up / sign in** (local backend for now, Firebase-ready).
2. **Duolingo / DuoABC UX** — the learning-path home screen, one-question-at-a-time
   lessons, instant feedback, streaks, XP, chests — while staying
   **deliberately designless**: default Material widgets, black/white, emoji as
   the only art, green/red only for feedback. No custom fonts, no images, no
   illustrations. The structure of the UX is Duolingo; the skin is plain.
3. **A full teaching curriculum** — a real, sequenced course for ages 4–7
   (letters, numbers, colors, shapes, words, early reading, early math,
   emotions), not the current one-lesson-per-interest placeholder.
4. Everything else a "full app" needs: settings, log out, practice mode,
   parent dashboard with real data, daily streaks, sound/TTS for pre-readers.

A backup of the pre-v3 state exists at `../Backup July17/`.

---

## 1. What Changes From V2 (and what stays)

### Stays
- Clean architecture layout (`features/<name>/domain|data|application|presentation`).
- Riverpod (`Notifier` controllers, repository providers).
- go_router with redirect gates.
- `ChildProfile`, coins, skins, `SkinCatalog`, skin shop screen.
- Onboarding flow (child name/age + visual interest picker).
- Local persistence via `shared_preferences` (Firebase stays a later phase —
  all repositories stay behind interfaces so swapping in Firebase later is a
  data-layer change only).

### Changes
- **`InMemoryAuthRepository` → `LocalAuthRepository`**: accounts actually
  persist. Sign up, restart the app, log back in — it works.
- **"No home screen, auto-resume into lesson" rule is superseded.** Duolingo's
  UX *is* a home screen: the vertical lesson path. V3 lands on the **Path
  screen**, auto-scrolled to the current lesson with a START bubble on it.
  Resume is still one tap and zero searching, which preserves the intent of
  the v2 rule.
- **One-lesson-per-interest world → real curriculum**: 6 units × 8 lessons,
  sequenced skills, themed by the child's interests.
- **Lesson player rewritten around DuoABC mechanics**: progress bar + exit X,
  one activity per screen, tap-to-answer with instant visual + spoken
  feedback, in-lesson mistake requeue, end-of-lesson celebration with
  XP/coins/accuracy.
- **Children are scoped per account.** Right now child profiles are stored
  globally — two different logins see the same children. V3 namespaces the
  child storage key by account id.

---

## 2. Authentication — Real and Working (Local Backend)

### Repository: `LocalAuthRepository` (replaces `InMemoryAuthRepository`)

Storage (all in `shared_preferences`):

```
auth.accounts   → JSON map: { "<email>": { "passwordHash": "...", "name": "..." } }
auth.session    → the email of the currently signed-in account, or absent
```

Behavior:
- **Sign up**: validate email format + password (min 6 chars). Reject duplicate
  emails with a clear error ("An account with this email already exists").
  Store `sha256(password + email)` as the hash (add `crypto` package — never
  store the raw password, even locally). Auto sign in after signup.
- **Sign in**: look up email, compare hash. Wrong password and unknown email
  produce the same error message ("Email or password is incorrect").
- **Session persistence**: on app start, if `auth.session` exists, the user is
  signed in — no login screen. This is what makes it feel like a real app.
- **Password reset (local version)**: enter email → if the account exists,
  go to a "set new password" screen → overwrite the hash. (With Firebase this
  becomes a reset email; the screen flow is already right.)
- **Log out**: clear `auth.session` only. Accounts and child data remain.
- Keep `admin@gmail.com` / `Password` pre-seeded as a demo account.

### `AuthController` changes
- `build()` reads the persisted session before emitting state (emit a
  `isRestoring` flag so the router can show a splash instead of flashing the
  welcome screen).
- Expose `errorMessage` in state so auth screens show real failures inline
  instead of generic snackbars.

### Auth UI (keep current screens, minimal fixes)
- Keep email + phone entry points; phone auth stays fake-verify for now
  (any 4-digit code) but goes through the same `LocalAuthRepository.signUp`
  using the phone number as the account key.
- Field validation messages under fields (Material default), nothing fancy.

### Acceptance criteria
- Sign up → kill app → reopen → still signed in, lands on Path screen.
- Log out → reopen → welcome screen → log in with same credentials → same
  children, same progress.
- Two different accounts on the same device see different children.

---

## 3. The Duolingo/DuoABC UX Spec (Designless Version)

### 3.1 Path Screen (new home, route `/home`)

The core Duolingo pattern: a **vertical scrolling path of lesson nodes**.

Layout (all default Material, black/white + emoji):

```
┌─────────────────────────────┐
│ ☰   🔥 4    ⚡ 320    🪙 45  🐻│   ← top stat bar (streak, XP, coins, PFP)
├─────────────────────────────┤
│  ── UNIT 1 · First Sounds ──│   ← unit header (divider + bold text)
│                             │
│        ✅  (done, filled)   │
│      ✅                     │
│        ✅                   │
│      🎁  (chest, opened)    │
│        ✅                   │
│      ▶️  ← START bubble     │   ← current lesson, auto-scrolled here
│        🔒                   │
│      🔒                     │
│                             │
│  ── UNIT 2 · Animal Friends─│
│        🔒 🔒 🔒 ...          │
└─────────────────────────────┘
```

Rules:
- Nodes alternate left/right offset (simple `Row` with spacers — the "winding"
  is just alternating alignment, no custom painting).
- Node states: **done** (filled black circle + ✓), **current** (outlined,
  pulsing not required — just bigger, with a "START" label above it),
  **locked** (grey 🔒, tap does nothing but a small "Complete the previous
  lesson!" snackbar).
- A **chest node** 🎁 every 4th lesson: not a lesson — tapping it when reached
  grants bonus coins (e.g. +15) once, then shows as opened.
- On open, the list **auto-scrolls to the current node** (`ScrollController` +
  `jumpTo` after first frame).
- Unit headers show unit number, title, and the unit's theme emoji.
- Tapping the current node → `/lesson?lessonId=<id>`. Tapping a done node →
  replay it (practice; XP but no repeat coin payout — existing
  `completeLesson` already guards double-pay).
- Top-left ☰ opens a standard `Drawer`: Practice Mistakes, Parent Dashboard,
  Settings, and at the bottom in red: Change Child, Log Out
  (per `main_page_plan.md`).
- Top-right child PFP (equipped skin emoji in a circle) → `/skins`.

### 3.2 Lesson Player v2 (Duolingo lesson mechanics)

Screen chrome:
- **Top bar**: `X` on the left (exit → confirm dialog "Stop the lesson? Your
  progress in this lesson is saved." — v3 keeps the checkpoint, so exiting is
  not punished), then a `LinearProgressIndicator` filling the rest of the bar.
  No coins/dashboard buttons in-lesson (they move to the Path screen).
- **One activity per screen.** Big prompt text (fontSize 22–26, bold), big
  full-width choice buttons (min height 56 — small fingers).

Answer flow (DuoABC variant — **the tap IS the answer, no confirm step**):
1. Child taps a choice → that tap is the answer. **No CHECK button.** Adult
   Duolingo's tap → CHECK → CONTINUE exists so adults can change their minds;
   a 4-year-old taps a tile, expects something to happen immediately, and
   gets stuck waiting on a confirm step. One tap per question, always.
2. **Correct** → the tapped tile turns green, TTS says "Nice job!", correct
   sound plays (if sound on), and the lesson **auto-advances after ~1
   second**. No CONTINUE tap needed.
3. **Wrong** → the tapped tile shakes and turns red, then the **correct tile
   lights up green** while TTS says "Not quite — it's this one!" Feedback
   must be **visual + spoken, never text-only** — the audience can't read,
   so text like "Answer: Blue" carries nothing. A small "❌ Not quite" banner
   may accompany it for parents, but the tile highlight and the voice are
   the actual feedback channel. Advance on a tap anywhere (or auto after
   ~2.5 s). **No hearts, no lives, no punishment** (DuoABC has none — right
   call for ages 4–7). The missed activity is **requeued at the end of the
   lesson** and recorded in the child's mistake bank for Practice mode.
4. Multi-step types (`matchPairs`, `fillBlank`, `sequence`) evaluate **per
   tap**: a correct tap locks in green, a wrong tap shakes red and the child
   simply tries again. The activity counts as "missed" (requeue + accuracy)
   if any tap in it was wrong.
5. Lesson ends when every activity (including requeued ones) is answered
   correctly once.

In-lesson extras:
- Per-activity **checkpoint saving** stays (already implemented) so resume
  returns mid-lesson.
- A small correct-answer combo counter ("3 in a row! 🔥") as plain text under
  the progress bar — text only, no animation work.
- 🔊 **speaker button** next to any prompt with spoken content — replays TTS
  (see §6). For pre-readers every prompt is auto-spoken on activity start.

### 3.3 Lesson Complete Screen

Plain, centered, emoji-only celebration:

```
        🎉
   Lesson complete!
   ⚡ +15 XP    🪙 +20
   Accuracy: 8/9
   🔥 Streak: day 4
      [ CONTINUE ]
```

- XP = 10 base + 1 per first-try-correct answer.
- Coins per existing `coinReward` (first completion only).
- If this completion crosses a chest node or finishes a unit, show that on the
  next screen ("🎁 Chest unlocked! +15 🪙" / "🏆 Unit 2 complete!").
- CONTINUE → back to Path screen, scrolled to the newly-unlocked node.

### 3.4 Daily Streak

- `ChildProfile` gains `dailyStreak` (int) and `lastActiveDate` (yyyy-mm-dd).
- On any lesson completion: if `lastActiveDate` == yesterday → streak+1; if
  today → unchanged; else → reset to 1. Update `lastActiveDate` to today.
- Shown as 🔥 N in the Path top bar and on the complete screen.
- No streak-freeze/notifications in v3 (listed in Later, §10).

---

## 4. The Curriculum — Full Course, Ages 4–7

### 4.1 Structure

```
Course
 └── Unit (6 units)          — a themed chapter with a learning goal
      └── Lesson (8 each)    — 6–10 activities, one sitting (3–5 min)
           └── Activity      — one question/interaction
```

48 lessons total. Lessons unlock strictly in order (Duolingo path). Every 4th
node is a chest. Units end with a **Review lesson** (mixed skills from the
unit) that acts as the unit checkpoint.

### 4.2 Theming by interest (keeps v2 personalization)

The curriculum is **fixed in skills and order** for every child, but **themed
by interests**: templates take a `topic` parameter exactly like v2's
`buildLessonForTopic`. The generator cycles through the child's selected
interests across lessons (lesson 1 dinosaurs, lesson 2 space, ...), so a
dinosaur kid counts 🦖 and a space kid counts 🚀 — same skill, same position
in the course. This keeps the deterministic-world guarantee from v2 (seeded
`Random(childId.hashCode ^ lessonIndex)`, generated once and stable).

### 4.3 The six units

**Unit 1 — First Sounds & Small Numbers** (theme: meeting your companion)
| # | Lesson | Skills |
|---|---|---|
| 1 | Say hello! | Tap the matching picture; companion intro; colors red/blue |
| 2 | Letters A & B | Letter recognition (uppercase), letter sound (TTS "tap the A") |
| 3 | Count 1–3 | Count objects, tap the number |
| 4 | Letters C & D | Recognition + first-letter matching (🐱 → C) |
| 5 | Colors 1 | Red, blue, green, yellow — tap the color, color of things |
| 6 | Letter E & review A–E | Mixed letter drill |
| 7 | Count 1–5 | Counting, "which group has 3?", number order 1-2-3 |
| 8 | **Review: Unit 1** | Mixed A–E, 1–5, colors |

**Unit 2 — Animal Friends** (vocabulary + more letters)
| # | Lesson | Skills |
|---|---|---|
| 9 | Letters F & G | Recognition, sounds |
| 10 | Animal words 1 | dog, cat, bird — picture↔word matching |
| 11 | Letters H, I, J | Recognition, "which letter starts 🐴 horse?" |
| 12 | Shapes 1 | Circle, square, triangle — tap the shape, shapes of things |
| 13 | Animal words 2 | fish, bear, duck; animal sounds ("which animal says moo?") |
| 14 | Numbers 6 & 7 | Counting to 7, number recognition |
| 15 | Big & small | Comparisons: bigger/smaller, tap the big one |
| 16 | **Review: Unit 2** | Mixed F–J, animals, shapes, 1–7 |

**Unit 3 — First Words** (early reading begins)
| # | Lesson | Skills |
|---|---|---|
| 17 | Letters K & L | Recognition, sounds |
| 18 | Read: cat, dog | First CVC words — match word to picture, tap word you hear |
| 19 | Letters M, N, O | Recognition; lowercase introduced (match A↔a) |
| 20 | Numbers 8, 9, 10 | Count to 10, "what comes after 8?" |
| 21 | Read: sun, hat, red | CVC words, fill the missing letter (c_t) |
| 22 | Shapes 2 | Star, heart, diamond; shape patterns (⚪⬜⚪⬜ what's next?) |
| 23 | Patterns | Sequence completion with colors/emoji |
| 24 | **Review: Unit 3** | Mixed K–O, CVC words, 1–10, patterns |

**Unit 4 — Numbers at Work** (early math)
| # | Lesson | Skills |
|---|---|---|
| 25 | Letters P & Q | Recognition, sounds |
| 26 | Add to 5 | 2 + 1 = ? with object pictures (🍎🍎 + 🍎 = ?) |
| 27 | Letters R, S, T | Recognition, first-letter matching |
| 28 | Numbers 11–15 | Recognition, counting, order |
| 29 | Add to 10 | Picture addition, number addition |
| 30 | Sight words 1 | the, and, is — tap the word you hear, word in context |
| 31 | Which is more? | Compare quantities, more/fewer |
| 32 | **Review: Unit 4** | Mixed P–T, addition, 11–15, sight words |

**Unit 5 — Reading & Taking Away** 
| # | Lesson | Skills |
|---|---|---|
| 33 | Letters U, V, W | Recognition, sounds |
| 34 | Take away | Simple subtraction to 5 with pictures |
| 35 | Letters X, Y, Z & full alphabet | A–Z mixed drill, alphabet order (what comes after G?) |
| 36 | Numbers 16–20 | Recognition, counting, order |
| 37 | Read a sentence | "The cat is red." — match sentence to picture |
| 38 | Sight words 2 | I, see, a, my — build "I see a cat" from word tiles (sequence) |
| 39 | Subtract to 10 | Picture and number subtraction |
| 40 | **Review: Unit 5** | Full alphabet, 1–20, +/- , sentences |

**Unit 6 — Stories & Feelings** (comprehension, EQ — pulls in the
userflow.md emotion goals)
| # | Lesson | Skills |
|---|---|---|
| 41 | How do they feel? | Emotions: 😊😢😠😨 — name the feeling, match to situation |
| 42 | Story time 1 | 3-line story (TTS) → answer a question about it |
| 43 | Days & time words | Morning/night, today/tomorrow, days as vocabulary |
| 44 | What happens next? | Story sequencing (put 3 pictures in order) |
| 45 | Being a friend | Social scenarios: "Your friend is sad. What do you do?" |
| 46 | Story time 2 | Longer story, 2 questions, retell by sequencing |
| 47 | All-star math | Mixed +/- to 10, counting to 20 |
| 48 | **Final review** | Mixed everything — course complete 🏆 → world-complete screen |

### 4.4 Content authoring model

All content is **data, not screens**. One file per unit under
`lib/features/curriculum/data/units/unit_1.dart` … `unit_6.dart`, each
exporting a `UnitTemplate`:

```dart
UnitTemplate(
  id: 'unit1', title: 'First Sounds & Small Numbers', emoji: '🔤',
  lessons: [
    LessonTemplate(
      id: 'u1l2', title: 'Letters A & B',
      activityBuilders: [
        (topic, rng) => Activity.letterTap(letter: 'A', ...),
        ...
      ],
    ),
  ],
)
```

Builders receive the `topic` (interest) + seeded `rng` so themed and shuffled
variants stay deterministic per child. The existing
`buildLessonForTopic`-style helpers become a shared library of **activity
factories** (`counting(...)`, `letterRecognition(...)`, `wordPictureMatch(...)`)
reused across units — same philosophy as v2's templates, applied to a real
course.

---

## 5. Activity Types (the interaction catalog)

The `Activity` model generalizes from "prompt + text choices + correctIndex"
to a typed union. All are still tap-only (no typing — target users can't
type), all render with plain Material widgets.

| Type | Interaction | Used for |
|---|---|---|
| `choiceText` | Tap 1 of 3–4 text buttons (exists today) | numbers, words, letters |
| `choicePicture` | Tap 1 of 4 big emoji tiles in a 2×2 grid | vocabulary, colors, shapes, emotions |
| `listenAndChoose` | 🔊 auto-plays TTS ("tap the word **cat**"), tap answer | phonics, sight words, pre-reader prompts |
| `countAndChoose` | Objects shown (emoji row), tap the right number | counting |
| `matchPairs` | 2 columns (**3 pairs max**), tap one from each side to match; matched pairs grey out | word↔picture, upper↔lowercase, number↔quantity |
| `fillBlank` | Word with a gap (`c _ t`) + letter choices | spelling, CVC words |
| `sequence` | Tap word/picture tiles in order to build a sentence or story order; tapped tiles move to an answer row (**3 tiles max; 4 allowed in units 5–6 only**) | sentence building, story sequencing, number order |
| `trueFalse` | Big ✅ / ❌ buttons under a statement/picture | comprehension, comparisons |

**Age caps (working-memory limits for the young end of 4–7):**
- `matchPairs` never exceeds 3 pairs; `sequence` never exceeds 3 tiles
  (4 permitted only in units 5–6, where sentence building appears).
- Neither `matchPairs` nor `sequence` appears in **Unit 1** — the first unit
  uses only single-tap types (`choiceText`, `choicePicture`, `countAndChoose`,
  `listenAndChoose`) so a 4-year-old ramps up before any multi-step task.
- The content validator test (§11) enforces all of these caps mechanically.

Model sketch:

```dart
enum ActivityType { choiceText, choicePicture, listenAndChoose,
                    countAndChoose, matchPairs, fillBlank, sequence, trueFalse }

class Activity {
  final ActivityType type;
  final String skillId;        // 'letters', 'counting', 'reading', 'math', 'eq'...
  final String prompt;         // displayed text
  final String? spokenPrompt;  // what TTS says (null = speak `prompt`)
  final List<String> choices;  // tiles/buttons/left column
  final List<String> rightColumn; // matchPairs only
  final List<int> correctOrder;   // sequence: indices in order; others: [correctIndex]
}
```

The lesson player switches on `type` to pick a widget
(`lib/features/lesson/presentation/activities/<type>_activity.dart`), each
implementing a tiny shared contract: `onAnswered(bool correct)`. The
tap-to-answer feedback logic (green/red tile highlight, TTS callouts,
auto-advance timing) lives once in the player, not per widget.

---

## 6. Audio & TTS (critical for pre-readers)

- Add **`flutter_tts`** (offline-capable, no API keys, works on Android).
- `TtsService` in `core/services/tts_service.dart`: `speak(String)`, `stop()`,
  slow child-friendly rate (~0.45), exposed via a Riverpod provider.
- Every activity auto-speaks `spokenPrompt ?? prompt` on appear; 🔊 button
  replays it. `listenAndChoose` *only* works via TTS.
- Feedback sounds: use `SystemSound`/short TTS ("Nice job!") — **no audio
  asset files** in v3, keeping the designless/no-assets rule.
- Settings toggle: "Sound & voice" on/off (persisted per account).

---

## 7. Everything Else a Full App Needs

### 7.1 Practice Mode (Duolingo's "practice mistakes")
- `ChildProfile` gains `mistakeBank: List<String>` (activity fingerprints:
  `lessonId:activityIndex`).
- Wrong answers add to the bank; answering the same item right during
  practice removes it.
- Drawer → "Practice 🔁" builds an ad-hoc lesson from up to 8 banked
  mistakes (or, if empty, random activities from completed lessons). Awards
  XP (5 + 1/correct) but no coins. Route: `/practice`.

### 7.2 Settings screen (route `/settings`)
- Sound & voice toggle.
- Parent name / account email (read-only display).
- "Change child" (→ `/select-child`), "Log out" (red), and
  "Delete all data on this device" (red, double-confirm) — resets that
  account's children + progress.

### 7.3 Parent Dashboard — real data
Replace placeholder numbers with values computed from the selected child:
- Lessons completed / 48, current unit, accuracy % (correct-first-try over
  answered, tracked as two counters on `ChildProfile`), daily streak,
  XP total, mistake-bank size ("8 items to practice"), per-skill breakdown
  (counts of completed activities by `skillId` — letters / numbers / reading /
  math / feelings).
- Gate it behind a simple **parent gate** (DuoABC-style): "Tap 7 then 3 to
  enter" with a 3×3 number pad — keeps kids out without a password.

### 7.4 Child select / multi-child
- Keep `ChildSelectScreen` (multi-child stays supported). Add child avatars
  (equipped-skin emoji), and per-child streak/XP shown on the card.
- Children stored under key `children.<accountId>` (the per-account fix).

### 7.5 Course complete
- Finishing lesson 48 → existing `WorldCompleteScreen`, upgraded: total XP,
  total coins, 🏆, and "Practice anything by tapping finished lessons."

---

## 8. Data Model & Storage Changes

`ChildProfile` additions (all with safe JSON defaults so existing local saves
load without migration):

```dart
int xp;                       // default 0
int dailyStreak;              // default 0
String? lastActiveDate;       // 'yyyy-MM-dd'
List<String> mistakeBank;     // default []
List<String> openedChestIds;  // default []
int answersTotal;             // for accuracy
int answersCorrectFirstTry;
```

Storage keys (all `shared_preferences`):

```
auth.accounts                     — account map (see §2)
auth.session                      — signed-in account id
children.<accountId>              — that account's children JSON list
settings.<accountId>              — { soundOn: true }
```

The world/course no longer needs persistence of generated lessons per child:
the course structure is static (units file) and theming is seeded/deterministic,
so `worldFor(childId, interests)` is a pure function — the v2 "persist the
generated world" risk disappears. `LocalWorldRepository` is deleted;
`WorldController` becomes `CourseController`.

---

## 9. Architecture: New/Changed Files

```
lib/
├── app/
│   ├── router.dart                  # updated: /home, /practice, /settings, splash gate
│   └── theme.dart                   # NEW: pull ThemeData out of main.dart
├── core/
│   ├── services/tts_service.dart    # NEW
│   └── widgets/                     # NEW: BigChoiceButton, FeedbackBanner, StatChip
├── features/
│   ├── auth/
│   │   ├── data/local_auth_repository.dart      # NEW (replaces in_memory)
│   │   └── application/auth_controller.dart     # session restore, errors
│   ├── curriculum/                              # NEW (replaces features/world)
│   │   ├── domain/  unit.dart, lesson.dart, activity.dart, course.dart
│   │   ├── data/    activity_factories.dart, units/unit_1.dart … unit_6.dart
│   │   └── application/course_controller.dart   # course build, unlock logic, chests
│   ├── lesson/
│   │   ├── application/lesson_session_controller.dart  # NEW: answer flow, requeue, XP
│   │   └── presentation/
│   │       ├── lesson_player_screen.dart        # rewritten (chrome + tap-to-answer feedback)
│   │       ├── lesson_complete_screen.dart      # NEW (split out)
│   │       └── activities/                      # NEW: one widget per ActivityType
│   ├── path/                                    # NEW
│   │   └── presentation/path_screen.dart        # the Duolingo home path + drawer
│   ├── practice/                                # NEW
│   │   └── application+presentation             # mistake-bank lesson builder
│   ├── profile/                                 # ChildProfile fields, per-account keys
│   ├── companion/                               # unchanged
│   ├── settings/                                # NEW: settings screen + controller
│   └── parent/presentation/parent_dashboard.dart # real data + parent gate
```

Router redirect (updated three-gate + home):

```
restoring session          → /splash (plain CircularProgressIndicator)
not logged in              → auth flow ('/', /login, /signup, ...)
logged in, no child        → /select-child → /child/new → /child/interests
logged in, child selected  → /home (path screen)
/lesson, /practice, /skins, /settings, /parent-dashboard reachable from /home
```

New dependencies: `flutter_tts`, `crypto`, `intl` (date math for streaks).
No image/animation/font packages — designless rule.

---

## 10. Implementation Order (phases, each independently verifiable)

1. **Auth for real** — `LocalAuthRepository`, session restore, per-account
   child keys, error messages, splash gate.
   ✅ *Verify: signup → relaunch → still in; two accounts isolated.*
2. **Curriculum engine** — new domain models, activity factories, units 1–2
   authored, `CourseController` with unlock/chest logic. Old `world/`
   deleted, tests ported.
   ✅ *Verify: unit tests — 16 lessons generate, deterministic per child,
   unlock order enforced.*
3. **Path screen** — node list, states, chests, drawer, stat bar, auto-scroll;
   router lands here.
   ✅ *Verify: complete a lesson → node turns done, next unlocks, chest opens
   at node 4.*
4. **Lesson player v2** — tap-to-answer loop (tile highlight + TTS feedback,
   auto-advance), mistake requeue,
   activity widgets for `choiceText`, `choicePicture`, `countAndChoose`,
   `trueFalse` (enough for units 1–2), complete screen with XP/accuracy/streak.
   ✅ *Verify: play units 1–2 end to end; wrong answers requeue; checkpoint
   resume mid-lesson.*
5. **Remaining activity widgets** — `matchPairs`, `fillBlank`, `sequence`,
   `listenAndChoose` + **TTS service**; author units 3–6.
   ✅ *Verify: play through to lesson 48 → course complete screen.*
6. **Gamification & practice** — daily streak logic, mistake bank,
   `/practice`, chest bonuses, accuracy counters.
7. **Settings + parent dashboard** — real stats, parent gate, sound toggle,
   delete-data.
8. **Tests & polish** — see §11; `flutter analyze` clean; full manual QA pass.

---

## 11. Testing

Unit tests:
- `LocalAuthRepository`: signup/login/duplicate/wrong-password/session/logout.
- Course generation: 48 lessons, stable across rebuilds for same child,
  themed by interests, every activity's answer data self-consistent
  (correct index in range, matchPairs columns equal length, etc. — a single
  validator test that walks *all* generated content catches authoring typos).
- Unlock logic: lesson N locked until N-1 complete; chests one-time.
- Streak math: yesterday→+1, today→same, gap→1.
- `LessonSessionController`: requeue on wrong, complete only when all correct,
  XP math, mistake-bank add/remove.
- Port existing `child_controller_test` (coins, double-pay guard, checkpoint).

Widget tests:
- Path screen renders states from a fake course; tap locked shows snackbar.
- Lesson player: pick wrong → wrong tile marked red, correct tile marked
  green → item reappears at end of lesson.

Manual QA script (run on Android emulator each release):
fresh install → signup → onboarding → land on path → play 3 lessons (one with
deliberate mistakes) → kill app mid-lesson → reopen resumes checkpoint →
open chest → buy a skin → parent gate + dashboard numbers sane → log out/in.

---

## 12. Decisions Made (defaults chosen — change if you disagree)

- **No hearts/lives** — DuoABC-style gentle retry + requeue instead. Right for
  ages 4–7; hearts cause quitting, not learning.
- **No CHECK button** — the tap is the answer; correct answers auto-advance.
  The confirm step exists in adult Duolingo for adults; it only confuses
  pre-readers.
- **Feedback is visual + spoken, never text-only** — wrong tile red, correct
  tile green, TTS voice; text banners are parent-facing garnish. Working-
  memory caps: 3 pairs / 3 sequence tiles max, no multi-step types in Unit 1.
- **Land on the Path screen, not auto-inside a lesson** — supersedes v2's
  "no home screen"; one tap on the pre-highlighted START node is the resume.
- **English content** for v3. `userflow.md`'s Mongolian focus is real, but
  TTS + curriculum in Mongolian is a separate content pass; the data-driven
  authoring model (§4.4) makes localization a units-files swap later.
- **Local auth now, Firebase later** — repository interface unchanged, so
  Phase-Firebase is a drop-in `FirebaseAuthRepository` + `FirestoreChildRepository`.
- **No microphone/speech-recognition activities** in v3 (Robot Mode, speech
  therapy from userflow.md) — deferred; needs mic permissions + a speech API.

## Later (explicitly out of v3 scope)
Firebase auth/Firestore sync · Mongolian localization · speech
recognition/Robot Mode · streak freeze & push notification reminders · real
art/animation/sound assets · leaderboards · iOS polish.
