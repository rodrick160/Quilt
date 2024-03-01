-- Accessor
-- Quantum Maniac
-- Mar 01 2024

--\\ Constants //--

local function UNINITIALIZED_ACCESSOR_ERROR()
	error("Attempt to access uninitialized module (make sure all imported modules have returned from their requires before using them).", 2)
end
local DEFAULT_ACCESSOR_METATABLE = {
	__index = UNINITIALIZED_ACCESSOR_ERROR,
	__newindex = UNINITIALIZED_ACCESSOR_ERROR,
	__call = UNINITIALIZED_ACCESSOR_ERROR,
	__concat = UNINITIALIZED_ACCESSOR_ERROR,
	__unm = UNINITIALIZED_ACCESSOR_ERROR,
	__add = UNINITIALIZED_ACCESSOR_ERROR,
	__sub = UNINITIALIZED_ACCESSOR_ERROR,
	__mul = UNINITIALIZED_ACCESSOR_ERROR,
	__div = UNINITIALIZED_ACCESSOR_ERROR,
	__idiv = UNINITIALIZED_ACCESSOR_ERROR,
	__mod = UNINITIALIZED_ACCESSOR_ERROR,
	__pow = UNINITIALIZED_ACCESSOR_ERROR,
	__tostring = UNINITIALIZED_ACCESSOR_ERROR,
	__eq = UNINITIALIZED_ACCESSOR_ERROR,
	__lt = UNINITIALIZED_ACCESSOR_ERROR,
	__le = UNINITIALIZED_ACCESSOR_ERROR,
	__len = UNINITIALIZED_ACCESSOR_ERROR,
	__iter = UNINITIALIZED_ACCESSOR_ERROR,
}

--\\ Module //--

local Accessor = {}

--\\ Types //--

export type Accessor = {}

--\\ Private //--

local accessors: {[string]: Accessor} = {}

local function generateAccessorMetatable(accessor: Accessor, module: any)
	local metatable = {}
	metatable.__index = module
	metatable.__newindex = module
	metatable.__call = function(_, ...)
		return module(...)
	end
	metatable.__concat = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs .. rhs
	end
	metatable.__unm = function()
		return -module
	end
	metatable.__add = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs + rhs
	end
	metatable.__sub = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs - rhs
	end
	metatable.__mul = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs * rhs
	end
	metatable.__div = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs / rhs
	end
	metatable.__idiv = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs // rhs
	end
	metatable.__mod = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs % rhs
	end
	metatable.__pow = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs ^ rhs
	end
	metatable.__tostring = function()
		return tostring(module)
	end
	metatable.__metatable = getmetatable(module)
	metatable.__eq = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs == rhs
	end
	metatable.__lt = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs < rhs
	end
	metatable.__le = function(lhs, rhs)
		lhs = if lhs == accessor then module else lhs
		rhs = if rhs == accessor then module else rhs
		return lhs <= rhs
	end
	metatable.__len = function()
		return #module
	end
	metatable.__iter = function()
		return pairs(module)
	end

	return metatable
end

--\\ Public //--

function Accessor.Get(moduleName: string): Accessor
	local accessor = accessors[moduleName]
	if not accessor then
		accessor = setmetatable({}, DEFAULT_ACCESSOR_METATABLE)
		accessors[moduleName] = accessor
	end
	return accessor
end

function Accessor.Initialize(moduleName: string, moduleScript: ModuleScript)
	local accessor = accessors[moduleName]
	if not accessor then return end
	if getmetatable(accessor) ~= DEFAULT_ACCESSOR_METATABLE then return end

	local success, moduleValue = pcall(require, moduleScript)
	if success then
		setmetatable(accessor, generateAccessorMetatable(accessor, moduleValue))
	end
end

--\\ Return //--

return Accessor