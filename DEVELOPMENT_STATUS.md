# Development status

## Phase 1 - Architecture and Rojo setup
Complete. Rojo mapping, shared modules, server/client boundaries, and documentation are present.

## Phase 2 - Lobby and courtroom map
Complete in source. A procedural courtroom, jury seating, lobby, role spawn anchors, jail door, evidence displays, laboratory, and decorations are generated on server startup.

## Phase 3 - Playable round loop
Implemented. Server-owned roles, briefing/trial/voting/verdict/rewards phases, single-submit jury voting, evidence presentation, witness questioning, accusations, defendant statements/confession choices, role teleportation, rewards, and disconnect cleanup are present.

## Phase 4 - Chaos and judge abilities
Implemented in source. Banana spawning, gravity changes, dance emote requests, judge scaling, reversible position swaps, silence state, security jail teleportation, forced confession state, and verdict reversal have duration/cooldown/cleanup paths. Voice loss is represented as a client-visible event only because Roblox voice services are intentionally not controlled.

## Phase 5 - Deeper trial systems
Implemented in source. Each generated witness has a trial-local story, truthfulness/lie state, answer history, and contradiction detection. Lawyers can inspect and present evidence, trigger witness reactions, and submit arguments scored against genuine/misleading evidence and testimony consistency. Argument scores can resolve ties or overturn a narrow vote margin. Bot witnesses fill small rounds, security NPC models are spawned per round, and courtroom disasters include an evidence mix-up with timed cleanup.

## Phase 6 - Visual polish, animations and player retention
Implemented in source.
- **Upgraded Courtroom Geometry & Lighting**: 150+ detailed architectural components including fluted marble columns with brass capitals, wood wainscoting, ceiling beams, chandeliers, courtroom seal, elevated judge platform with interactive 3D gavel (ProximityPrompt with slam audio and screen shake), witness stand with microphone, defense/prosecution stations with lamps, 2-tier jury box, spectator gallery, and holding cell.
- **Grand Lobby & Waiting Areas**: Marble-tiled entrance hall, reception desk, live matchmaking status billboard (`SurfaceGui`), velvet waiting lounge sofas, coffee table, interactive water cooler, 3-tiered Top Lawyers leaderboard podium, and interactive practice witness dummy.
- **Unlockable Courtroom Themes**: `Classic Mahogany`, `Neo-Tokyo Cyberpunk`, `Ohio Dungeon`, and `Royal Golden Palace` with dynamic material, color, and post-processing lighting adjustments (`BloomEffect`, `ColorCorrectionEffect`, atmospheric fog).
- **Procedural Character Animations & Reactions**: Joint manipulation controller for R15/R6 avatars supporting `OBJECTION`, `GAVEL_SLAM`, `CRY`, `LAUGH`, `DANCE`, and `FACEPALM` with animated reaction billboards, camera screen shake, and safe restoration.
- **Audio Catalog**: Authentic courtroom sound effects using verified Roblox client system assets (`rbxasset://sounds/...`) with volume and pitch adjustments for gavel impacts, dramatic objections, guilty uproar, not guilty victory chimes, cash registration, and countdown ticks.
- **Braincoins Shop & Cosmetics**: Server-authoritative catalog of gavels, lawyer briefcases, particle auras, equippable titles, and courtroom themes across Common, Rare, Epic, and Legendary rarities. Physical props welded to characters via `CosmeticsService`.
- **Progression, Daily Missions & Achievements**: Deterministic daily missions cycling per day seed, lifetime achievement badges, player level/XP scaling, and overhead title tags.
- **Mobile Responsive UI & Low-End Optimization**: Modern HUD with top bar currency/XP indicators, responsive scaling via `UIScale`, popup modals for Shop, Missions, Emotes, and Settings. Includes a Low Graphics Mode toggle that disables expensive shadows and decorative particle emitters for low-end mobile devices.

## Validation boundary
- Automated logic coverage in `ServerScriptService/Tests/LogicTests.lua` validates case generation, roles, verdicts, witness memory contradictions, argument scoring, cosmetics catalog querying, daily missions determinism, theme configuration, audio catalog, and DataService transactions (purchases, equips, missions, achievements). Tests execute successfully in Roblox Studio via Luau execution.
- Roblox Studio testing requirements:
  - Multi-client Start Server test to verify synchronized character cosmetic welds and emote broadcasts across diverse client window sizes.
  - Published place DataStore test to verify persistence across rejoins with API Services enabled.
  - Verification of mobile touch controls on small phone aspect ratios using the Roblox Studio Device Emulator.
