# MULTIPLAYER TEST PLAN: BRAINROT COURTROOM — THE FINAL VERDICT

**Game Title**: BRAINROT COURTROOM: THE FINAL VERDICT  
**Supported Server Size**: 2–12 Players (Scalable with Autonomous Bot Essentials)  
**Target Server Size**: 8–12 Players  
**Test Frameworks**: Automated Unit & Logic Tests (`lune run scripts/run_tests.luau` & `selene src`), Roblox Studio Multi-Client Local Server (2–8 clients), Live Playtest (Roblox Public/Private Server).

---

## 1. Test Environment Summary & Distinctions

| Environment | Mode | Automated vs Manual | Scope & Coverage |
|---|---|---|---|
| **Lune Test Engine** | CLI Headless Luau Runtime | **Automated** | 100% logic coverage: DataStore data loss safety, session locks, 2/3/4/8/12 role assignment, witness contradiction rules, zero false-positives, chaos events, cosmetic validation, bot jury calculations. |
| **Selene Linter** | CLI Static Analysis | **Automated** | 100% syntax, Luau semantics, undefined variable detection, standard library usage rules. |
| **Roblox Studio Multi-Client** | Test > Start (2 to 8 Players) | **Manual Simulation** | Network replication, client UI modals, character animations, tween visual effects, sound playback, physics-based chaos impulses (bananas, water flood, meme orbs). |
| **Live Playtest** | Published Place | **Manual / Production** | Production DataStore persistence across servers, global matchmaking, mobile touch responsiveness, real latency. |

---

## 2. Complete End-to-End Match Flow Test

### Flow Sequence
$$\text{Lobby} \longrightarrow \text{Role Assignment} \longrightarrow \text{Briefing} \longrightarrow \text{Trial} \longrightarrow \text{Evidence} \longrightarrow \text{Witness} \longrightarrow \text{Arguments} \longrightarrow \text{Chaos} \longrightarrow \text{Voting} \longrightarrow \text{Verdict} \longrightarrow \text{Punishment / Release} \longrightarrow \text{Rewards} \longrightarrow \text{Lobby Reset}$$

### Detailed Step-by-Step Test Procedure

| Phase | Action / Event | Expected System Behavior | Verification Check |
|---|---|---|---|
| **1. Lobby** | Players gather in waiting area. | Countdown active (`state.Phase == "Lobby"`). Intermission displays status banner. Players can access Shop, Dossier, Missions, and Settings. | Minimum player check (`>= 2`). If `< 2`, round pauses in Lobby. |
| **2. Role Assignment** | Intermission ends. `RoleAssigner.Assign` executes. | Fair rotation algorithm checks history. Missing essentials filled by bots if players `< 4`. | All 4 essential roles (`Judge`, `Prosecutor`, `Defense`, `Defendant`) exist. Never assign missing role to a fake player. |
| **3. Teleport & Briefing** | Players teleported to courtroom podiums. | Judge on judicial bench, lawyers at respective tables, defendant at stand, jury in gallery, spectators in rear. Case generated with structured GroundTruth. | Case briefing text displayed on client status panel. Judge theme applied to map geometry and lighting. |
| **4. Trial Phase** | Timer starts (e.g. 60–90s). Trial actions enabled. | Action bar displays role-specific abilities. Bot lawyers/defendant submit automated actions if small server. | Argument box visible for Prosecutor & Defense. Judge controls visible for Judge. |
| **5. Evidence Presentation** | Prosecutor or Defense clicks "PRESENT EVIDENCE" with Exhibit ID. | Server validates role, phase, and evidence ID. Broadcasts exhibit inspection and fires objection emote/sound. | Exhibit details replicated to all clients. Argument score increments for valid presentation. |
| **6. Witness Questioning** | Lawyer clicks "QUESTION WITNESS" (optionally selecting topic: LOCATION, TIME, OBJECT, ACTION). | Server retrieves structured witness story for topic. `WitnessMemory.Record` processes statement against memory and active evidence. | **Zero false-positives** across different topics. Genuine contradiction flags only if conflicting statement on same topic or disproven by reliable evidence. |
| **7. Arguments Submission** | Lawyer types argument in argument box and clicks "SUBMIT ARGUMENT". | Server validates character limit (<= 180), scores argument via keyword and evidence correlation, awards points to side. | Objections triggered. Spectators react with BillboardGui text bubbles. Longest argument tracked. |
| **8. Chaos Event** | Random chaos timer triggers during Trial. | Server executes real event (`VOICE_LOSS`, `COURTROOM_FLOOD`, `BANANA_FLOOD`, `BRAINROT_INVASION`, `GRAVITY_GLITCH`, `POSITION_SWAP`, `JUDGE_TINY`, `EVERYONE_DANCES`, `EVIDENCE_MIXUP`, `COURTROOM_EXPLOSION`). | Visual & gameplay effects execute. Cooldown tracked. Complete cleanup on duration expiry without permanent map damage. |
| **9. Jury Voting** | Trial timer reaches 0. Phase transitions to "Voting". | Jury action bar displays "GUILTY" and "NOT GUILTY". Bot jury members calculate votes based on argument scores & authentic evidence. | Each juror can vote exactly once. Non-jury cannot vote. Ties resolved by argument scores or Judge tie-breaker. |
| **10. Verdict** | Voting timer expires. `Verdict.Calculate` determines outcome. | Camera shakes, dramatic verdict overlay displayed. Sound sting plays (`VerdictGuilty` or `VerdictNotGuilty`). | Reverse Verdict judge power respected if triggered. |
| **11. Punishment / Release** | **If GUILTY**: Humanoid security guards march to defendant stand and escort defendant to jail cell. **If NOT GUILTY**: Victory confetti rains, defense & defendant dance. | Escort sequence runs with full fallback protection if defendant disconnected or missing. | Defendant locked in jail cell or confetti folder cleaned up. |
| **12. Rewards** | Phase transitions to "Rewards". | Participation, conviction, defense, and judge XP & Braincoins distributed via `DataService.ProcessReward`. Daily mission & achievement progress recorded. | Duplicate reward tokens rejected (idempotency). Currency & level synced to clients. |
| **13. Lobby Reset** | Rewards timer expires. `cleanupRound` executes. | All active chaos effects cleared, security & spectator NPC folders destroyed, players teleported back to lobby at `(0, 5, 125)`. | Roles, votes, arguments reset. Game enters Lobby for next trial. |

