---
# DESIGN.md — Excloud App Status Pages
---

## The Concept

**"Control room calm."** These pages exist in a moment of vulnerability — someone just paid for something and is waiting for it to exist. The design absorbs anxiety by projecting quiet confidence. Not "please wait," but "we've got this."

## The Hook

Two different *symbols* that communicate state without words:

- **Initializing:** A radar-like pulse beacon — concentric rings expanding outward from a warm glowing core. It reads as "scanning, reaching, deploying" — active progress without a progress bar (which would be dishonest since we don't know percentages).
- **Unavailable:** Two vertical pause bars — the universal "paused" symbol. Instantly communicates "temporarily stopped, not broken." It's the difference between a dead screen and a deliberate pause.

Both use the same design language but are immediately distinguishable at a glance.

## Typography Rationale

System font stack. This is deliberate, not lazy — these pages need to load *instantly* on first paint with zero layout shift. A custom font would flash or delay, exactly when the user needs immediate reassurance. The system stack also feels "native" to the platform, like a real system notification rather than a marketing page pretending nothing is wrong.

Tight negative letter-spacing on headings (-0.02em) gives them weight without needing a heavier font. The all-caps labels (0.15em tracking) create structural hierarchy — they read as metadata, not prose.

## Color Rationale

Warm amber/copper accent (#c4956a for initializing, #b5874f for unavailable) against near-black. Why warm:

- Cool blues/greens say "corporate status page" — the thing you see when AWS is down and you're panicking. Wrong association.
- Warm amber says "campfire," "instrument panel," "something alive." It's the color of active signals, not error states.
- The unavailable page shifts slightly cooler/darker in its amber — still the same family, but perceptibly "dimmer," like a light that's been turned down, not off.

The backgrounds use extremely subtle texture — a grid for initializing (structured, "things are happening in order"), dots for unavailable (quieter, ambient). Both are masked to only appear in the center, creating depth without clutter.

## Layout / Structure Rationale

Vertically centered, single column, no card/container. The content floats in space rather than sitting in a box. Cards create a boundary between "the page" and "the content" — here the content IS the page. There's nowhere else to look, nothing else to do. The design embraces that.

The status bar at the bottom (pill-shaped, border, dot + text) acts as a grounding element — it's the one piece that feels "UI" rather than "page," giving the user something concrete to anchor to. "This page refreshes automatically" is the key information and it's given its own component.

## What Was Rejected

- **Progress bars / steps.** Considered showing "Step 1: Pulling images, Step 2: Starting containers" etc. Rejected because (a) we don't have real-time progress data from inside the VM, so it would be fake, and (b) non-technical users don't care about docker pulls. Honesty over theater.
- **Large app icons/logos.** Considered fetching and displaying the app's icon. Rejected — we don't have guaranteed access to icons at the Caddy level (it's static HTML), and a missing/broken image would undermine trust more than no image at all.
- **Animated gradient backgrounds.** The obvious "premium loading screen" move. Rejected — it reads as marketing rather than infrastructure. These pages should feel like part of the *platform*, not a splash screen.
- **Any JavaScript.** Could have done smoother animations or real-time status checks via JS. Rejected — pure CSS keeps the page weight near zero, works with CSP restrictions, and the meta-refresh approach is honest about what's happening (polling, not streaming).

## Tone & Texture

The initializing page should feel like watching a satellite deploy — calm, methodical, the machinery is working. The grid texture reinforces "structured process."

The unavailable page should feel like a brief intermission — the lights are dimmed, not off. The dot texture is softer, the pause symbol is immediately readable, and "taking a moment" is human language, not tech jargon.

Both avoid the word "error." Neither page is an error. One is a process, the other is a pause.

## The Small Detail Nobody Will Notice

The beacon rings on the initializing page are staggered by 0.8s, not the typical 0.5s. This creates a slower, more deliberate rhythm — closer to breathing than to a loading spinner. It subconsciously signals "this is supposed to take a minute" rather than "something is stuck."
