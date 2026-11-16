# BRAINROT COURTROOM: THE FINAL VERDICT

An original, asset-free Roblox courtroom party game built in Luau with Rojo. Players become judges, lawyers, witnesses, defendants, and jury members while procedurally generated absurd cases spiral into chaotic verdicts.

## Import

1. Install [Rojo](https://rojo.space/).
2. Run `rojo serve` from this repository.
3. Open Roblox Studio, install the Rojo plugin, and connect to the project.
4. Publish the place and enable **Game Settings > Security > Enable Studio Access to API Services** when testing persistence.

The map is generated from Roblox primitives at runtime. No unverified asset IDs or paid assets are required.

## Project layout

- `src/ReplicatedStorage/Shared`: shared configuration, case generation, roles, verdicts, and network names.
- `src/ServerScriptService`: authoritative persistence, map generation, round state, voting, rewards, and cooldown validation.
- `src/StarterPlayer/StarterPlayerScripts`: responsive runtime UI and input actions.

## Implemented gameplay

The server assigns Judge, Prosecutor, Defense, Defendant, Witness, and Jury roles, runs complete timed rounds, teleports players to role stations, generates cases and evidence, supports evidence presentation and witness questioning, validates single-submit jury votes, awards results, and cleans up disconnected players.

Judge abilities have server-side role and per-player cooldown checks. Banana rain creates physical objects; gravity glitch, judge tiny, position swap, order silence, security, forced confession, and reverse verdict have live state or character effects with cleanup. The UI exposes role-specific controls and verdict results across resizable layouts.

## Testing checklist

- Start with 2+ players in Studio's **Start Server** test mode.
- Confirm each player receives exactly one role and jury-only voting is enforced.
- Advance through Briefing, Trial, Voting, Verdict, and Rewards phases.
- Disconnect a player during a trial and confirm the server continues without errors.
- In a published test place, confirm DataStore access and verify Braincoins/XP survive rejoin.
- Resize the client window or use the Device Emulator to check UI scaling.

The repository includes a server-side smoke module at `src/ServerScriptService/Tests/LogicTests.lua`. It does not replace Roblox Studio testing: DataStore access, RemoteEvents, spawning, prompts, animations, disconnects, and multiplayer synchronization must be verified in a published or local Studio server session.

Roblox Studio execution is required to validate engine behavior; static project structure can be checked before importing.

## Asset manifest

The project intentionally uses procedural geometry and Roblox materials. Add only original or properly licensed sounds and textures in Studio; recommended replacement points are documented in `src/SoundService/README.txt`.