---

## 3. Specific Edge Case & Regression Test Matrix

### Test Case A: Small Server Role Scaling (2 & 3 Players)
- **Setup**: Start Studio with 2 clients.
- **Verification**:
  - Client 1 = Judge, Client 2 = Prosecutor.
  - `state.BotRoles` contains `Defense` (`BOT_DEFENSE`) and `Defendant` (`BOT_DEFENDANT`).
  - Bot Defense objects and submits arguments autonomously during Trial.
  - Bot Defendant gives plea statement.
  - Bot jury casts minimum 3 votes during Voting phase.
  - Neither Client 1 nor Client 2 is assigned duplicate or missing roles.

### Test Case B: Player Disconnect Handling
- **Setup**: Start Studio with 4 clients.
  - Client 1: Judge
  - Client 2: Prosecutor
  - Client 3: Defense
  - Client 4: Defendant
- **Sub-case 1 (Judge Disconnect)**: Client 1 exits during Trial.
  - Juror is promoted to Acting Judge; if no juror, `BOT_JUDGE` is sworn in immediately.
- **Sub-case 2 (Defendant Disconnect)**: Client 4 exits during Trial.
  - `BOT_DEFENDANT` is assigned; trial proceeds to verdict; security guards execute safe escort fallback without throwing nil errors.
- **Sub-case 3 (Prosecutor/Defense Disconnect)**: Client 2 or 3 exits during Trial.
  - Bot lawyer assumes duties without crashing trial scoring.

### Test Case C: Witness Contradiction False-Positive Immunity
- **Setup**: Question a truthful witness 10 consecutive times across `LOCATION`, `TIME`, `OBJECT`, and `ACTION`.
- **Expected**: Exactly 0 contradictions flagged.
- **Setup**: Question a lying witness on `LOCATION` with statement A, then on `LOCATION` with conflicting statement B.
- **Expected**: Exactly 1 genuine internal contradiction flagged (`Type == "INTERNAL"`).
- **Setup**: Present unreliable evidence (e.g. Blurry Photo) and question witness on that topic.
- **Expected**: Exactly 0 contradictions flagged.
- **Setup**: Present authentic reliable evidence (e.g. CCTV Log) that conflicts with witness statement on `LOCATION`.
- **Expected**: Exactly 1 evidence-exposed contradiction flagged (`Type == "EVIDENCE"`).

### Test Case D: DataStore Failure & Session Lock Safety
- **Setup**: Simulate network/service error during profile load (`GetAsync` failure).
- **Expected**: `profileMeta.SafeToSave` is `false`. Subsequent calls to `DataService.Save` abort immediately. Existing player DataStore data is completely protected from overwrite.
- **Setup**: Two servers attempt to modify the same player's profile simultaneously.
- **Expected**: `UpdateAsync` checks `SessionLock`. The second server detects active lease and denies concurrent modification.

### Test Case E: Cosmetic Catalog & Equipment Validation
- **Setup**: Attempt to equip an unowned item.
- **Expected**: Rejected with `"Unauthorized item: not owned by player"`.
- **Setup**: Attempt to equip an invalid category (e.g. `"Weapon"`).
- **Expected**: Rejected with `"Invalid category"`.
- **Setup**: Attempt to equip a Title into the Gavel slot.
- **Expected**: Rejected with `"Category mismatch"`.
- **Setup**: Purchase an item with sufficient Braincoins and equip into correct slot.
- **Expected**: Succeeds, balance updates, equipped state replicates to client.

---

## 4. Reproducing Tests in Roblox Studio

1. Open project in Roblox Studio via Rojo:
   - Run `rojo serve default.project.json` in terminal.
   - In Roblox Studio, click **Rojo > Connect** (`localhost:34872`).
2. Run automated logic test suite:
   - Run in terminal: `lune run scripts/run_tests.luau`.
   - Verify `🏆 ALL LOGICTESTS PASSED SUCCESSFULLY! (100%)`.
3. Run static validation:
   - Run in terminal: `selene src`.
   - Verify `Results: 0 errors, 0 warnings, 0 parse errors`.
4. Run multi-client playtest in Studio:
   - In Roblox Studio ribbon: Navigate to **Test** tab.
   - Set **Clients** dropdown to `2 Players` or `4 Players`.
   - Click **Start** to spawn local multi-client server.
   - Observe complete match flow from Lobby through Verdict and Rewards.
