# Maza Talk P02 Master Implementation & Developer Guide

This document serves as your complete, end-to-end master blueprint for developing, building, and verifying the **Maza Talk P02 Wizard-of-Oz interactive Flutter prototype**. Centered on the target word **«Алим» (Apple)**, this guide translates the architecture, state machines, design tokens, and sequence steps into a structured, actionable engineering roadmap.

---

## Part 1: Architecture Overview & Core Setup

### 1.1 Technology Stack & Standards
* **Framework & Language:** Flutter (Null-safe Dart).
* **Target Platforms:** iOS and Android (Optimized for tablets and touch displays).
* **Primary Typography:** **Nunito** font family across all view layers, headers, and speech blocks.
* **Design System Tokens:** Strict adherence to centralized tokens for colors, spacing, and component geometry.

### 1.2 Folder Structure Blueprint
Organize your workspace under `lib/` and `test/` following this structure:
```text
lib/
├── core/
│   ├── constants/       # MazaColors, MazaSpacing, MazaRadius, MazaSizes
│   ├── theme/           # ThemeData configurations (Nunito typography)
│   └── utils/           # Logger, audio helper stubs
├── models/
│   ├── character_state.mo # Maza visual states
│   └── telemetry_event.mo # Analytics & event log structs
├── state/
│   ├── interaction_state.dart  # Enum of 13 states (S00 - S90)
│   ├── interaction_event.dart  # Enum of UI/system events
│   └── interaction_controller.dart # Centralized StateEngine & dispatcher
├── components/
│   ├── maza_character.mo   # Canonical character rendering
│   ├── speech_bubble.mo    # Dialog card component
│   ├── primary_button.mo   # 48dp minimum touch target button
│   └── aac_grid.mo         # Communication grid component
└── screens/
    └── interaction_root.dart # Main orchestrator view switching states
```

---

## Part 2: State Engine & Safety Architecture

### 2.1 The 13 Interaction States (`InteractionState`)
1. `S00_HOME`: Initial splash and launch entry.
2. `S05_INTRO`: Welcoming greeting by Maza.
3. `S10_STIMULUS`: Presenting the stimulus ("Алим").
4. `S15_PROMPT`: Directing the child to speak or select.
5. `S20_WAIT`: Listening state with timeout handling.
6. `S25_PARTIAL`: Handling partial or unintelligible utterances.
7. `S30_CORRECT`: Positive feedback on correct target completion.
8. `S40_HELP`: Guiding scaffold for stuck users.
9. `S50_OFF_PATH`: Safe redirection for off-topic inputs.
10. `S60_AAC_FALLBACK`: Alternative communication grid presentation.
11. `S70_FATIGUE`: Rest break trigger for sustained engagement.
12. `S80_RESUME`: Re-engagement following breaks.
13. `S90_CLOSURE`: Session wrap-up and celebratory exit.

### 2.2 Safety & State Engine Implementation Rules
* **Single Source of Truth:** Never mutate state directly inside widgets. All state transitions flow through `InteractionController.dispatch(InteractionEvent event)`.
* **True Stop Tokening:** Every asynchronous block (such as delayed audio playback or wait timers) must utilize a local `generationId`. If an interrupt event occurs, increment the generation ID to instantly invalidate stale async completions.
* **App Lifecycle Safety:** Register a `WidgetsBindingObserver` in your root controller to automatically trigger `S70_FATIGUE` or pause background audio when the app is minimized or backgrounded.

---

## Part 3: Step-by-Step Build Tutorial (BUILD 01 to BUILD 20)

Follow these phases sequentially to construct the prototype safely and systematically.

### Phase 1: Foundation & Tokens
* **BUILD 01: Project Setup & Dependencies**
  * Initialize the Flutter project, add dependencies (`provider`, `flutter_svg`, `audioplayers`), and configure assets directory.
* **BUILD 02: Design Tokens Setup**
  * Create `lib/core/constants/maza_colors.dart` containing `MazaColors.teal500` (`#28B8A8`), `MazaColors.teal700` (`#087F78`), `MazaColors.navy` (`#183050`), and background creams.
* **BUILD 03: Typography & Touch Targets**
  * Define `MazaSizes.minTouchTarget = 48.0` and configure global Nunito typography themes.

### Phase 2: Core State Engine
* **BUILD 04: State & Event Enums**
  * Code the `InteractionState` enum (13 states) and `InteractionEvent` enum.
* **BUILD 05: InteractionController Core**
  * Implement `InteractionController` with state transition logic, validation guards, and generation token management.
* **BUILD 06: Lifecycle Observer Integration**
  * Wire up `WidgetsBindingObserver` to catch background/foreground state transitions.

### Phase 3: Reusable Components
* **BUILD 07: Primary Button Component**
  * Build a reusable button enforcing the 48dp touch target rule with visual feedback.
* **BUILD 08: Speech Bubble Component**
  * Implement the text card container supporting Mongolian Unicode text rendering with custom padding.
* **BUILD 09: Maza Character Widget**
  * Create the canonical Mazaalai view (sandy fur, teal open-front hoodie, heart-like chest marking) with static/active visual states.

### Phase 4: Screen States (S00 - S30)
* **BUILD 10: S00 Home & S05 Intro Screens**
  * Build initial launch view and introductory speech transition.
* **BUILD 11: S10 Stimulus & S15 Prompt Screens**
  * Implement the core stimulus view displaying «Алим» with visual and audio cues.
* **BUILD 12: S20 Wait & S25 Partial Screens**
  * Add silence timers and partial response handling loops.
* **BUILD 13: S30 Correct State Screen**
  * Design the celebratory success screen for correct target completion.

### Phase 5: Safety, Help & Fallbacks (S40 - S60)
* **BUILD 14: S40 Help Scaffold**
  * Implement the tiered help system with generation token cancellation.
* **BUILD 15: S50 Off-Path Redirection**
  * Build the gentle redirection card for unexpected user input.
* **BUILD 16: S60 AAC Fallback Grid**
  * Create the alternative communication grid for non-verbal or supported modes.

### Phase 6: Fatigue, Resume & Closure (S70 - S90)
* **BUILD 17: S70 Fatigue & S80 Resume Screens**
  * Implement the rest break overlay and safe return pathway.
* **BUILD 18: S90 Closure Screen**
  * Build the final session summary and wrap-up screen.

### Phase 7: Testing & Verification
* **BUILD 19: Automated Test Suite Execution**
  * Execute all 146 unit and widget tests covering state transitions, safety guards, and touch targets.
* **BUILD 20: QA Gate & Real-Device Audit**
  * Perform accessibility audits, screen-reader checks, and touch target validations on physical Android and iOS devices.

---

## Part 4: QA & Verification Checklists

### 4.1 Accessibility Gates
* [ ] All interactive elements meet or exceed the `48 × 48 dp` minimum touch target size.
* [ ] Color contrast ratios between text and background meet WCAG AA standards.
* [ ] Screen readers properly announce Maza's dialogue speech bubbles in logical tab orders.

### 4.2 State Machine Integrity Checks
* [ ] Rapid double-taps on buttons do not trigger double-state transitions or corrupt the `turnId`.
* [ ] Backgrounding the app successfully pauses timers and invokes safe state handling.
* [ ] True Stop generation tokens successfully cancel pending asynchronous audio or wait routines.

---

With this master guide, you are ready to construct and verify the Maza Talk P02 build efficiently and robustly. Let me know which specific build step you would like to tackle first!