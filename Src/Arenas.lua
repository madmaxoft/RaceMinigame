-- Arenas.lua

-- Implements the Arenas class and the gArenas singleton representing all the arenas known to the plugin





require("Arena")
require("Utils")





local Arenas = {}





function Arenas:new(aObj)
	aObj = aObj or {}
	setmetatable(aObj, self)
	self.__index = self
	aObj:init()
	return aObj
end





--- Initializes the class' members to the default values
function Arenas:init()
	self.mArenas = {}
end





--- Adds a new arena of the specified name
-- Returns the new arena, or nil and error message on an error
function Arenas:addArena(aArenaName, aWorld, aStartPos, aStartYawDegrees, aStartPitchDegrees)
	assert(type(aArenaName) == "string")
	assert(tolua.type(aWorld) == "cWorld")
	assert(tolua.type(aStartPos) == "Vector3<double>")
	assert(type(aStartYawDegrees) == "number")
	assert(type(aStartPitchDegrees) == "number")

	local a = self:findByName(aArenaName)
	if (a) then
		return nil, "Arena already exists"
	end

	-- Add the arena:
	local numArenas = #self.mArenas + 1
	self.mArenas[numArenas] = Arena:new(
		{
			mWorld = aWorld,
			mStartPos = aStartPos,
			mStartYawDegrees = aStartYawDegrees,
			mStartPitchDegrees = aStartPitchDegrees,
			mName = aArenaName
		}
	)

	return self.mArenas[numArenas]
end





--- Deletes the arena of the speified name
-- Returns true on success, or nil and error message on failure
function Arenas:delArena(aArenaName)
	assert(type(aArenaName) == "string")

	for idx, arena in ipairs(self.mArenas) do
		if (arena.mName == aArenaName) then
			local num = #self.mArenas
			self.mArenas[idx] = self.mArenas[num]
			self.mArenas[num] = nil
			return true
		end
	end

	-- Arena not found:
	return nil, "Arena doesn't exist"
end





--- Returns the arena of the specified name
-- Returns nil if no such arena
function Arenas:findByName(aArenaName)
	for _, arena in ipairs(self.mArenas) do
		if (arena.mName == aArenaName) then
			return arena
		end
	end
	return nil
end





--- Saves the complete arena configuration to a config file
-- Returns true on success, nil and error message on failure
function Arenas:save()
	--Back up the previous configuration:
	os.remove("RaceMinigameArenas.bak")
	os.rename("RaceMinigameArenas.cfg", "RaceMinigameArenas.bak")

	-- Save to file:
	local f, msg = io.open("RaceMinigameArenas.cfg", "w")
	if not(f) then
		return nil, msg
	end
	f:write(
[[
-- RaceMinigameArenas.cfg

-- This is the configuration file for the RaceMinigame plugin, containing the definitions of all the arenas currently defined
-- NOTE: This file gets overwritten with every change to the arenas, if you want to edit it manually, you need to stop the server first!

return
]]
	)
	f:write(serializeValue(self:saveToLuaTable()))
	f:close()

	return true
end





--- Returns a Lua table that contains all the arenas, serialized
-- This is used to save the arena config to a file; see loadFromLuaTable() for the counterpart
function Arenas:saveToLuaTable()
	local res = { mArenas = {} }
	for idx, arena in ipairs(self.mArenas) do
		res.mArenas[idx] = arena:saveToLuaTable()
	end

	return res
end





--- Loads the complete arena configuration from the config file
-- Returns true on success, nil and error message on failure
function Arenas:load()
	-- To consider: We're already creating a backup, we might want to try loading that if the main config fails
	return self:loadFromFile("RaceMinigameArenas.cfg")
end





--- Loads the complete arena configuration from the specified file
-- Returns true on success, nil and error message on failure
function Arenas:loadFromFile(aFileName)
	-- Load the file contents:
	local f, msg = io.open(aFileName, "rb")
	if not(f) then
		return nil, msg
	end
	local cfg = f:read("*all")
	f:close()

	-- Parse the Lua code inside:
	cfg, msg = loadstring(cfg, aFileName)
	if not(cfg) then
		return nil, msg
	end
	local isSuccess
	isSuccess, cfg = pcall(cfg)
	if not(isSuccess) then
		return nil, cfg
	end
	if not(cfg) then
		return nil, "Empty configuration"
	end

	-- Load from the configuration table
	for idx, arenaDef in ipairs(cfg.mArenas) do
		local arena, msg = Arena.fromLuaTable(arenaDef)
		if not(arena) then
			return nil, "Failed to load arena #" .. idx .. ": " .. tostring(msg)
		end
		self.mArenas[idx] = arena
	end
	return true
end





gArenas = Arenas:new()
