# PROJECT_V4.md — The Playground Placement Test

> **Status (2026-08-11): SPEC — not yet implemented.** This document plans
> the next slice of work on top of the completed V3 app (see `PROJECT_V3.md`;
> all 8 of its phases are done — real auth, 48-lesson curriculum, Duolingo
> path, tap-to-answer player, TTS). V4 does not touch the curriculum, the
> lesson player, or gamification — it replaces what happens **between
> sign-up and the first lesson**.

## Purpose

Today, right after a parent signs up, *the parent* fills out two more forms —
a name/age text field screen, then a grid of interest tiles to tap — and
that's it; the child never touches the phone until the course itself starts.
It works, but it's a paperwork step wearing a kids'-app skin, and it throws
away information: we could be *watching the child play* for those two
minutes instead of *reading a form the parent filled in about them*.

V4 replaces the interest-picker step with a **placement playground**: after
the parent enters the child's name and age, they hand the phone over, and
the child plays through **10 short game levels** hosted by our mascot,
Мазаалай (the bear, referred to in-app as "Maza"). Maza talks — speech
bubble plus spoken TTS, no reading required — and each level is a tap-only
mini-game: find the hidden ball, repeat a word, tap the color Maza names,
count the dinosaurs, and so on. There is no pass/fail. The child just plays;
we score what we observe, and that score becomes the **starting point** in
the existing V3 curriculum instead of everyone beginning at Lesson 1
regardless of what they already know.

Two things stay non-negotiable from V3 and get *more* important here, not
less: **no reading required** (every instruction is spoken) and **nothing
the child does is ever marked wrong on screen** — this product's own end
goal (`userflow.md`) starts at "not speaking yet," so a placement flow that
punishes silence or hesitation would fail the exact kids it's for.

---

## 1. What Changes From V3 (and what stays)

### Stays
- Everything in `PROJECT_V3.md` — auth, the 48-lesson curriculum and its 6
  units, the Path screen, the lesson player and its answer mechanics, TTS
  service, gamification, parent dashboard. V4 is additive.
