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
- **Structured Factual Witness Memory & Equivalence Engine**: Witnesses possess consistent underlying testimony. Contradictions only trigger when a witness makes mutually exclusive factual claims on the **same topic** or authentic reliable evidence directly disproves their claim. Rephrased or equivalent statements (e.g. conversational filler, stop-word variations) are recognized as equivalent and never trigger false positives. Asking across different topics never triggers contradictions.
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

### 5. High-Performance Camera & Responsive UI
- **Genuine Spectator Camera**: Scriptable follow-camera runs exclusively for genuine spectators during active trials (never in the lobby). Features smooth `RunService.RenderStepped` CFrame interpolation, zero tween spam, and cleanly coordinates with the 4-shot briefing cinematic without camera fighting.
- **Optimized UI Performance**: Object-pooled lobby list and witness logs eliminate DOM destruction and reconstruction churn. Responsive `UIScale` auto-adapts for mobile, tablet, and desktop viewports.
- **Verified Audio & Visual Polish**: Uses 100% verified built-in Roblox client system audio (`rbxasset://sounds/...`) and procedural pitch synthesis. Zero unverified asset IDs. Procedural joint animations for `OBJECTION!`, `GAVEL SLAM`, `CRY`, `LAUGH`, `DANCE`, and `FACEPALM`. 4 unlockable courtroom themes with dynamic material, color, and lighting swaps.

### 6. Progression & Cosmetic Economy
- **Braincoins Shop & Inventory**: Server-validated purchasing and equipping of Gavels, Briefcases, Auras, Titles, and Themes. Cross-category equip attempts and unowned items are strictly rejected.
- **Daily Missions & Lifetime Achievements**: Automated cycling missions and achievements with Braincoin and XP rewards.

### 7. Complete Roblox Monetization System (Phase 18)
- **Roblox MarketplaceService Integration**: Fully server-authoritative and idempotent transaction pipeline.
  - **Game Passes**:
    - `VIP Judge` (149 R$): Grants permanent VIP status, priority role weighting, and sovereign titles.
    - `Golden Gavel` (79 R$): Permanently unlocks the Solid Gold Gavel and Royal Golden Judge Gavel.
    - `Premium Emotes` (99 R$): Permanently unlocks exclusive animations (`VIP_BOW`, `CHAMPAGNE`, `MIC_DROP`).
    - `Cyberpunk Courtroom` (199 R$): Permanently unlocks the Neo-Tokyo theme, Neon Gavel, and Glitch Aura.
    - `VIP Nameplate` (49 R$): Glowing golden `[★ VIP ★]` overhead badge displayed across all courtrooms.
  - **Developer Products**:
    - Consumable Braincoin bundles: 500 (49 R$), 1,500 (99 R$), 4,000 (199 R$), and 12,000 (499 R$).
    - Interactive effect products: `Banana Effect` (19 R$), `Funny Gavel Effect` (29 R$).
  - **Strict Idempotent ProcessReceipt**:
    - Server verifies player presence and profile readiness before processing.
    - Persists receipt IDs (`PurchaseId`) into DataStore before returning `Enum.ProductPurchaseDecision.PurchaseGranted`.
    - Duplicate receipts are rejected without double-crediting.
    - If save fails or player is not loaded, returns `Enum.ProductPurchaseDecision.NotProcessedYet` so Roblox safely retries.
    - Client `PromptProductPurchaseFinished` is NEVER treated as proof of purchase.
  - **VIP Courtroom Subscription**:
    - Server-side subscription status check with automatic expiration enforcement.
    - Perks: `[VIP]` overhead title, Diamond VIP Halo, Platinum VIP Gavel, exclusive emotes, and 2,500 monthly Braincoins.
  - **No Pay-to-Win Guarantee**: Monetization is 100% cosmetic, visual, audio, and vanity-based. Trial logic, evidence scoring, and voting remain completely fair and skill/humor-based.
  - **Private Servers**: Full private server support with host control customization.
  - **Monetization Analytics**: Real-time revenue tracking, purchase counts per product, conversion indicators, and failure monitoring.

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
    │   └── Shared/           # Core shared modules (MonetizationConfig, CaseGenerator, RoleAssigner, etc.)
    ├── ServerScriptService/  # Authoritative game services & test suites
    │   ├── Services/         # MonetizationService, RoundService, DataService, MapBuilder, CosmeticsService
    │   └── Tests/            # LogicTests.lua (comprehensive 12 test suites)
    └── StarterPlayer/
        └── StarterPlayerScripts/ # CourtroomClient (UI, Shop categories, HUD, effects, camera)
```

---

## ⚙️ Creator Dashboard Monetization Setup

To configure Robux purchases in your published place:
1. Publish the place to your universe from Roblox Studio (**File > Publish to Roblox**).
2. Open the [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations) and select your Experience.
3. **Game Passes**: Navigate to **Monetization > Passes**, create passes matching the prices in `MonetizationConfig.lua`, copy the generated Pass IDs, and paste them into `src/ReplicatedStorage/Shared/MonetizationConfig.lua`.
4. **Developer Products**: Navigate to **Monetization > Developer Products**, create products for Braincoin bundles (500, 1500, 4000, 12000) and effects, and paste product IDs into `MonetizationConfig.lua`.
5. **Private Servers**: Enable under **Monetization > Private Servers** (recommended 50 R$).

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
*Result: 12 comprehensive test suites covering all bug fixes, structured contradiction rules, DataStore shutdown release, remote validation, complete multiplayer round flow, and full monetization architecture (ProcessReceipt idempotency, Game Passes, VIP subscriptions, analytics) passing with 100% success.*

### 3. Studio Testing vs Automated Headless Testing
- **Automated Lune Suite**: Headless simulation of server state, DataStore transactions, role assignment, witness contradiction engine, argument scoring, and chaos effects.
- **Roblox Studio Testing**: Interactive multi-client testing via Studio's "Start Local Server (2–4 Players)" for visual verification of 3D geometry, client HUD, and player-to-player interaction.

### 3. Rojo Build Verification
```bash
rojo build default.project.json --output build.rbxl
```
*Result: Builds complete `.rbxl` place file without compilation errors.*

### 4. Multiplayer Studio Playtest
Refer to [MULTIPLAYER_TEST_PLAN.md](file:///c:/Users/sachi/OneDrive/Desktop/Brainrot-courtroom-main/MULTIPLAYER_TEST_PLAN.md) for step-by-step instructions on running 2-player, 4-player, and disconnect regression tests in Roblox Studio.
