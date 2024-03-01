local Quilt = require(game.ReplicatedStorage.Packages.Quilt)
Quilt.LoadChildren(script)

local Import = Quilt.Import
local TestModule1 = Import "TestModule1"
TestModule1.DoSomething()