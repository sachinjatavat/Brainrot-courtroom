# Architecture

The server owns round state, roles, case generation, votes, cooldowns, rewards, and persistence. Clients only render replicated snapshots and request actions through `CourtroomAction`.

## Runtime flow

1. `Main.server.lua` creates the remotes, builds the procedural map, starts persistence, and starts `RoundService`.
2. `RoundService` rotates through Lobby, Briefing, Trial, Voting, Verdict, and Rewards.
3. `CaseGenerator` creates a fresh crime, evidence set, and witness personalities every round.
4. `RoleAssigner` shuffles players using a server-only `Random` instance.
5. Jury votes are validated against the server role map. Missing players are represented by virtual jury bots so small servers still resolve.
6. `DataService` writes Braincoins, XP, levels, cosmetics, and daily reward timestamps with `UpdateAsync`.

## Security boundaries

- The client cannot assign roles, submit votes outside the Voting phase, vote as non-jury, alter rewards, or activate judge powers without the server role.
- Judge power names are converted to strings and rate-limited server-side.
- DataStore calls are wrapped in `pcall`; failed saves are logged rather than silently treated as success.

## Extension points

Add new crimes, witnesses, evidence, chaos events, cosmetics, and punishments in the shared data modules or the round reward table. New client UI can subscribe to `CourtroomState` without changing authoritative logic.
