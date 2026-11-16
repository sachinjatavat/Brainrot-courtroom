LogicTests.lua is an executable server-side smoke test module. In Studio's server command bar, run:

require(game.ServerScriptService.Tests.LogicTests).Run()

It verifies role cardinality, evidence bounds, and verdict calculation without requiring a live round.
