-- Track.lua

-- Implements the Track class that representing a single race track within an area





Track = {}
Track.__index = Track





--- Creates a new Track object
-- Requires a pre-initalized table with at least the mStartPos, mStartYawDegrees, mStartPitchDegrees and
-- mFinishCuboid members
function Track:new(aObj)
	assert(aObj)
	assert(type(aObj.mParentArena) == "table")
	assert(tolua.type(aObj.mStartPos) == "Vector3<double>")
	assert(type(aObj.mStartYawDegrees) == "number")
	assert(type(aObj.mStartPitchDegrees) == "number")
	assert(tolua.type(aObj.mFinishCuboid) == "cCuboid")

	setmetatable(aObj, self)
	aObj:init()
	return aObj
end





function Track:init()
	-- No initializatin needed yet
end




--- Loads the track parameters from the specified Lua table
-- Used to load the arena config from a file; see saveToLuaTable() for the counterpart
-- Returns a new Track object on success, nil and error message on failure
function Track.fromLuaTable(aTrackDef, aParentArena)
	assert(type(aTrackDef) == "table")
	assert(type(aParentArena) == "table")

	-- Check that the required data is present:
	if (
		(type(aTrackDef.mStartPos) ~= "table") or
		(type(aTrackDef.mStartYawDegrees) ~= "number") or
		(type(aTrackDef.mStartPitchDegrees) ~= "number") or
		(type(aTrackDef.mFinishCuboid) ~= "table")
	) then
		return nil, "Missing required data"
	end

	-- Create the Track object:
	local res =
	{
		mParentArena = aParentArena,
		mStartPos = loadVector3FromTable(aTrackDef.mStartPos),
		mStartYawDegrees = aTrackDef.mStartYawDegrees,
		mStartPitchDegrees = aTrackDef.mStartPitchDegrees,
		mFinishCuboid = loadCuboidFromTable(aTrackDef.mFinishCuboid),
	}
	setmetatable(res, Track)

	return res
end




--- Returns a Lua table that contains all the information for the track, serialized
-- This is used to save the track config to a file; see loadFromLuaTable() for the counterpart
function Track:saveToLuaTable()
	return
	{
		mStartPos = saveVector3ToTable(self.mStartPos),
		mStartYawDegrees = self.mStartYawDegrees,
		mStartPitchDegrees = self.mStartPitchDegrees,
		mFinishCuboid = saveCuboidToTable(self.mFinishCuboid)
	}
end





--- Teleports the specified entity to the track's start
-- Note that if the entity is changing worlds, the teleport is done asynchronously after this function returns
function Track:teleportEntityToStart(aEntity)
	assert(aEntity)

	teleportEntityToWorldPos(aEntity, self.mParentArena:world(), self.mStartPos, self.mStartYawDegrees, self.mStartPitchDegrees)
end





function Track:finishCuboid()
	return self.mFinishCuboid
end
