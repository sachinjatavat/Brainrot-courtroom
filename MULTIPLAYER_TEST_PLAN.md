# MULTIPLAYER TEST PLAN: BRAINROT COURTROOM

**Game**: BRAINROT COURTROOM: THE FINAL VERDICT  
**Target Server Size**: 8–12 players  
**Minimum Players**: 2 players  

---

## 1. Test Environments

| Mode | Environment | Purpose |
|---|---|---|
| **Local Multi-Client** | Roblox Studio **Test > Start (2-8 Players)** | Validate network synchronization, role assignment, voting, UI reactivity, character prop welding |
| **Team Test** | Roblox Studio Team Create | Verify real-time edit consistency and concurrent developer sessions |
| **Live Playtest** | Published Place (Private or Public Server) | Test DataStore persistence across servers, API service latency, mobile/tablet input |

---

## 2. Test Suites & Matrix

### Test Case 1: Automatic Role Assignment & Rotation
- **Steps**:
  1. Start server with 4 players (Client 1, Client 2, Client 3, Client 4).
  2. Advance past intermission.
  3. Verify each player receives a unique role from `RoleOrder` (Judge, Prosecutor, Defense, Defendant).
  4. Complete round and observe role assignment in Round 2.
- **Pass Criteria**:
  - Exactly one Judge, Prosecutor, Defense, and Defendant exist.
  - Previous Judge does not immediately repeat as Judge if other candidates exist (fair role rotation).
  - Teleportation places players on correct role pedestals with equipped role props (Judge gavel, lawyer briefcases).

### Test Case 2: Evidence Presentation & Witness Cross-Examination
- **Steps**:
  1. During Trial phase, Prosecutor selects Exhibit 1 and clicks "PRESENT EVIDENCE".
  2. Verify all clients receive notification and exhibit update.
  3. Defense lawyer questions Witness 1 ("QUESTION WITNESS").
  4. Check if contradiction is triggered when conflicting statement is registered.
- **Pass Criteria**:
  - Contradiction triggers notification, sound effect, and spectator NPC gasp reaction.
  - Argument scoring properly evaluates genuine vs misleading evidence.

### Test Case 3: Jury Voting & Single-Submit Constraint
- **Steps**:
  1. Advance to Voting phase.
  2. Jury client votes "GUILTY".
  3. Attempt to vote a second time ("NOT GUILTY").
- **Pass Criteria**:
  - First vote is registered; second vote is ignored by server.
  - Non-jury clients (Judge, Defendant) cannot vote.
  - Bot jury members cast intelligent votes based on evidence reliability and argument scores.

### Test Case 4: Dramatic Verdict Presentation
- **Steps**:
  1. Conclude Voting phase with majority GUILTY.
  2. Conclude a second round with majority NOT GUILTY.
- **Pass Criteria**:
  - GUILTY: Screen vignette turns dark red, defendant plays crying animation, security escorts defendant to jail.
  - NOT GUILTY: Confetti spawns across the courtroom, cyan/gold overlay displays, defense and defendant celebrate with victory dance.
  - End-of-round awards (Best Lawyer, Most Chaotic, Silver Tongue) are calculated and announced with bonus Braincoins.

### Test Case 5: Judge Powers & Chaos Engine
- **Steps**:
  1. As Judge, use "ORDER SILENCE". Verify argument inputs and chat are silenced for 6s.
  2. Use "THROW BANANA". Verify physics bananas spawn and clean up after 4s.
  3. Trigger chaos events (`BANANA_FLOOD`, `GRAVITY_GLITCH`, `COURTROOM_FLOOD`, `ROLE_SWAP`, `COURTROOM_EXPLOSION`).
- **Pass Criteria**:
  - Visual and physics effects clean up cleanly with zero residual workspace clutter.
  - Cooldowns prevent ability spam.

### Test Case 6: Player Disconnection Handling
- **Steps**:
  1. In a 3-player trial, disconnect the Judge mid-trial.
  2. Disconnect a juror during voting.
- **Pass Criteria**:
  - Server automatically promotes an acting Judge or adjusts vote threshold without throwing unhandled exceptions.
  - Round continues to verdict and cleans up safely.

### Test Case 7: Braincoins Shop, Inventory & Persistence
- **Steps**:
  1. Earn or claim coins via daily rewards.
  2. Open Shop modal, purchase "Ohio Banana Gavel" or a Title.
  3. Equip the purchased item.
  4. Reconnect to a published server session.
- **Pass Criteria**:
  - Balance deducts accurately; item status changes to "EQUIPPED".
  - Data persists across server rejoin via DataStoreService.
