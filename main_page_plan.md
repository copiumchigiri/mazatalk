# Main Page Plan

Design spec for the main/home page, evolving doc — edit freely.

## Overview

Make the main page feel like a game hub, not a plain app screen.

## Top Bar

### Top Right — Child PFP

- Circular profile picture, unique per child.
- Tapping it opens the **Skin/PFP Selection Screen** (see below).
- Coins counter shown directly next to the PFP.

### Top Left — Hamburger Menu

- Standard 3-line hamburger icon.
- Opens a slide-out side drawer (slides in from the side, not a popup).
- Bottom of the drawer has destructive/account actions in red, like a normal app:
  - Log out
  - Change child

## Skin / PFP Selection Screen

Opened by tapping the child's PFP on the main page.

- **Top**: shows the currently equipped PFP/skin, large.
- **Below that**: a 3-row grid of unlocked skins.
  - Circular avatars with clean borders (no clutter).
  - Skin name shown under each avatar.
  - Name color indicates rarity tier:
    - Blue = standard
    - Green = standard (tier above blue, exact order TBD)
    - Purple = rare
    - Gold = top tier
  - (Tune exact tier order/names later — for now: blue, green, purple, gold.)
- **Locked skins**:
  - Shown dimmed/greyed out.
  - Price displayed in coins (gold coin icon + number).
  - Unlocked permanently once purchased with coins.
- **Coins** are earned by making progress through classes.

## Main Page — Bottom Section

- A time-period selector, ordered chronologically:
  - Dinosaurs → Stone Age → ~1200 Mongolia → Modern day
  - (These are placeholder eras for now — names/count subject to change.)
- Each time period contains multiple classes.
- **Current classes stay exactly as they are for now** — no changes to existing class content, only the surrounding navigation/structure.

## Class Framework (applies to every class)

Style: Duolingo-style — big fonts, bold, consistent visual language across all classes.

### Top Bar Inside a Class

- **Top left**: Exit button.
  - Tapping it shows a confirmation dialog: "Are you sure? You will lose all progress."
  - (Behavior may change later — e.g. save progress instead of losing it — but lose-progress-on-exit is the v1 behavior.)
- **Rest of the top bar**: a progress bar showing how far through the class the child is.

## Open Questions / TBD

- Exact rarity tier order and names (blue/green/purple/gold — confirm order).
- Full list of skins per tier and their coin prices.
- Full list of classes within each time period.
- Whether exiting a class should eventually save partial progress instead of discarding it.
