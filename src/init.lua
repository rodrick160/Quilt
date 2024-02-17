-- Quilt
-- Quantum Maniac
-- Feb 10 2024

--\\ Module //--

local Quilt = {}

--\\ Private //--

local initialized = false
local accessors = {}
local moduleScripts = {}
local modules = {}
local requireStack = {}

local function addModules(instances: {Instance})
    for _, instance in instances do
        if instance:IsA("ModuleScript") then
			if moduleScripts[instance.Name] then
				error("Duplicate module \"" .. instance.Name .. "\".")
			end
            moduleScripts[instance.Name] = instance
        end
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