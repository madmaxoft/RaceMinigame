-- Arena.lua

-- Implements the Arena class representing a single race arena.





Arena = {}





local function teleportEntityToWorldPos(aEntity, aWorld, aStartPos, aStartYawDegrees, aStartPitchDegrees)
	assert(aEntity)
	assert(tolua.type(aWorld) == "cWorld")
	assert(tolua.type(aStartPos) == "Vector3<double>")
	assert(type(aStartYawDegrees) == "number")

	-- If the entity is in the same world, just teleport:
	if (aEntity:GetWorld() == aWorld) then
		aEntity:TeleportToCoords(aStartPos.x, aStartPos.y, aStartPos.z)
		aEntity:SetYaw(aStartYawDegrees)
		aEntity:SetPitch(aStartPitchDegrees)
		if (aEntity:IsPlayer()) then
			aEntity:SendRotation(aStartYawDegrees, aStartPitchDegrees)
		end
		return
	end

	-- If the entity is in a different world, first orient it properly and then move it to the arena's world:
	aEntity:SetYaw(aStartYawDegrees)
	aEntity:SetPitch(aStartPitchDegrees)
	if (aEntity:IsPlayer()) then
		aEntity:SendRotation(aStartYawDegrees, aStartPitchDegrees)
	end
	local shouldSendRespawn = false
	if (aEntity:IsPlayer()) then
		shouldSendRespawn = (aEntity:GetWorld():GetDimension() ~= aWorld:GetDimension())  -- Only ever send respawn packet when changing dimensions
	end
	aEntity:MoveToWorld(aWorld, shouldSendRespawn, aStartPos)
end





--- Creates a new Arena object
-- Requires a pre-initalized table with at least the mWorld, mStartPos and mStartYawDegrees members
function Arena:new(aObj)
	assert(aObj)
	assert(tolua.type(aObj.mWorld) == "cWorld")
	assert(tolua.type(aObj.mStartPos) == "Vector3<double>")
	assert(type(aObj.mStartYawDegrees) == "number")
	assert(type(aObj.mStartPitchDegrees) == "number")

	setmetatable(aObj, self)
	self.__index = self
	aObj:init()
	return aObj
end





--- Initializes the class' members to the default values
function Arena:init()
	self.mTracks = self.mTracks or {}

	assert(type(self.mTracks) == "table")
end





function Arena:addTrack(aPosition, aYawDegrees, aPitchDegrees, aFinishCuboid)
end




--- Loads the arena parameters from the specified Lua table
-- Used to load the arena config from a file; see saveToLuaTable() for the counterpart
-- Returns a new Arena object on success, nil and error message on failure
function Arena.fromLuaTable(aArenaDef)
	assert(type(aArenaDef) == "table")

	-- Check that the required data is present:
	if (
		(type(aArenaDef.mWorldName) ~= "string") or
		(type(aArenaDef.mStartPos) ~= "table") or
		(type(aArenaDef.mStartYawDegrees) ~= "number") or
		(type(aArenaDef.mStartPitchDegrees) ~= "number") or
		(type(aArenaDef.mTracks) ~= "table") or
		(type(aArenaDef.mName) ~= "string")
	) then
		return nil, "Missing required data"
	end

	-- Create the Arena object:
	local res =
	{
		mWorld = cRoot:Get():GetWorld(aArenaDef.mWorldName),
		mStartPos = Vector3d(aArenaDef.mStartPos[1], aArenaDef.mStartPos[2], aArenaDef.mStartPos[3]),
		mStartYawDegrees = aArenaDef.mStartYawDegrees,
		mStartPitchDegrees = aArenaDef.mStartPitchDegrees,
		mTracks = {},
		mName = aArenaDef.mName,
	}
	setmetatable(res, Arena)
	Arena.__index = Arena

	-- Load all the tracks:
	for idx, trackDef in ipairs(aArenaDef.mTracks) do
		local trk, msg = Track.fromLuaTable(trackDef)
			if not(trk) then
				return nil, "Failed to load track #" .. idx .. " of arena " .. res.mName .. ": " .. tostring(msg)
			end
		res.mTracks[idx] = trk
	end

	return res
end





--- Teleports the specified entity to the arena's StartPos
-- Note that the teleporting itself may happen asynchronously after this function returns if the entity
-- needs to change worlds
function Arena:teleportEntityToStart(aEntity)
	assert(aEntity)

	teleportEntityToWorldPos(aEntity, self.mWorld, self.mStartPos, self.mStartYawDegrees, self.mStartPitchDegrees)
end





--- Teleports the specified entity to the specified track's start
-- Returns true on success, nil and error message on failure
-- Note that the teleporting itself may happen asynchronously after this function returns if the entity
-- needs to change worlds
function Arena:teleportEntityToTrackStart(aEntity, aTrackNum)
	assert(aEntity)

	-- Get the track:
	local track = self.mTracks[aTrackNum]
	if not(track) then
		return nil, "No such track"
	end

	-- Teleport:
	teleportEntityToWorldPos(aEntity, self.mWorld, track.mStartPos, track.mStartYawDegrees, track.mStartPitchDegrees)
	return true
end





--- Returns a Lua table that contains all the information for the arena, serialized
-- This is used to save the arena config to a file; see loadFromLuaTable() for the counterpart
function Arena:saveToLuaTable()
	local res =
	{
		mWorldName = self.mWorld:GetName(),
		mStartPos =
		{
			self.mStartPos.x,
			self.mStartPos.y,
			self.mStartPos.z
		},
		mStartYawDegrees = self.mStartYawDegrees,
		mStartPitchDegrees = self.mStartPitchDegrees,
		mTracks = {},
		mName = self.mName,
	}
	for idx, track in ipairs(self.mTracks) do
		res.mTracks[idx] = track:saveToLua()
	end

	return res
end
