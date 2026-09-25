# Maza's trip — art brief

The post-signup test is now **«Мазагийн аялал»**: 9 levels in 3 acts. Everything
on screen is currently drawn in code as a placeholder, so the app is fully
playable today. To replace a placeholder, export a PNG with the exact file name
below into `assets/art/` — **no code change needed**. Any file you leave out
keeps its placeholder, so art can arrive piece by piece.

## Style

- Friendly, soft, rounded shapes; thick clean outlines are fine. Reference: the
  existing Maza logo (`assets/images/logo.png`) — same bear, same warm brown fur,
  same teal hoodie.
- Palette anchors: brand cyan `#00C0D5`, light cyan `#AFEEF5`, pink `#F34BFF`,
  warm brown fur, sun-yellow `#FFC800`. Kept bright but not neon.
- The audience is 3–6 years old and **pre-readers**: every object must be
  recognisable at a glance with no text. No text baked into any image.
- Never red-as-wrong. Red only appears as a paint colour (the red pot).
- Mongolian context where it fits: sheep, gers, open steppe, rivers.
- PNG, transparent background, sRGB. Export at 3× the "display size" below
  (e.g. bush displays at ~92×84 pt → export ~276×252 px).

## Priority 1 — biggest change to how it feels

| File | What | Display size | Where it's used |
|---|---|---|---|
| `act1_bg.png` | Meadow: rolling green hills, sky, few flowers. **Pale** — tiles sit on top. Portrait. | full screen, 1080×2340 | Act 1 background |
| `act2_bg.png` | Riverside: river bands, reeds, far mountains. Pale. | full screen | Act 2 background |
| `act3_bg.png` | Warm evening by a white ger, sun low. Pale. | full screen | Act 3 background |
| `bush.png` | A round bush, no ball. Must look "hide-able". | 92×84 | Find the Ball (8 per scene; the ball hides under one) |
| `ball.png` | Maza's ball — bright, cyan/white, cheerful. | 44×44 | Find the Ball reveal |
| `sheep.png` | One cute sheep, side view, facing right. | 68×56 | Count the Friends (2–5 shown) |
| `pot_red.png` `pot_blue.png` `pot_green.png` `pot_yellow.png` | A paint pot filled with that colour. **Colours must be unambiguous** (this is the colour-knowledge test). | 96×96 | Tap the Color |

## Priority 2 — the puzzle and feeling levels

| File | What | Display size | Where |
|---|---|---|---|
| `shape_circle.png` `shape_square.png` `shape_triangle.png` | Solid toy-block pieces (chunky, friendly). | 96×96 | Match the Shape: the draggable piece + filled hole |
| `shape_circle_hole.png` `shape_square_hole.png` `shape_triangle_hole.png` | The matching **cut-out**: same silhouette, recessed / dashed outline, on a light tile. Same size and centring as the solids. | 96×96 | Match the Shape holes |
| `face_happy.png` `face_sad.png` `face_angry.png` `face_scared.png` | A friend character's face showing the feeling. **Very clear**, exaggerated expressions (this is the emotion-awareness test). Same character, same colours, four expressions. | 84×84 | How Do They Feel |
| `backpack.png` | Maza's little travel backpack, open front. | 64×64 | Pick Favorites |
| `interest_dinosaurs.png` `interest_cars.png` `interest_trains.png` `interest_space.png` `interest_ocean.png` `interest_animals.png` `interest_music.png` `interest_art.png` `interest_fairyTales.png` `interest_sports.png` | One simple icon-style picture for each interest: dinosaur, car, train, rocket, wave/fish, animal (e.g. horse), music note/instrument, paint palette, storybook/castle, football. Same style as each other. | 36×36 (in tile) | Pick Favorites tiles and backpack slots |

## Priority 3 — Maza himself (I will wire these in once they exist)

Right now Maza is the flat logo everywhere. Poses of the same bear, transparent
PNG, ~600×600 px:

| File | Pose | Would be used |
|---|---|---|
| `maza_idle.png` | Standing, friendly wave | Speech bubble avatar, act intro cards |
| `maza_cheer.png` | Arms up, jumping | Correct answers, end of each act |
| `maza_oops.png` | Head tilt, gentle "hmm" (not sad) | Try-again nudge |
| `maza_walk.png` | Side-view walking | Progress-bar marker |
| `maza_backpack.png` | Wearing the backpack | Act 3 intro |

## Not art, but the game needs it (audio)

The playground currently has **no sound effects at all**. Short, soft, child-safe:

- `sfx_correct` — bright chime (~0.6 s) with the star burst
- `sfx_tryagain` — soft low "boop", never a buzzer (~0.4 s)
- `sfx_act_start` — short fanfare when an act intro opens (~1.5 s)
- `sfx_pad_1` `sfx_pad_2` `sfx_pad_3` — three distinct notes for the Copy the
  Pattern pads (cyan / pink / yellow)
- `sfx_ball_pop` — bouncy pop when the ball is revealed

Also worth considering: a **real recorded Mongolian voice** for Maza's ~30 lines
(`tools/tts_phrases.txt`). The current voice is free synthetic speech (Microsoft
`mn-MN-YesuiNeural`); a warm human recording would be noticeably better for
children and is a drop-in replacement for the mp3s in `assets/audio/tts/`
(file name = first 12 hex chars of sha1 of the phrase — the generator script
prints them).

## Where things live in code (for whoever wires new art)

- Placeholders: `lib/features/placement/presentation/art/painters.dart`
- Art loader (PNG if present, else placeholder): `art/play_art.dart`
- Act text and order: `lib/features/placement/domain/playground_acts.dart`
