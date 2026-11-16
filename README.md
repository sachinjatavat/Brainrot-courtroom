# BRAINROT COURTROOM: THE FINAL VERDICT

An original, asset-free Roblox courtroom party game built in Luau with Rojo. Players become judges, lawyers, witnesses, defendants, and jury members while procedurally generated absurd cases spiral into chaotic verdicts.

## Features

- **Procedural Courtroom & Grand Lobby**: Detailed architecture with fluted marble columns, brass capitals, wainscoting, chandeliers, elevated judge bench with interactive 3D gavel (click/prompt to slam with audio and camera shake), witness stand with microphone, lawyer desks with lamps, 2-tier jury box, spectator pews, holding cell, and a grand waiting lobby with a live matchmaking billboard, lounge seating, water cooler, leaderboard podium, and interactive practice witness dummy.
- **Dynamic Courtroom Themes**: Switch between `Classic Mahogany`, `Neo-Tokyo Cyberpunk`, `Ohio Dungeon`, and `Royal Golden Palace` themes with real-time floor/wall material changes, color shifts, and atmospheric lighting adjustments (`BloomEffect`, `ColorCorrectionEffect`, custom ambient and fog).
- **Authoritative Round & Trial Systems**: 6 distinct player roles (Judge, Prosecutor, Defense, Defendant, Witness, Jury) across timed phases (Lobby, Briefing, Trial, Voting, Verdict, Rewards). Includes single-submit jury voting, bot jury fill for small servers, and disconnect cleanup.
- **Deep Trial & Evidence Mechanics**: Randomly generated absurd cases, genuine vs misleading evidence exhibits, witness memory with lie detection and contradiction discovery, and lawyer argument scoring against case facts.
- **Procedural Character Animations & Reactions**: Joint-manipulated R15/R6 animations for `OBJECTION!`, `GAVEL SLAM`, `CRY`, `LAUGH`, `DANCE`, and `FACEPALM` with floating reaction billboards, sound stings, and camera screen shake.
- **Dramatic Verdict Sequences**: Fullscreen dramatic verdict presentation with custom camera shake, dark crimson dimming and jail escort for guilty defendants, and confetti explosions with victory dances for acquitted defendants.
- **Verified Audio Catalog**: Custom sound manager powered by verified built-in Roblox client system audio (`rbxasset://sounds/...`) and procedural pitch synthesis for gavel strikes, objection stingers, guilty uproars, victory chimes, cash sounds, and countdown clocks—zero broken or unverified asset IDs.
- **Braincoins Shop & Cosmetic Inventory**: Complete server-validated economy for purchasing and equipping gavel skins, lawyer briefcases, particle auras, player titles, and courtroom themes across Common, Rare, Epic, and Legendary rarities. Equipped props are dynamically welded to player characters upon spawning.
- **Progression, Daily Missions & Achievements**: Automated cycling daily missions, lifetime achievements with coin/XP rewards, level progression, and glowing overhead player title billboards.
- **Mobile Responsive Modern UI & Performance Modes**: Sleek glassmorphism top HUD with coins, level, and XP counters, responsive `UIScale` adaptation for desktop, tablet, and mobile screens, and a Low Graphics Mode toggle that disables heavy shadows and decorative particle emitters for low-end mobile devices.

## Project layout

- `src/ReplicatedStorage/Shared`: Shared configuration, case generation, roles, verdicts, witness memory, argument scoring, cosmetics catalog, progression missions, themes, animations, audio catalog, and performance presets.
- `src/ServerScriptService`: Authoritative round management (`RoundService`), player data persistence & shop validation (`DataService`), procedural map builder & themes (`MapBuilder`), character cosmetic welding (`CosmeticsService`), and logic tests.
- `src/StarterPlayer/StarterPlayerScripts`: Mobile-responsive client controller (`CourtroomClient`) managing HUD, action drawers, modal popups (Shop, Missions, Emotes, Settings), screen shake, and audio playback.

## Import & Setup

1. Install [Rojo](https://rojo.space/) (v7.4+ recommended).
2. Run `rojo serve` from this repository.
3. Open Roblox Studio, open the place or a new baseplate, open the Rojo plugin, and click **Connect**.
4. To test persistence: Publish the place to Roblox and enable **Game Settings > Security > Enable Studio Access to API Services**. (In offline/unpublished Studio sessions, `DataService` safely operates in local fallback mode).

## Testing checklist

- Run automated logic tests anytime via `src/ServerScriptService/Tests/LogicTests.lua` (all tests pass in Studio edit mode).
- Start Studio's **Start Server** test with 2+ players:
  - Verify role assignments and role stations.
  - Test lawyer evidence presentation, witness questioning, and argument scoring.
  - Test jury voting and dramatic verdict presentation.
  - Open the Shop modal and test purchasing and equipping items.
  - Open the Missions modal and test claiming daily mission rewards.
  - Open the Emotes modal and trigger `OBJECTION!`, `DANCE`, or `CRY`.
  - Resize the window or use the Studio Device Emulator to test mobile touch layouts and scaling.