- The parent still creates the account and still enters the child's **name
  and age** directly (that's a parent fact, not something to gamify — a
  4-year-old can't type their own birthday).
- The "designless" rule mostly holds: default Material widgets, no imported
  art/animation packages, emoji as the only art, black/white base palette.
  §4 below carves out one narrow exception for the playground's freeform
  layout — explained there.
- `Interest` enum, `interestIds` on `ChildProfile`, and the interest-driven
  lesson theming from V3 §4.2 — unchanged. V4 just changes *how* interests
  get captured (playground level, not a form screen).

### Changes
- **`InterestSelectScreen` (the plain interest-grid form) is retired** as an
  onboarding step. Its data (tap 3 interests) is captured instead by
  Playground Level 7, restyled to match the other levels. The screen's code
  can be deleted once the playground ships; nothing else depends on it.
- **New onboarding step: the Playground Placement Test**, between "parent
  enters child name/age" and "land on the Path screen."
- **`ChildProfile` gains a placement result** (score + starting lesson +
  a few supplementary signals — §8) instead of starting every child at
  Unit 1, Lesson 1.
- **Two dead fields formally retired**: `disabilities` and `preferNotToSay`
  on `ChildProfile` were never wired to any screen (grep confirms zero
  references outside the model file) — they're leftover intent from an
  earlier "speech level / diagnosis" question set that this doc explicitly
  does **not** bring back (see §9 and Decisions, §14). Left in place for
  this version to avoid a save-migration; safe to delete once no analytics
  depend on them.

---

## 2. The New Onboarding Flow, End to End

```
Welcome → Sign Up → Child name + age (parent, phone in parent's hands)
   ↓
Handoff screen: "Give the phone to <name>!"  (parent taps, then phone
   orientation/attention shifts to the child)
   ↓
🎪 Playground — 10 levels, Maza hosting, ~3–5 minutes, no forms, no reading
   ↓
Placement computed (silent, <1s) → ChildProfile.placement set
   ↓
Path screen, auto-scrolled to the *placed* starting lesson in Unit 1
```

This supersedes V3 §9's router note `logged in, no child → /select-child →
/child/new → /child/interests`. New version:

```
logged in, no child   → /select-child → /child/new → /child/handoff
                          → /playground → /home (path, placed lesson)
```

`/child/interests` is removed from the redirect chain (its data now comes
from `/playground`, level 7).

---

## 3. The Handoff Screen (`/child/handoff`)

A single deliberate beat between "parent is holding the phone" and "child is
holding the phone" — skipping this, kids get a level 1 that starts before
they're looking at the screen.

```
┌─────────────────────────────┐
│                              │
│           🐻                │
│                              │
│     Time to play, Tuya!     │
│                              │
│  Give the phone to Tuya.    │
│  Maza has some fun games    │
│  for her to try. 🎈         │
│                              │
│   [ We're ready! ▶ ]        │
│                              │
│   Skip playing, start at    │
│      Lesson 1 (parent)      │
└─────────────────────────────┘
```

- Big single CTA, nothing to type. TTS speaks the message once on arrival
  (so a child who can't read yet but has already taken the phone still gets
  oriented).
- **Skip link** (small, parent-styled, bottom): sends straight to `/home`
  with the default placement (Unit 1, Lesson 1, no supplementary signals).
  This exists for parents in a hurry, kids who are overstimulated by a new
  screen, or a re-install where the parent just wants the normal course.
  Never nag or hide this option — see §9.
- After "We're ready!", a 2-second full-bleed **Maza wave animation** (a
  `Tween`-driven scale/rotate on the existing emoji mascot — no new asset)
  acts as the visual handoff cue before Level 1 loads.

---

## 4. The Companion Speech-Bubble System

The playground is hosted by Maza the whole way through, so this needs to be
a real reusable piece, not one-off text per screen.

### 4.1 Why the design budget expands slightly here

V3's "designless" rule (flat Material, `Column`/`ListView`, no freeform
canvas) is right for lesson content parents will scroll through hundreds of
times. The playground is different: it's a first impression aimed entirely
at a child who can't read the UI conventions adults infer for free (progress
bars, buttons that say "Next"). It gets:
- A `Stack`-based freeform **scene** instead of a list layout, so objects can
  be scattered/positioned (needed for Level 1's find-the-ball mechanic).
- Simple `AnimatedPositioned`/`AnimatedScale` tweens for feedback (bounce,
  wiggle, pulse-to-hint). Still **no image assets, no Lottie, no custom
  fonts** — motion is built from `Tween`s on existing emoji/Container
  widgets, same as the V3 mascot radar painter and lesson tile shake.

Everything else — colors, typography, no external asset packages — is
unchanged from V3.

### 4.2 `MazaSpeechBubble` widget (`core/widgets/maza_speech_bubble.dart`)

```dart
class MazaSpeechBubble extends ConsumerStatefulWidget {
  final String text;          // shown on screen (short, large font)
  final String? spokenText;   // what TTS says; null = speak `text`
  final bool autoSpeak;       // true on level entry
}
```

- Bear emoji avatar (reuse `MascotPlaceholder`'s 🐻, no new art) + a rounded
  speech-bubble `Container` with a small triangle tail, black border, white
  fill — matches existing button styling.
- Text is short (one line, ≤ 8 words) and large (24–28pt) — playground copy
  is written for *listening*, not reading.
- On appear: auto-speaks via the existing `ttsServiceProvider` (V3's
  `TtsService`, no new service needed). A 🔊 tap-to-replay sits on the
  bubble, same convention as the lesson player.
- Idle micro-animation: a slow 2px bob + occasional blink (palette swap on a
  simple circle "eye," no asset) so Maza reads as alive between prompts,
  without needing sprite art.

### 4.3 Language

Spoken lines stay **English**, consistent with V3 Decision (`PROJECT_V3.md`
§12: "English content for v3... Mongolian is a separate content pass").
On-screen bubble text follows the same bilingual convention the current
onboarding screens already use (Mongolian primary line, small English
gloss under it) so a parent glancing over the child's shoulder still tracks
what's happening, even though the TTS engine (`flutter_tts`, `en-US` only
today) speaks the English line. This is a display/audio language mismatch,
same as the rest of the app currently has — not a new problem V4 introduces.

---

## 5. Level Engine Architecture

A `PlaygroundLevel` contract lets each of the 10 levels be a self-contained
widget the shell hosts identically:

```dart
abstract class PlaygroundLevel {
  String get id;
  String get promptText;         // bubble text
  String? get spokenPrompt;      // null = speak promptText
  Widget build(BuildContext context, PlaygroundLevelCallbacks callbacks);
}

class PlaygroundLevelCallbacks {
  final void Function(int points, {bool timedOut}) onComplete; // 0–10
}
```

`PlaygroundSessionController` (Riverpod `Notifier`) owns:
- `currentIndex` (0–9), advances on `onComplete`.
- `Map<String, int> scores` keyed by level id.
- Level-specific side payloads (Level 7's picked `interestIds`, Level 9's
  `readyForMultiStep` bool) collected the same way, just typed per level.
- On the 10th `onComplete`, computes the `PlacementResult` (§7) and writes
  it to the child's profile, then routes to `/home`.

Shared shell (`PlaygroundScreen`):
```
┌─────────────────────────────┐
│  ● ● ● ○ ○ ○ ○ ○ ○ ○         │  ← 10 dots, filled = done (not a % bar —
│                              │     a bar implies reading a number; dots
│                              │     are countable at a glance)
│         🐻  "Find the       │
│              ball!"         │
│                              │
│     (level content here)    │
│                              │
└─────────────────────────────┘
```

Universal rules across all 10 levels (this is the important part):
1. **No CHECK button, no wrong-answer punishment** — same tap-is-the-answer
   philosophy as the V3 lesson player, taken further: unlike lessons,
   **there is no red state at all** in the playground. A miss just doesn't
   advance; it re-prompts or hints. Nothing shakes red, no "❌," no buzzer.
2. **Every level always completes.** There is no failure state that blocks
   progress — only a *score* that varies. This is the core reason the
   playground is safe for non-verbal or hesitant kids: doing nothing for
   12 seconds still moves you forward, just with a lower score for that
   level, exactly like a real answer attempt that missed.
3. **Universal timeout: 12 seconds of no input** → auto-advance at whatever
   partial score the level defines for "no response" (never 0 — see each
   level's rule below; a startled or shy child shouldn't read as "worst
   possible").
4. **Correct/attempted response** → Maza gives brief praise (bubble + TTS,
   ~1 second), then auto-advances — no continue tap, matching V3's
   auto-advance-on-correct rule.
5. Levels are **seeded per session** (`Random(childId.hashCode ^ 'placement')`)
   so layouts (e.g., where the ball hides) are stable for a given child
   across a resumed session but vary child to child — same determinism
   pattern V3 uses for lesson content.

---

## 6. The 10 Levels

Each level: what the child sees, what Maza says, the mechanic, and how it's
scored (0–10 unless noted). Levels are ordered easy → varied, front-loading
the two "big" mechanics the user flow is built around (find-the-object,
repeat-after-me) before anything else.

**1. Find the Ball** — *attention / instruction-following*
Playground scene: 8–12 scattered decoy emoji (🌳🧒🛝🐦🎈…) placed at random
`Positioned` offsets in a `Stack`, one obvious ⚽ among them. Maza: *"Look
around... find the ball!"* Tap the ball → bounce + chime. Tap a decoy →
gentle wiggle, no other feedback, try again. After 2 misses or 6s idle, the
ball gets a soft pulsing glow (hint). Scoring: found with 0–1 misses before
hint = 10; found only after hint = 6; timeout (never found) = 2 — the floor
is deliberately low enough that an entirely non-responsive session can still
land in §7.2's lowest placement bucket, rather than that bucket being
mathematically unreachable.

**2. Repeat After Me** — *verbal comfort baseline, never gating*
Maza: *"Say 'ball'!"* with a big 🎤 button. Tap-and-hold to record (via
`speech_to_text`, best-effort — see §9), release to stop. Whatever happens,
this level always completes within ~5s of releasing the mic (or the 12s
timeout if never tapped). Scoring: recognizable word match = 10; any
vocalization detected but no match = 6; mic tapped but silence/no speech
detected = 4; never tapped at all = 3. **Nothing here is displayed as
"wrong"** — Maza says "Nice try!" for every outcome, same tone, same
animation.

**3. Tap the Color** — *listening vocabulary*
2×2 grid of color-name text tiles (Red/Blue/Green/Yellow — V3's Unit 1
Lesson 5 palette), not literal colored swatches: the rest of the app renders
colors as text buttons, not colored UI (`lesson_player_screen.dart`), and
this level follows the same convention rather than introducing a one-off
exception. Maza names one. Tap it → correct. Scoring: correct first tap =
10; correct after one miss = 6; timeout = 2 (see Level 1's note on why the
floor is 2, not 3).

**4. Count the Friends** — *counting*
A row of 2–5 emoji objects (themed later by whatever the child picks in
Level 7, generic 🧸 for now since interests aren't known yet). Maza: *"How
many teddy bears?"* Tap the matching number tile from 1–5. Same scoring
pattern as Level 3.

**5. Find the Letter** — *letter recognition*
Grid of 5 big letters, a subset of A–E (V3 Unit 1's first letters). Maza
names one by sound ("Find the letter... **A**!"). Same scoring pattern.

**6. Match the Shape** — *shape recognition (probe, not gating)*
Maza names a shape (circle/square/triangle); tap the matching tile among 3.
This skill lives in V3 Unit 2, not Unit 1 — it's included as a **forward
probe**: strong performance here feeds `readyForMultiStep`-adjacent signal
rather than the core placement score (a child can be great at shapes and
still need Unit 1's letters — the two don't imply each other). Same scoring
pattern, but weighted separately — see §7.

**7. Pick Your Favorites!** — *interest capture (replaces `InterestSelectScreen`)*
The existing `Interest` enum (dinosaurs, cars, trains, space, ocean,
animals, music, art, fairy tales, sports), shown as a 3×3-ish tap grid
styled like a toybox, with a light bounce-on-tap. Maza: *"Tap 3 things you
love!"* Selecting exactly 3 auto-advances (no Finish button to hunt for).
**Always scores 10 regardless of picks** — there's no correct answer here;
this level exists purely to capture `interestIds` the same way
`InterestSelectScreen` used to, just in the playground's voice. If the
child taps fewer than 3 before the (extended, 20s) timeout, whatever was
picked is kept, and any remainder is backfilled randomly so theming still
has 3 interests to cycle through (never leaves a child with zero themed
content).

**8. How Do They Feel?** — *emotion recognition (probe, bonus signal)*
Maza narrates a one-line scenario ("Your friend shares their toy with
you!"), 4 face emoji (😊😢😠😨) to tap. Feeds `emotionAwareness`, a
supplementary signal only (§7) — this skill is Unit 6 content, far past
where placement will ever start a child, so it never affects the starting
lesson. It exists to give the parent dashboard an early EQ data point from
day one (ties to `userflow.md`'s EQ Village ambitions — not built in V4,
just the first data collected toward it).

**9. Memory Match** — *working memory probe*
3 pairs of animal emoji, 6 face-down tiles (`?`), tap two to reveal; match =
stays face up, mismatch = flips back after 1s (no red, just a flip). Child
gets up to 6 attempts within the 12s-per-tap timeout budget (extended to
20s total for this level, since it's inherently multi-step). Scoring feeds
`readyForMultiStep` (bool: ≥2 of 3 pairs matched within budget) — this is
the signal V3's Unit 1 content-caps section already anticipates ("neither
`matchPairs` nor `sequence` appears in Unit 1"); a strong `readyForMultiStep`
doesn't unlock anything in V4, it's recorded for a future personalization
pass (§15).

**10. Copy the Pattern** — *sequencing, closing flourish*
Maza taps 3 objects in order (⚽ lights up, then 🎈, then 🌟, each with a
sound), then: *"Now you try!"* — child taps the same 3 in the same order.
One retry allowed on a mismatch (tiles reset, Maza repeats the pattern once
more) before scoring. This is the biggest on-screen celebration of the 10
(confetti-style emoji burst built from a `Tween`, same "no asset packages"
rule) — it's the last level, so it doubles as the placement test's own
"lesson complete" moment. Uses the 20s extended timeout (not the 12s
default) since a mismatch triggers a full second demo before the child gets
another try. Scoring: correct first try = 10; correct after one repeat = 6;
still wrong or timeout = 2 (never 0 — attempting a 3-step sequence at all is
meaningful signal, not a failure; the floor matches Level 1's for the same
reason — see its note).

---

## 7. Scoring & Placement Algorithm

### 7.1 Two kinds of signal

Only levels that map directly onto **Unit 1's actual skills** decide where
the child starts. Everything else is recorded but doesn't move the start
point — mixing them would let a child who's great at shapes (Unit 2) but
has never seen a letter get placed past Unit 1's letters, which is exactly
the kind of gap the whole "review lessons every 4th node" design in V3
exists to prevent.

**Core placement score** = sum of Levels 1, 3, 4, 5, 10 (0–10 each, max 50),
normalized to /100 (`×2`). These five map onto Unit 1's own skills: finding
the ball (instruction-following, prerequisite to *any* tap-based lesson),
colors, counting, letters, and pattern-sequencing (Unit 1 Lesson 6/7
territory).

**Supplementary signals** (stored, not placement-driving):
| Signal | From | Type | Used for |
|---|---|---|---|
| `verbalComfort` | Level 2 | 0–10 | Parent dashboard baseline; future speech-focused content gating (V5+) |
| `shapeAwareness` | Level 6 | 0–10 | Future personalization only |
| `emotionAwareness` | Level 8 | 0–10 | Parent dashboard EQ data point |
| `readyForMultiStep` | Level 9 | bool | Future personalization only — **not used to alter V3's existing "no matchPairs/sequence in Unit 1" rule in V4** |
| `interestIds` | Level 7 | `List<String>` | Lesson theming — same role `interestIds` already plays in V3 §4.2 |

### 7.2 Placement mapping

Core score buckets into a **starting lesson within Unit 1 only** — V4 never
skips a child into Unit 2 or beyond, and never auto-skips Unit 1's two
review lessons (7, 8), since those exist specifically to catch gaps and
skipping them on a heuristic first impression defeats their purpose.

| Core score | Starting lesson | Rationale |
|---|---|---|
| 0–20 | Lesson 1 | No prior signal — start at the true beginning. |
| 21–40 | Lesson 2 | Basic instruction-following/attention present. |
| 41–55 | Lesson 3 | + solid color/counting response. |
| 56–70 | Lesson 4 | + letter recognition present. |
| 71–85 | Lesson 5 | Strong across the board. |
| 86–100 | Lesson 6 | Near-ceiling on every core probe. |

Lessons 1..(start−1) are marked **placed**: added to `completedLessonIds`
with **0 XP and 0 coins** (so V3's `completeLesson` payout-guard math stays
correct — a placed lesson has never actually been played) and flagged in a
new `placedLessonIds` list so the Path screen can render them with a
distinct ✓ badge instead of the normal filled-done circle (§10) — a parent
or curious kid tapping a placed node should be able to tell it was
inferred, not played, and can still replay it for real credit like any
other done node.

### 7.3 Parent recourse

Placement is a two-minute heuristic from a handful of tap games, not a real
diagnostic instrument — it will get some kids wrong in both directions.
Settings (`/settings`, V3 §7.2) gains two new actions:
- **"Redo the playground"** — re-run all 10 levels, overwrites the prior
  placement (does not touch already-earned XP/coins/streak from real lesson
  play).
- **"Start over from Lesson 1"** — clears `placedLessonIds` only, one tap,
  no re-test needed, for a parent who just wants the full course regardless
  of what placement said.

---

## 8. Data Model Changes

`ChildProfile` additions (safe JSON defaults, no migration needed — same
pattern V3 used for its own additions):

```dart
bool placementCompleted;         // default false
int? placementCoreScore;         // 0–100, null until playground finishes
List<String> placedLessonIds;    // auto-credited, 0 XP/coins, badge on Path
int? verbalComfort;              // 0–10, supplementary
int? shapeAwareness;             // 0–10, supplementary
int? emotionAwareness;           // 0–10, supplementary
bool? readyForMultiStep;         // supplementary
```

`interestIds` is unchanged — Level 7 writes to the same field
`InterestSelectScreen` used to.

New storage: none beyond the existing `children.<accountId>` blob — these
are just more fields on the same persisted `ChildProfile` JSON, consistent
with how V3 added its own gamification fields.

---

## 9. Accessibility & Non-Verbal Safety Rules

This section is the one that most directly serves the app's actual mission
(`userflow.md`'s end goal literally starts at "Not Speaking"), so it's
called out on its own rather than buried in level specs:

- **Speech is never required to proceed.** Level 2 always completes; a
  child who never taps the mic, or taps it and says nothing, still moves on
  with a non-zero, non-shaming score and identical praise from Maza.
- **No red, no "wrong," no buzzer anywhere in the playground** — a stricter
  rule than the lesson player's already-gentle "no hearts" policy (V3 §12).
  The playground is a first impression; V4 spends that impression building
  trust, not correcting.
- **Every level has a generous timeout** (12s default, 20s for the two
  multi-step levels) that always advances. A child who freezes, gets
  distracted, or needs a moment is never stuck on a screen.
- **The handoff screen's "Skip playing" link is real, not a dark pattern** —
  full-size tap target, no confirmation nag, no "are you sure you want to
  miss out" copy. A parent who needs to skip (overwhelmed child, low time,
  a re-install) gets the same default course V3 already ships.
- `speech_to_text` (Level 2) is **best-effort only**: if the package errors,
  the platform denies mic permission, or the device has no recognizer
  available, the level silently degrades to "vocalization detected" (via
  raw mic amplitude, not transcription) or, failing even that, to the
  timeout path — it never blocks, never shows a permission-denial dialog
  mid-playground. Any permission prompt happens once, before Level 2,
  phrased for the parent ("Maza would like to listen — you can skip this
  anytime"), not for the child.

---

## 10. Architecture: New/Changed Files

```
lib/
├── core/
│   ├── services/
│   │   └── speech_input_service.dart     # NEW: thin wrapper over
│   │                                      #   speech_to_text, best-effort,
│   │                                      #   never throws into caller
│   └── widgets/
│       └── maza_speech_bubble.dart       # NEW: §4.2
├── features/
│   ├── placement/                        # NEW feature
│   │   ├── domain/
│   │   │   └── placement_result.dart     # core score, buckets, signals
│   │   ├── application/
│   │   │   └── playground_session_controller.dart
│   │   └── presentation/
│   │       ├── handoff_screen.dart       # /child/handoff, §3
│   │       ├── playground_screen.dart    # shell, dot progress, §5
│   │       └── levels/
│   │           ├── find_the_ball_level.dart
│   │           ├── repeat_after_me_level.dart
│   │           ├── tap_the_color_level.dart
│   │           ├── count_the_friends_level.dart
│   │           ├── find_the_letter_level.dart
│   │           ├── match_the_shape_level.dart
│   │           ├── pick_favorites_level.dart     # replaces InterestSelectScreen
│   │           ├── how_do_they_feel_level.dart
│   │           ├── memory_match_level.dart
│   │           └── copy_the_pattern_level.dart
│   └── profile/
│       └── domain/child_profile.dart     # CHANGED: §8 fields
├── screens/
│   └── onboarding_screens.dart           # CHANGED: InterestSelectScreen
│                                          #   deleted; ChildProfileScreen's
│                                          #   "Next" now goes to /child/handoff
└── app/
    └── router.dart                       # CHANGED: §2/§11 routes
```

New dependency: `speech_to_text` (Level 2 only; degrades gracefully per §9
if unavailable — see V3's own precedent of swallowing TTS failures in
`tts_service.dart`). No image/animation/font packages — designless rule
holds outside the freeform `Stack` layout carve-out in §4.1.

---

## 11. Router Changes

```dart
GoRoute(path: '/child/handoff', builder: (_, state) => HandoffScreen(...)),
GoRoute(path: '/playground', builder: (_, state) => const PlaygroundScreen()),
```

Redirect chain (replaces V3 §9's version):
```
restoring session          → /splash
not logged in               → auth flow
logged in, no child         → /select-child → /child/new → /child/handoff
                               → /playground → /home
logged in, child selected   → /home (path screen, at placed lesson if new)
```

`/child/interests` is removed entirely — no route falls back to it.

---

## 12. Implementation Order

1. **`speech_input_service.dart` + `MazaSpeechBubble`** — the two shared
   primitives everything else builds on.
   ✅ *Verify: bubble shows/speaks text on a throwaway test screen; mic
   wrapper returns a result or a graceful null on a device with mic access
   denied.*
2. **Placement domain + `PlaygroundSessionController`** — scoring math,
   bucket table, `PlacementResult`, unit tests for the mapping table itself
   (score → starting lesson) independent of any UI.
   ✅ *Verify: unit tests cover every bucket boundary in §7.2.*
3. **Playground shell + Levels 1, 3, 4, 5** (the four simplest tap-target
   levels — enough to prove the shell, dot progress, and universal timeout
   rule end to end).
   ✅ *Verify: play levels 1–4 on an emulator; timeout auto-advances;
   scores land in the controller.*
4. **Level 7 (interests) replaces `InterestSelectScreen`** in the router;
   delete the old screen once nothing references it.
   ✅ *Verify: `interestIds` still reaches `buildCourseForChild` unchanged.*
5. **Levels 2, 9, 10** (the harder ones — mic, multi-step memory match,
   sequence copy).
   ✅ *Verify: Level 2 completes with mic permission denied; memory match
   and pattern-copy handle their retry/mismatch paths.*
6. **Levels 6, 8** (bonus-signal-only, simplest to build last since nothing
   downstream depends on them yet).
7. **Handoff screen + full router wiring + `ChildProfile` placement fields
   + Path screen's "placed" badge.**
   ✅ *Verify: fresh signup → name/age → handoff → all 10 levels → lands on
   Path auto-scrolled to the placed lesson with correct badges on the
   skipped nodes.*
8. **Settings: "Redo the playground" / "Start over from Lesson 1."**
   ✅ *Verify: redo overwrites placement without touching XP/coins/streak;
   start-over clears `placedLessonIds` only.*

---

## 13. Testing

Unit tests:
- Placement bucket table: every boundary in §7.2, plus the "core score
  computed from exactly levels 1/3/4/5/10, nothing else" invariant.
- `PlaygroundSessionController`: advances on every `onComplete`, times out
  correctly per level, never leaves a level un-scored.
- `placedLessonIds` write: 0 XP/0 coins asserted, `completeLesson`'s
  existing double-pay guard still holds when a placed lesson is later
  actually played.
- `speech_input_service`: mic-denied and package-unavailable paths both
  resolve to a non-throwing "no result," never propagate an exception.

Widget tests:
- Playground shell: dot progress fills correctly across 10 levels using a
  fake level sequence.
- Level 1 (find the ball): tapping the seeded ball position completes with
  score 10; tapping a decoy does not advance; timeout advances with score 3.
- Level 2: completes regardless of whether the fake speech service returns
  a match, a vocalization-only result, or nothing.
- Path screen: a `ChildProfile` with non-empty `placedLessonIds` renders
  the distinct badge on those nodes and auto-scrolls to the correct start.

Manual QA script (run each release, add to V3's existing script):
fresh signup → child name/age → handoff screen → tap "We're ready" → play
all 10 levels naturally (include at least one deliberate timeout and one
deliberate mic-skip) → confirm landing on Path at a sensible lesson with
placed-node badges → Settings → Redo the playground → confirm it overwrites
cleanly → Settings → Start over from Lesson 1 → confirm full course intact.

---

## 14. Decisions Made (defaults chosen — change if you disagree)

- **Placement never crosses into Unit 2, and never skips Unit 1's two review
  lessons.** The core score only decides *where within Unit 1* a child
  starts. Skipping units on a two-minute tap-game heuristic risks exactly
  the gap V3's own "review every 4th node" design exists to catch.
- **No failure state anywhere in the playground.** Every level completes;
  only the score varies. This is a deliberate, stronger version of V3's
  "no hearts/lives" decision, because the playground doubles as the app's
  first impression for kids who may not yet speak at all.
- **The disability/speech-level questions from the original `userflow.md`
  vision are not resurrected here.** They were never implemented past two
  dead `ChildProfile` fields, and V4 deliberately replaces "ask the parent
  to characterize the child" with "watch the child play" — a playground
  level *is* a listening/speech-comfort probe (Level 2), just collected as
  gameplay instead of a clinical-sounding form. A real diagnosis workflow,
  if ever needed, belongs in the parent dashboard as an optional add-on,
  not a signup gate.
- **`speech_to_text` is best-effort, not authoritative.** No pronunciation
  grading in V4 (V3 §12 already deferred "speech recognition/Robot Mode" —
  this doc's Level 2 is a narrow, non-blocking exception scoped to
  "detect any attempt," not the full Robot Mode feature from `userflow.md`).
- **English TTS stays** for spoken lines, matching V3's existing content
  language decision; on-screen bubble text keeps the bilingual convention
  already used by the current onboarding screens.
- **Parent recourse is mandatory, not a nice-to-have** — "Redo the
  playground" and "Start over from Lesson 1" ship in the same release as
  placement itself, not as a fast-follow, because a wrong placement with no
  way to fix it is worse than no placement at all.

## Later (explicitly out of V4 scope)
Real pronunciation/ASR grading and the full Robot Mode "AI checks
pronunciation" loop from `userflow.md` · adaptive branching *within* the
playground (e.g., harder letters if Level 5 goes perfectly) · cross-unit
placement · using `shapeAwareness`/`readyForMultiStep`/`emotionAwareness` for
anything beyond parent-dashboard display · Mongolian TTS · a
"watch your kid's playground session" replay for parents · re-running
individual levels instead of the full 10 on redo.
