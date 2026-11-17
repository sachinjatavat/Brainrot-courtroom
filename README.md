# BRAINROT COURTROOM: THE FINAL VERDICT

An original, asset-free multiplayer Roblox courtroom party game built in Luau with Rojo. Players take on roles as Judges, Prosecutors, Defense Lawyers, Defendants, Witnesses, and Jurors in procedurally generated absurd cases that spiral into hilarious chaos.

---

## 🌟 Key Features

### 1. Robust Server-Authoritative Architecture
- **Scalable Multiplayer Capacity**: Supports **2 to 12 players** per server.
- **Autonomous Bot Essentials**: On smaller servers (2–3 players), missing essential roles (`Prosecutor`, `Defense`, `Defendant`) are seamlessly filled by functional bots with automated arguments, objections, and pleas.
- **Safe Session Locking & Zero Data Loss**: `DataService` utilizes `UpdateAsync` with session lease protection (900s timeout), exponential backoff retries, and strict `SafeToSave` guards preventing destructive overwrites on failed loads.
- **Fair Role Rotation**: Role history tracking prevents players from repeatedly holding high-impact roles (e.g. Judge) across rounds.

### 2. Deep Courtroom Trial & Contradiction Engine
- **Absurd Procedural Cases**: Hilarious crimes (e.g., stealing the moon for an oversized lamp, robbing golden toilets from the Pentagon, destroying the universe with a plastic spoon) with structured ground truth across 4 topics (`LOCATION`, `TIME`, `OBJECT`, `ACTION`).
- **Logical Witness Memory & Zero False Positives**: Witnesses possess consistent underlying testimony. Contradictions only trigger when a witness contradicts themselves on the **same topic** or authentic reliable evidence directly disproves their claim. Asking across different topics never triggers false contradictions.
- **Dynamic Argument Scoring**: Evaluates lawyer arguments against active evidence, witness consistency, and case facts.

### 3. Functional Humanoid Security Guard NPCs
- **Rigged Humanoid Security**: Built with complete `Motor6D` joints, navy uniforms, Peaked Officer Caps, and Neon Gold Badges.
- **Animated Escort Sequence**: When a defendant is found GUILTY, security guards march to the defendant stand and escort them to the holding cell, featuring safe fallback behavior if the player disconnects.

### 4. Modular Chaos Events Engine
- **10 Real Chaos Events + Courtroom Explosion**:
  - `VOICE_LOSS`: Microphones cut out with audio static, blocking lawyer argument submissions.
  - `COURTROOM_FLOOD`: Floor floods with water rising to Y=3.5 with swimming buoyancy physics.
  - `ROLE_SWAP`: Real-time podium and desk swap of Prosecutor and Defense.
  - `BRAINROT_INVASION`: 10 bouncing neon meme balls with elastic physics and knockback impulses.
  - `GRAVITY_GLITCH`: Gravity drops to 35, causing floaty high jumps.
  - `POSITION_SWAP`: Two players swap positions with poof effects.
  - `BANANA_FLOOD`: Bananas rain from the ceiling; stepping on them causes a 1.2s cartoon slip.
  - `JUDGE_TINY`: Shrinks the Judge to miniature size (0.4x).
  - `EVERYONE_DANCES`: Mandatory courtroom dance groove with slowed movement.
  - `EVIDENCE_MIXUP`: Scrambles evidence exhibits.
  - `COURTROOM_EXPLOSION`: Explosive shockwave scattering flying paperwork.

### 5. Verified Audio & Visual Polish
- **100% Verified System Assets**: Uses verified built-in Roblox client system audio (`rbxasset://sounds/...`) and procedural pitch synthesis. Zero unverified asset IDs.
- **Procedural Animations**: R15/R6 joint animations for `OBJECTION!`, `GAVEL SLAM`, `CRY`, `LAUGH`, `DANCE`, and `FACEPALM`.
- **4 Unlockable Courtroom Themes**: `Classic Mahogany`, `Neo-Tokyo Cyberpunk`, `Ohio Dungeon`, and `Royal Golden Palace` with dynamic material, color, and lighting swaps.

### 6. Progression & Cosmetic Economy
- **Braincoins Shop & Inventory**: Server-validated purchasing and equipping of Gavels, Briefcases, Auras, Titles, and Themes. Cross-category equip attempts and unowned items are strictly rejected.
- **Daily Missions & Lifetime Achievements**: Automated cycling missions and achievements with Braincoin and XP rewards.

---

## 📁 Repository Layout

```
├── default.project.json      # Rojo project configuration
├── aftman.toml               # Toolchain configuration (Rojo, Selene, Lune)
├── selene.toml               # Luau linter rules (Roblox standard library)
├── MULTIPLAYER_TEST_PLAN.md  # Reproducible multiplayer test plan
├── AUDIT_REPORT.md           # Full audit and bug resolution report
├── DEVELOPMENT_STATUS.md     # Development phase status and bug tracker
├── scripts/
│   └── run_tests.luau        # Headless Lune automated test runner
└── src/
    ├── ReplicatedStorage/
    │   └── Shared/           # Core shared modules (CaseGenerator, RoleAssigner, WitnessMemory, etc.)
    ├── ServerScriptService/  # Authoritative game services & test suites
    │   ├── Services/         # RoundService, DataService, MapBuilder, CosmeticsService
    │   └── Tests/            # LogicTests.lua (comprehensive test suite)
    └── StarterPlayer/
        └── StarterPlayerScripts/ # CourtroomClient (UI, HUD, effects, camera shake)
```

---

## 🛠️ Toolchain & Setup

1. **Prerequisites**:
   - Install [Aftman](https://github.com/LPGhatkyt/aftman) (toolchain manager).
   - Run `aftman install` to install `rojo`, `selene`, and `lune`.

2. **Roblox Studio Connection**:
   - Run `rojo serve default.project.json` in your terminal.
   - In Roblox Studio, open your place and click **Connect** in the Rojo plugin.

3. **Production DataStore Persistence**:
   - Publish the place to Roblox and enable **Game Settings > Security > Enable Studio Access to API Services**.
   - In unpublished or local Studio sessions, `DataService` operates safely in an isolated fallback mode.

---

## 🧪 Testing & Verification

### 1. Automated Static Linting (Selene)
```bash
selene src
```
*Result: `0 errors, 0 warnings, 0 parse errors` across all source files.*

### 2. Automated Logic Test Suite (Lune)
```bash
lune run scripts/run_tests.luau
```
*Result: 7 comprehensive test suites covering all bug fixes and mechanics passed with 100% success.*

### 3. Rojo Build Verification
```bash
rojo build default.project.json --output build.rbxl
```
*Result: Builds complete `.rbxl` place file without compilation errors.*

### 4. Multiplayer Studio Playtest
Refer to [MULTIPLAYER_TEST_PLAN.md](file:///c:/Users/sachi/OneDrive/Desktop/Brainrot-courtroom-main/MULTIPLAYER_TEST_PLAN.md) for step-by-step instructions on running 2-player, 4-player, and disconnect regression tests in Roblox Studio.
