-- Commands.lua

-- Implements the command handlers referenced in Info.lua





require("Arenas")
require("Race")





--- Returns the player's current WE selection, or nil if none / no WE
local function getWorldEditSelection(aPlayer)
	local sel = cCuboid()
	if not(cPluginManager:CallPlugin("WorldEdit", "GetPlayerCuboidSelection", aPlayer, sel)) then
		return nil
	end
	return sel
end





--- Handler for the "/rmg start" command
-- Starts the race
function rmgStart(aSplit, aPlayer)
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot start a race, a race is already in progress")
		return true
	end

	gRace:start()
	return true
end





--- Handler for the "/rmg continue" command
-- Continues to the next race arena, awards no points to players who haven't finished yet.
function rmgContinue(aSplit, aPlayer)
	if not(gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot continue a race, there's no race in progress.")
		return true
	end

	gRace:continueInNextArena()
	return true
end





--- Handler for the "/rmg finish" command
-- Finishes the races, displays the score
function rmgFinish(aSplit, aPlayer)
	if not(gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot continue a race, there's no race in progress.")
		return true
	end

	local score = gRace:finish()
	score:broadcastToAll()
	return true
end





--- Handler for the "/rmg join" command
-- Adds the player to the race
function rmgJoin(aSplit, aPlayer)
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot join a race, there's a race still in progress. Please wait until the current race finishes.")
		return true
	end

	gRace:addPlayer(aPlayer)
	return true
end





--- Handler for the "/rmg alljoin" command
-- Adds all players except the initiating player to the race
-- Silently skips players already in the race
function rmgAllJoin(aSplit, aPlayer)
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot join a race, there's a race still in progress. Please wait until the current race finishes.")
		return true
	end

	cRoot.Get():ForEachPlayer(
		function(aCBPlayer)
			if (aPlayer == aCBPlayer) then
				return
			end
			gRace:addPlayer(aPlayer)
		end
	)
	return true
end





--- Handler for the "/rmg arena new" command
-- Adds a new arena
function rmgArenaNew(aSplit, aPlayer)
	-- If a race is in progress, abort:
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot modify arenas, there's a race still in progress.")
		return true
	end

	-- If the user didn't give an arena name, abort:
	local arenaName = aSplit[4]
	if not(arenaName) then
		aPlayer:SendMessageFailure("Missing parameter: arena name")
		return true
	end

	-- Add the new arena based on the user's position and yaw:
	local arena, errMsg = gArenas:addArena(arenaName, aPlayer:GetWorld(), aPlayer:GetPosition(), aPlayer:GetYaw(), aPlayer:GetPitch())
	if not(arena) then
		aPlayer:SendMessageFailure(errMsg)
		return true
	end

	-- All OK
	gArenas:save()
	aPlayer:SendMessageSuccess("Arena created")
	return true
end





--- Handler for the "/rmg arena del" command
-- Removes the specified arena
function rmgArenaDel(aSplit, aPlayer)
	-- If a race is in progress, abort:
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot modify arenas, there's a race still in progress.")
		return true
	end

	-- If the user didn't give an arena name, abort:
	if not(aSplit[4]) then
		aPlayer:SendMessageFailure("Missing parameter: arena name")
		return true
	end

	-- Delete the arena:
	local arena, errMsg = gArenas:delArena(aSplit[4])
	if not(arena) then
		aPlayer:SendMessageFailure(errMsg)
		return true
	end

	-- All OK
	gArenas:save()
	aPlayer:SendMessageSuccess("Arena deleted")
	return true
end





--- Handler for the "/rmg arena list" command
-- Lists all arenas
function rmgArenaList(aSplit, aPlayer)
	local arenas = {}
	for idx, arena in ipairs(gArenas.mArenas) do
		arenas[idx] = string.format("%s  (%s)", arena.mName, arena.mWorld:GetName())
	end
	table.sort(arenas)

	aPlayer:SendMessageSuccess(table.concat(arenas, "\n"))
	return true
end





--- Handler for the "/rmg arena goto" command
-- Teleports the player to the specified arena's StartPos
function rmgArenaGoto(aSplit, aPlayer)
	-- If the user didn't give an arena name, abort:
	if not(aSplit[4]) then
		aPlayer:SendMessageFailure("Missing parameter: arena name")
		return true
	end

	-- Find the specified arena:
	local arena = gArenas:findByName(aSplit[4])
	if not(arena) then
		aPlayer:SendMessageFailure("No such arena")
		return true
	end

	-- Teleport the player to the arena:
	arena:teleportEntityToStart(aPlayer)
	return true
end





--- Handler for the "/rmg arena newtrack" command
-- Creates a new track, with start at the current player's pos and end within the current WorldEdit selection
function rmgArenaNewTrack(aSplit, aPlayer)
	-- If a race is in progress, abort:
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot modify arenas, there's a race still in progress.")
		return true
	end

	-- If the user didn't give an arena name, abort:
	local arenaName = aSplit[4]
	if not(arenaName) then
		aPlayer:SendMessageFailure("Missing parameter: arena name")
		return true
	end

	-- Find the specified arena:
	local arena = gArenas:findByName(arenaName)
	if not(arena) then
		aPlayer:SendMessageFailure("No such arena")
		return true
	end
	if (arena.mWorld ~= aPlayer:GetWorld()) then
		aPlayer:SendMessageFailure(string.format(
			"Cannot add track in a different world, the arena is in world %s",
			arena.mWorld:GetName()
		))
		return true
	end

	-- Get the player's current WorldEdit selection:
	local weSel = getWorldEditSelection(aPlayer)
	if not(weSel) then
		aPlayer:SendMessageFailure("Cannot get your current WorldEdit selection")
		return true
	end

	local trackNum = arena:addTrack(aPlayer:GetPosition(), aPlayer:GetYaw(), aPlayer:GetPitch(), weSel)
	gArenas:save()
	aPlayer:SendMessageSuccess(string.format(
		"Track %d added",
		trackNum
	))
	return true
end





--- Handler for the "/rmg arena deltrack" command
-- Removes the specified track
function rmgArenaDelTrack(aSplit, aPlayer)
	-- If a race is in progress, abort:
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot modify arenas, there's a race still in progress.")
		return true
	end

	-- If the user didn't give an arena name, abort:
	if not(aSplit[4]) then
		aPlayer:SendMessageFailure("Missing parameter: arena name")
		return true
	end

	-- If the user didn't give a track number, abort:
	local trackNum = tonumber(aSplit[5])
	if not(trackNum) then
		aPlayer:SendMessageFailure("Missing parameter: track number")
		return true
	end

	-- Find the specified arena:
	local arena = gArenas:findByName(arenaName)
	if not(arena) then
		aPlayer:SendMessageFailure("No such arena")
		return true
	end

	local isSuccess, msg = arena:delTrack(trackNum)
	if not(isSuccess) then
		aPlayer:SendMessageFailure("Cannot delete track: " .. msg)
		return true
	end

	gArenas:save()
	aPlayer:SendMessageSuccess("Track deleted")
	return true
end





--- Handler for the "/rmg arena gototrack" command
-- Teleports the user to the specified track's StartPos, sets their WorldEdit selection to the track's finish
function rmgArenaGotoTrack(aSplit, aPlayer)
	-- If a race is in progress, abort:
	if (gRace:isInProgress()) then
		aPlayer:SendMessageFailure("Cannot modify arenas, there's a race still in progress.")
		return true
	end

	-- If the user didn't give an arena name, abort:
	if not(aSplit[4]) then
		aPlayer:SendMessageFailure("Missing parameter: arena name")
		return true
	end

	-- If the user didn't give a track number, abort:
	local trackNum = tonumber(aSplit[5])
	if not(trackNum) then
		aPlayer:SendMessageFailure("Missing parameter: track number")
		return true
	end

	-- Find the specified arena:
	local arena = gArenas:findByName(arenaName)
	if not(arena) then
		aPlayer:SendMessageFailure("No such arena")
		return true
	end

	local isSuccess, msg = arena:teleportEntityToTrackStart(trackNum, aPlayer)
	if not(isSuccess) then
		aPlayer:SendMessageFailure("Cannot go to track: " .. msg)
		return true
	end
	return true
end
