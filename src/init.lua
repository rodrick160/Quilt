-- Quilt
-- Quantum Maniac
-- Feb 10 2024

--\\ Dependencies //--

local RunService = game:GetService("RunService")

--\\ Constants //--

local MODULE_LOCATIONS = {
	workspace,
	game.Players,
	game.Lighting,
	game.ReplicatedFirst,
	game.ReplicatedStorage,
	game.ServerScriptService,
	game.ServerStorage,
	game.SoundService,
}

if RunService:IsClient() and RunService:IsRunning() then
	MODULE_LOCATIONS[#MODULE_LOCATIONS + 1] = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
end

--\\ Module //--

local Quilt = {}

--\\ Private //--

local accessors = {}
local modules = {}
local moduleScripts
local requireStack = {}

local function getModules()
	if moduleScripts then return end
	moduleScripts = {}

	local function _getModules(parent: Instance)
		for _, child in parent:GetChildren() do
			if child.Name == "_Index" then continue end
			if child:IsA("ModuleScript") then
				if moduleScripts[child.Name] then
					error(`Duplicate module "{child.Name}" found.`)
				end
				moduleScripts[child.Name] = child
			end
			_getModules(child)
		end
	end

	for _, location in MODULE_LOCATIONS do
		_getModules(location)
	end
end

--\\ Public //--

function Quilt.Initialize()
    for moduleName, accessor in accessors do
		if getmetatable(accessor) then continue end

		local module = modules[moduleName]
		if not module then
			error(`Failed to find module "{moduleName}".`)
		end

		local metatable
        if typeof(module) == "table" then
			metatable = {
				__index = module,
				__newindex = module,
			}
		elseif typeof(metatable) == "function" then
			metatable = {
				__call = function(_, ...)
					return module(...)
				end
			}
		end

		setmetatable(accessor, metatable)
    end
end

function Quilt.Import(moduleName: string): table
	if not table.find(requireStack, moduleName) then
		getModules()
		local moduleScript = moduleScripts[moduleName]
		if not moduleScript then
			error(`Failed to find module "{moduleName}".`)
		end

		requireStack[#requireStack + 1] = moduleName
		local module = require(moduleScript)
		modules[moduleName] = module
		requireStack[#requireStack] = nil

		if #requireStack == 0 then
			Quilt.Initialize()
		end

		return module
	end

    if not accessors[moduleName] then
        accessors[moduleName] = {}
    end
    local accessor = accessors[moduleName]

    return accessor
end

setmetatable(Quilt, {__call = function(_, ...)
	return Quilt.Import(...)
end})

--\\ Return //--

return Quilt