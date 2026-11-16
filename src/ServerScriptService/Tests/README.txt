LogicTests.lua is an executable server-side smoke test module. In Studio's server command bar, run:

require(game.ServerScriptService.Tests.LogicTests).Run()

It verifies role cardinality, evidence bounds and dialogue data, verdict ties, and invalid vote values without requiring a live round.

DataStore, RemoteEvent validation, disconnect cleanup, map prompts, teleportation, animations, and chaos effects require a Roblox Studio server playtest. These are not claimed as static-test results.
