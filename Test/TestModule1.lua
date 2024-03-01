-- TestModule1
-- Quantum Maniac
-- Mar 01 2024

--\\ Dependencies //--

local Import = require(game.ReplicatedStorage.Packages.Quilt).Import
local TestModule2 = Import "TestModule2"

--\\ Module //--

local TestModule1 = {}

--\\ Public //--

function TestModule1.DoSomething()
	print("Something")
	TestModule2.DoSomethingElse()
end

function TestModule1.DoAnotherThing()
	print("Another thing")
end

--\\ Return //--

return TestModule1