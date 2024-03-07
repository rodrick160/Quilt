-- Quilt
-- Quantum Maniac
-- Feb 10 2024

--\\ Dependencies //--

local RunService = game:GetService("RunService")

local Accessor = require(script.Accessor)

--\\ Constants //--

local MODULE_LOCATIONS = {
	game.ReplicatedFirst,
	game.ReplicatedStorage,
	game.ServerScriptService,
	game.ServerStorage,
}
if RunService:IsClient() and RunService:IsRunning() then
	MODULE_LOCATIONS[#MODULE_LOCATIONS+1] = game.Players.LocalPlayer:WaitForChild("PlayerScripts")
end

--\\ Module //--

local Quilt = {}

--\\ Types //--

export type PredicateFn = (module: ModuleScript) -> boolean

type Accessor = Accessor.Accessor

--\\ Private //--

local moduleScripts: {[string]: ModuleScript}

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

local function import(module: string | ModuleScript): table
	getModules()

	local moduleScript, moduleName
	if typeof(module) == "string" then
		moduleName = module
		moduleScript = moduleScripts[module]
	elseif typeof(module) == "Instance" and module:IsA("ModuleScript") then
		moduleName = module.Name
		moduleScript = module
	end

	if not moduleScript then
		error(`Failed to find module "{module}".`, 2)
	end

	local success, moduleValue = pcall(require, moduleScript)
	if success then
		Accessor.Initialize(moduleName, moduleScript)
	else
		moduleValue = Accessor.Get(moduleName)
	end

	return moduleValue
end

local function loadList(list: {Instance}, predicate: PredicateFn?): {[string]: any}
	local modules = {}
	for _, instance in list do
		if instance:IsA("ModuleScript") and (not predicate or predicate(instance)) then
			if modules[instance.Name] then
				error(`Duplicate module "{instance.Name}" found.`, 3)
			end
			modules[instance.Name] = import(instance)
		end
	end
	return modules
end

--\\ Public //--

Quilt.Import = setmetatable({
	Server = function(...)
		return if RunService:IsServer() then import(...) else nil
	end,
	Client = function(...)
		return if RunService:IsClient() then import(...) else nil
	end
}, {
	__call = function(_, ...)
		return import(...)
	end
})

function Quilt.LoadChildren(parent: Instance, predicate: PredicateFn?)
	return loadList(parent:GetChildren(), predicate)
end

function Quilt.LoadDescendants(parent: Instance, predicate: PredicateFn?)
	return loadList(parent:GetDescendants(), predicate)
end

function Quilt.MatchesName(matchName: string): (module: ModuleScript) -> boolean
	return function(module)
		return module.Name:match(matchName) ~= nil
	end
end

function Quilt.SpawnAll(loadedModules: {[string]: any}, methodName: string)
	for _, module in loadedModules do
		if typeof(module) == "table" and typeof(module[methodName]) == "function" then
			task.spawn(module[methodName], module)
		end
	end
end

--\\ Return //--

return Quilt