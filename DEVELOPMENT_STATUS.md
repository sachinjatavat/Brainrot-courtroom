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
- Security currently teleports the defendant to the jail position rather than running an NPC escort sequence.
- Witness personality output is deterministic data-driven text with random line selection; it does not yet model a persistent lie state or contradiction graph.
- Argument text is length-validated and announced, but not scored by a judge or used in verdict calculation.
