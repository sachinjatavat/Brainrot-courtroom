# Development status

## Phase 1 - Architecture and Rojo setup
Complete. Rojo mapping, shared modules, server/client boundaries, and documentation are present.

## Phase 2 - Lobby and courtroom map
Complete in source. A procedural courtroom, jury seating, lobby, role spawn anchors, jail door, evidence displays, laboratory, and decorations are generated on server startup.

## Phase 3 - Playable round loop
Implemented. Server-owned roles, briefing/trial/voting/verdict/rewards phases, single-submit jury voting, evidence presentation, witness questioning, accusations, defendant statements/confession choices, role teleportation, rewards, and disconnect cleanup are present.

## Phase 4 - Chaos and judge abilities
Implemented in source. Banana spawning, gravity changes, dance emote requests, judge scaling, reversible position swaps, silence state, security jail teleportation, forced confession state, and verdict reversal have duration/cooldown/cleanup paths. Voice loss is represented as a client-visible event only because Roblox voice services are intentionally not controlled.

## Remaining limitations
- Roblox Studio multiplayer testing has not been run in this environment; engine behavior, UI layout on devices, animation availability, prompts, and DataStore permissions still need verification.
- The courtroom uses generated primitives and placeholder interaction prompts; it has no authored audio, avatars, or persistent evidence inventory.

## Phase 5 - Deeper trial systems
Implemented in source. Each generated witness now has a trial-local story, truthfulness/lie state, answer history, and contradiction detection. Lawyers can inspect and present evidence, trigger witness reactions, and submit arguments scored against genuine/misleading evidence and testimony consistency. Argument scores can resolve ties or overturn a narrow vote margin. Bot witnesses fill small rounds, security NPC models are spawned per round, and courtroom disasters include an evidence mix-up with timed cleanup.

## Validation boundary
- Shared logic coverage is present in `ServerScriptService/Tests/LogicTests.lua`; static Luau validation still needs to be run with the project's Rojo/Aftman toolchain.
- Roblox Studio testing is still required for RemoteEvent wiring, generated NPC/model behavior, client UI layout, chaos cleanup under disconnects, and multiplayer timing/DataStore permissions.
