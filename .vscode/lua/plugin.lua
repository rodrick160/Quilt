-- Quilt LSP Plugin
-- Quantum Maniac
-- Feb 11 2024

-- # selene: allow(incorrect_standard_library_use, unused_variable)

--\\ Dependencies //--

---@diagnostic disable-next-line: undefined-doc-module
local FileSystem = require("bee.filesystem")
local FileSystemUtility = require("fs-utility")
local FileURI = require("file-uri")
local JSON = require("json")
local Workspace = require("workspace")

--\\ Private //--

local moduleMap = {}
local projectJsonMap = {}
local quiltPath

local function relativePathToGamePath(relativePath)
	relativePath = tostring(relativePath):gsub("\\", "/"):gsub("%.%w+$", "")
	relativePath = relativePath:gsub("/[^/]*[%.@][^/]", function(str)
		return "[\"" .. str:sub(2) .. "\"]"
	end)
	for codePath, studioPath in pairs(projectJsonMap) do
		relativePath = relativePath:gsub(codePath, studioPath)
	end
	return relativePath:gsub("/", "."):gsub(".init", "")
end

local function buildModuleMap()
	local projectRoot = FileSystem.path(Workspace.path)
	FileSystemUtility.scanDirectory(projectRoot / "", function(path)
		if path:string():match("_Index") then return end
		if path:extension():string() ~= ".lua" then return end
		local uri = FileURI.encode(path:string())
		local relativePath = Workspace.getRelativePath(uri)
		local scriptName = path:stem():string()
		if scriptName == "init" then
			scriptName = path:parent_path():stem():string()
		end
		moduleMap[scriptName] = relativePath
	end)
end

local function buildProjectJsonMap()
	if next(projectJsonMap) then return end

	local projectRoot = FileSystem.path(Workspace.path)
	local projectJson = FileSystemUtility.loadFile(projectRoot / "default.project.json")
	if projectJson then
		projectJson = JSON.decode(projectJson)
		local function addPaths(path, tree)
			for i, v in pairs(tree) do
				if i == "$path" then
					projectJsonMap[v] = path
				elseif i:sub(1, 1) ~= "$" then
					addPaths(path .. "." .. i, v)
				end
			end
		end
		addPaths("game", projectJson.tree)
	end
end

local function buildQuiltPath()
	if quiltPath then return end

	local rootPath = FileSystem.path(Workspace.path)
	FileSystemUtility.scanDirectory(rootPath, function(path)
		if path:string():match("Quilt.lua") or path:string():match("Quilt\\init.lua") then
			local uri = FileURI.encode(path:string())
			local relativePath = Workspace.getRelativePath(uri)
			quiltPath = relativePathToGamePath(relativePath)
		end
	end)
end

local function getModuleGamePath(moduleName)
	local path = moduleMap[moduleName]

	if path and FileSystem.exists(FileSystem.path(path)) then
		return relativePathToGamePath(path)
	end
end

--\\ Public //--

function OnSetText(_, text)
	if text:match("Quilt LSP Plugin") then return end

	buildProjectJsonMap()
	buildQuiltPath()

	local diffs = {}

	for localPos in text:gmatch('()local%s+[%w_]+%s*=%s*Import%s*%(?%s*"Fusion"%s*%)?') do
		diffs[#diffs + 1] = {
			start = localPos,
			finish = localPos - 1,
			text = ("local PubTypes ---@module PubTypes\n---@diagnostic disable-next-line: empty-block\nif PubTypes then end\n"),
		}
	end
	for localPos in text:gmatch('()local%s+[%w_]+%s*=%s*require%s*%(?%s*".*Fusion"%s*%)?') do
		diffs[#diffs + 1] = {
			start = localPos,
			finish = localPos - 1,
			text = ("local PubTypes ---@module PubTypes\n---@diagnostic disable-next-line: empty-block\nif PubTypes then end\n"),
		}
	end
	for startPos, endPos in text:gmatch('()Fusion()%.%w+<%w>') do
		diffs[#diffs + 1] = {
			start = startPos,
			finish = endPos - 1,
			text = "PubTypes",
		}
	end

	local mapBuilt = false

	for moduleStart, moduleName, moduleEnd in text:gmatch("local%s+%w+%s()---@module (%w+)()") do
		local gamePath = getModuleGamePath(moduleName)

		if not gamePath and not mapBuilt then
			mapBuilt = true
			buildModuleMap()
			gamePath = getModuleGamePath(moduleName)
		end

		if gamePath then
			diffs[#diffs + 1] = {
				start = moduleStart,
				finish = moduleEnd - 1,
				text = ("= require(%s)"):format(gamePath)
			}
		end
	end

	local importText, lineEnd = text:match("(%w+)%s*=%s*[^\r\n]*Import()\r\n")
	if quiltPath and importText then
		diffs[#diffs+1] = {
			start = lineEnd,
			finish = lineEnd - 1,
			text = "\n---@diagnostic disable-next-line: empty-block\nif " .. importText .. " then end"
		}

		local function handleImport(moduleStart, moduleName, moduleEnd)
			local gamePath = getModuleGamePath(moduleName)

			if not gamePath and not mapBuilt then
				mapBuilt = true
				buildModuleMap()
				gamePath = getModuleGamePath(moduleName)
			end

			if gamePath then
				diffs[#diffs + 1] = {
					start = moduleStart,
					finish = moduleEnd - 1,
					text = ("require(%s)"):format(gamePath)
				}
			end
		end

		for moduleStart, moduleName, moduleEnd in text:gmatch("local%s+%w+%s*=%s*()" .. importText .. "%s*%(?%s*\"([%w_]+)\"%s-%)?().") do
			handleImport(moduleStart, moduleName, moduleEnd)
		end
		for moduleStart, moduleName, moduleEnd in text:gmatch("local%s+%w+%s*=%s*()" .. importText .. "%.Server%s*%(?%s*\"([%w_]+)\"%s-%)?().") do
			handleImport(moduleStart, moduleName, moduleEnd)
		end
		for moduleStart, moduleName, moduleEnd in text:gmatch("local%s+%w+%s*=%s*()" .. importText .. "%.Client%s*%(?%s*\"([%w_]+)\"%s-%)?().") do
			handleImport(moduleStart, moduleName, moduleEnd)
		end
	end

	if #diffs == 0 then return end
	return diffs
end