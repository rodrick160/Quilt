-- Quilt
-- Quantum Maniac
-- Feb 10 2024

--\\ Dependencies //--

local SharedTableRegistry = game:GetService("SharedTableRegistry")

--\\ Module //--

local Quilt = {}

--\\ Private //--

local initialized = false
local accessors = {}
local moduleScripts
local modules = {}
local requireStack = {}

local moduleScriptPaths = SharedTableRegistry:GetSharedTable("ModuleScriptPaths")
if not moduleScriptPaths then
	moduleScriptPaths = SharedTable.new()
	SharedTableRegistry:SetSharedTable("ModuleScriptPaths", moduleScriptPaths)
end

local function generatePath(instance: Instance): string
	local path = ""
	local traveller = instance
	repeat
		if traveller ~= instance then
			path = "/" .. path
		end
		path = traveller.Name:gsub("/", "\1") .. path
		traveller = traveller.Parent
	until traveller == game

	return path
end

local function addModules(instances: {Instance})
    for _, instance in instances do
        if instance:IsA("ModuleScript") then
			if moduleScriptPaths[instance.Name] then
				error("Duplicate module \"" .. instance.Name .. "\".")
			end
            moduleScriptPaths[instance.Name] = generatePath(instance)
        end
    end
end

local function getModuleScripts(): {ModuleScript}
	if moduleScripts then return end

	moduleScripts = {}
	for moduleName, modulePath in moduleScriptPaths do
		local traveller = game
		for _, childName in modulePath:split("/") do
			childName = childName:gsub("\1", "/")
			traveller = traveller[childName]
		end
		moduleScripts[moduleName] = traveller
	end
end

--\\ Public //--

function Quilt.AddModulesDeep(root: Instance)
	addModules(root:GetDescendants())
end

function Quilt.AddModules(root: Instance)
	addModules(root:GetChildren())
end

function Quilt.Initialize()
	if initialized then
		error("Attempt to initialize Quilt twice.", 2)
	end

	getModuleScripts()
	for moduleName, moduleScript in moduleScripts do
		requireStack[#requireStack + 1] = moduleName
		modules[moduleName] = require(moduleScript)
		requireStack[#requireStack] = nil
	end

    for moduleName, accessor in accessors do
		local module = modules[moduleName]
		if not module then
			error("Failed to find module \"" .. moduleName .. "\".")
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

	initialized = true
end

function Quilt.Import(moduleName: string): table
	if not table.find(requireStack, moduleName) then
		getModuleScripts()
		if not moduleScripts[moduleName] then
			error("Failed to find module \"" .. moduleName .. "\".")
		end

		requireStack[#requireStack + 1] = moduleName
		local module = require(moduleScripts[moduleName])
		requireStack[#requireStack] = nil
		return module
	end

	if initialized then
		error("Failed to find module \"" .. moduleName .. "\".")
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