# PROJECT_V2.md

## Project Overview

This application is an AI-powered educational app designed for children around 5 years old. The goal is to teach through conversation, curiosity, and play rather than traditional alphabet drills.

The experience should feel like going on an adventure with a companion rather than completing school lessons.

---

## Core Philosophy

The app should adapt to every child instead of forcing every child through the same learning path.

Lessons should feel personal, engaging, and connected to the child's interests.

---

## Target Audience

- Children aged 4–7
- Parents setting up the account
- Android-first

---

## Platform

Primary platform:

- Android

The UI should be responsive and follow Flutter best practices.

---

## User Flow

### First Launch

The parent creates an account or signs in.

After authentication, the app asks questions about the child.

Questions include:

- Name
- Age
- Gender (optional)
- Interests

Interests should be presented visually instead of as text.

Example interests:

- Dinosaurs
- Cars
- Trains
- Animals
- Space
- Princesses
- Music
- Ocean
- Art

Parents can choose multiple interests.

---

## World Generation

After setup, the app generates a personalized learning world.

The map is generated from reusable lesson templates.

Different lesson paths can be rearranged depending on the child's interests.

This means every child has a slightly different adventure while still covering the same educational objectives.

---

## Main Experience

There is no traditional home screen.

When the app opens, it should always continue exactly where the child left off.

The user should never have to search for today's lesson.

Flow:

Launch App  
↓  
Continue Previous Lesson  
↓  
Complete Lesson  
↓  
Unlock Next Area  
↓  
Save Progress  
↓  
Close App  
↓  
Next launch returns here  

---

## Main Character

There is one main companion character.

This character stays with the child throughout the entire experience.

As the child progresses, the companion evolves through visual changes, animations, personality, dialogue, and unlockable accessories.

The child should feel like they are growing together with their companion.

---

## Learning Style

Instead of teaching isolated letters, the AI teaches through topics.

Example:

If the child likes dinosaurs:

- Counting dinosaurs  
- Reading dinosaur names  
- Colors  
- Shapes  
- Simple English  
- Vocabulary  
- Storytelling  

If the child likes space:

The same educational concepts are taught through planets, rockets, and astronauts.

Educational goals stay consistent while the theme changes.

---

## Authentication

Keep the existing authentication system.

Reuse:

- Login
- Signup
- Password reset

Modify onboarding to collect child information instead of the previous setup flow.

---

## Progress

Progress should automatically save.

When reopening the app, the child should return directly to:

- the lesson they were working on
- the exact checkpoint if possible

No manual "Continue" button should be required.

---

## Technical Requirements

- Flutter
- Firebase Authentication
- Firestore
- Riverpod
- Clean Architecture
- Responsive UI
- Android compatible
- Material 3
- No duplicated code
- Reusable widgets

---

## AI Requirements

The AI should adapt lessons using:

- age
- interests
- previous mistakes
- completed lessons
- difficulty

The child should feel like the AI remembers them.

---

## Things Removed

Remove:

- Previous alphabet-first approach
- Previous home screen
- Old navigation flow
- Letter teaching pages

---

## Success Criteria

The app should:

- feel like an adventure
- always continue where the child left off
- personalize content
- work smoothly on Android
- have clean, maintainable code
- be easy to expand with new lesson themes

---

## Design Note

One improvement suggestion:

Instead of using gender to decide interests, show all children a wide variety of interests equally.

Example:

- 🦖 Dinosaurs
- 🚗 Cars
- 🚂 Trains
- 🚀 Space
- 🐠 Ocean
- 🐶 Animals
- 🎵 Music
- 🎨 Art
- 👑 Fairy tales
- ⚽ Sports

Let the child choose freely so personalization is based on real interest rather than assumptions.