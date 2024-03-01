-- TestModule2
-- Quantum Maniac
-- Mar 01 2024

--\\ Dependencies //--

local Import = require(game.ReplicatedStorage.Packages.Quilt).Import
local TestModule1 = Import "TestModule1"

--\\ Module //--

local TestModule2 = {}

--\\ Public //--

function TestModule2.DoSomethingElse()
	print("Something else")
	TestModule1.DoAnotherThing()
end

--\\ Return //--

return TestModule2