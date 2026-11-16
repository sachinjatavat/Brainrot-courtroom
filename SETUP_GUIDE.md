# SETUP & PUBLISHING GUIDE: BRAINROT COURTROOM

A complete guide to configuring, developing, testing, and publishing **BRAINROT COURTROOM: THE FINAL VERDICT**.

---

## 1. Prerequisites

- **Roblox Studio** installed.
- **Rojo** installed (v7.4+; v7.7.1 installed via Aftman).
- **Rojo Studio Plugin** installed (`%LOCALAPPDATA%\Roblox\Plugins\Rojo.rbxm`).

---

## 2. Running Locally with Rojo

1. Open your terminal in the repository folder:
   ```powershell
   cd "C:\Users\sachi\OneDrive\Desktop\Brainrot-courtroom-main"
   ```
2. Start the Rojo sync server:
   ```powershell
   rojo serve
   ```
   *(By default, this listens on `localhost:34872`)*.
3. Open **Roblox Studio**.
4. Create a new empty place or open your existing project place.
5. In the top ribbon bar, click the **Plugins** tab.
6. Click the **Rojo** button and click **Connect**.
7. All game files will immediately synchronize into their respective services (`ReplicatedStorage`, `ServerScriptService`, `StarterPlayer`, etc.).

---

## 3. Running Automated Tests

A built-in comprehensive logic test suite is included in `src/ServerScriptService/Tests/LogicTests.lua`.

To run tests in Roblox Studio:
1. Open the **Command Bar** in Studio (View > Command Bar).
2. Execute:
   ```lua
   require(game.ServerScriptService.Tests.LogicTests).Run()
   ```
3. A successful run returns `true` with zero assertion failures.

---

## 4. Multiplayer Testing in Studio

To test with multiple simulated clients:
1. In Roblox Studio, click the **Test** tab in the top ribbon bar.
2. Under the **Clients and Servers** section, set the player count to **2 Players** or **4 Players**.
3. Click **Start**.
4. Studio will launch 1 Server window and multiple Player client windows.
5. Watch the players spawn in the Grand Lobby, transition through Briefing and Trial, present evidence, cross-examine witnesses, vote in the jury box, and receive dramatic verdicts!

---

## 5. Publishing to Roblox

1. In Roblox Studio, click **File > Publish to Roblox As...**
2. Name your experience: **BRAINROT COURTROOM: THE FINAL VERDICT**.
3. Under **Game Settings > Security**:
   - Enable **Enable Studio Access to API Services** (required for DataStore testing).
   - Enable **Allow HTTP Requests** if external webhooks are configured.
4. Set **Max Players** under Places / Game Settings to **12** (Optimized for 8–12 players).
5. Click **Save** and **Publish**.
