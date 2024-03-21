-- Race.lua

-- Implements the Race class and provides the global singleton gRace object, representing an on-going race.





require("Score")
require("Arenas")





local Race = {}




--- Flag that specifies whether the player-moving hook
local gEnablePlayerPosHook = false





--- Creates a new object of the Race class, initialized with its initial state
function Race:new(aObj)
	aObj= aObj or {}
	setmetatable(aObj, self)
	self.__index = self
	aObj:init()
	return aObj
end





--- Initializes the object of a Race class with its initial state
function Race:init()
	self.mIsInProgress = false
	self.mPlayersArray = {}
	self.mPlayersByUuid = {}
	self.mPlayerTracksByUuid = {}  -- Map of uuid -> Track for each player
	self.mFinishedPlayersByUuid = {}  -- Map of uuid -> true for all players that have already finished their current track
	self.mCurrentArena = nil
	self.mScore = Score:new()
end






--- Returns whether a race is currently in progress
function Race:isInProgress()
	return self.mIsInProgress
end





--- Adds the specified player to the race
-- Returns true on success, nil and message on failure
function Race:addPlayer(aPlayer)
	assert(not(self.mIsInProgress))
	assert(tolua.type(aPlayer) == "cPlayer")

	-- Check if the player is already present:
	local uuid = aPlayer:GetUUID()
	if (self.mPlayersByUuid[uuid]) then
		return nil, "Already joined"
	end

	-- Add the player:
	table.insert(self.mPlayersArray, aPlayer)
	self.mPlayersByUuid[uuid] = aPlayer
	return true
end





--- Removes the specified player from the race
-- Unlike adding a player, removing does work even while a race is in progress
-- Returns true on success, nil and error message on failure
function Race:removePlayer(aPlayer)
	assert(tolua.type(aPlayer) == "cPlayer")

	-- Check whether the player is present:
	local uuid = aPlayer:GetUUID()
	if not(self.mPlayersByUuid[uuid]) then
		return nil, "Not in the race"
	end

	-- Remove the player:
	self.mPlayersByUuid[uuid] = nil
	for idx, player in ipairs(self.mPlayersArray) do
		if (player:GetUUID() == uuid) then
			table.remove(self.mPlayersArray, idx)
			break
		end
	end
	return true
end





--- Returns whether the player is in the race
function Race:hasPlayerJoined(aPlayer)
	return (self.mPlayersByUuid[aPlayer:GetUUID()] ~= nil)
end





--- Starts a new race from the specified race arena (first one if none specified)
-- Returns true on success, nil and error message on failure
function Race:start(aArena)
	-- Bail out if a race is already in progress:
	if (self.mIsInProgress) then
		return nil, "A race is already in progress"
	end

	-- Check if the arenas support all the players we have:
	local maxPlayersInArenas = gArenas:getMaxPlayers()
	if (#self.mPlayersArray > maxPlayersInArenas) then
		return nil, string.format("Too many players, the arenas only support up to %d players", maxPlayersInArenas)
	end

	-- Pick a starting arena, if not given:
	if not(aArena) then
		local msg
		aArena = gArenas:pickStartingArena()
		if not(aArena) then
			return nil, msg
		end
	end
	assert(type(aArena) == "table")

	self:startRaceInArena(aArena)
end





--- Starts the race in the specified arena
-- Teleports the players to the arena, assigns tracks to players and begins the countdown to the actual race
function Race:startRaceInArena(aArena)
	self.mCurrentArena = aArena
	self.mIsInProgress = true
	self.mNumFinishedPlayers = 0
	self.mFinishedPlayersByUuid = {}
	self:teleportPlayersToCurrentArena()
	self:assignTracksToPlayers()
	self:beginCountdown()
end





--- Assigns a random track from the current arena to each player
function Race:assignTracksToPlayers()
	assert(self.mIsInProgress)

	-- Shuffle tracks from the current arena:
	local numTracks = self.mCurrentArena:trackCount()
	local trackIdx = {}
	for i = 1, numTracks do
		trackIdx[i] = i
	end
	for i = 1, 200 do
		local idx1, idx2 = math.random(numTracks), math.random(numTracks)
		trackIdx[idx1], trackIdx[idx2] = trackIdx[idx2], trackIdx[idx1]
	end

	-- Assign a random track to each player:
	for idx, player in ipairs(self.mPlayersArray) do
		local uuid = player:GetUUID()
		local track = self.mCurrentArena:trackByIdx(trackIdx[idx])
		self.mPlayerTracksByUuid[uuid] = track
	end
end





--- Teleports all the players to the current arena
function Race:teleportPlayersToCurrentArena()
	assert(self.mIsInProgress)

	local arena = self.mCurrentArena
	for _, player in ipairs(self.mPlayersArray) do
		arena:teleportEntityToStart(player)
	end
end





--- Schedules the countdown for the race in the current arena to begin
function Race:beginCountdown()
	-- Schedule a countdown of 5 seconds:
	local countdown = function(aNumber)
		return function()
			if not(self.mIsInProgress) then  -- If "rmg finish" was executed in the meantime
				return
			end
			self:broadcastMessage(string.format("%d...", aNumber))
		end
	end
	local world = self.mCurrentArena:world()
	for i = 1, 5 do
		world:ScheduleTask(i * 20 - 20, countdown(6 - i))
	end

	-- Schedule the race start:
	world:ScheduleTask(100,
		function()
			if not(self.mIsInProgress) then  -- If "rmg finish" was executed in the meantime
				return
			end
			self:broadcastMessage("GO!")
			self:startRaceOnTrack()
		end
	)
end





--- Teleports all players to their tracks' starting positions and starts the race
function Race:startRaceOnTrack()
	for _, player in ipairs(self.mPlayersArray) do
		local uuid = player:GetUUID()
		self.mPlayerTracksByUuid[uuid]:teleportEntityToStart(player)
	end
	self.mStartTick = self.mCurrentArena:world():GetWorldAge()
	gEnablePlayerPosHook = true
end





--- Broadcasts the specified message to all players in the race
function Race:broadcastMessage(aMsg)
	assert(aMsg)

	for _, player in ipairs(self.mPlayersArray) do
		player:SendMessage(aMsg)
	end
end





--- Continues the race in the next arena.
-- Players who haven't finished their track in the current arena are awarded no points.
function Race:continueInNextArena()
	local arena = gArenas:nextArena(self.mCurrentArena)
	self:startRaceInArena(arena)
end






--- Finishes the race
-- Returns the Score object calculated from the finished race.
function Race:finish()
	-- Terminate the race
	gEnablePlayerPosHook = false
	self.mIsInProgress = false

	-- Return the score and reset the internal one for a new race:
	local score = self.mScore
	self.mScore = Score:new()
	return score
end





--- If a race is in progress, checks the specified player's position against their finish cuboid
-- NOTE: This runs in the PLAYER_MOVING hook handler
function Race:checkPlayerPositionForFinish(aPlayer, aPosition)
	-- If not enabled, ignore all movement:
	if not(gEnablePlayerPosHook) then
		return
	end

	-- If player already finished, ignore:
	local uuid = aPlayer:GetUUID()
	if (self.mFinishedPlayersByUuid[uuid]) then
		return
	end

	-- Check the player's finish cuboid:
	local track = self.mPlayerTracksByUuid[uuid]
	if not(track) then
		return  -- Player not in race
	end
	if (track:finishCuboid():IsInside(aPosition)) then
		self:playerReachedFinish(aPlayer)
	end
end





--- Called once a player reaches their track's finish
-- Adds the score, sends messages, teleports the player back to arena's start
-- NOTE: This runs in the PLAYER_MOVING hook handler; teleporting inside a handler doesn't always work
function Race:playerReachedFinish(aPlayer)
	self.mFinishedPlayersByUuid[aPlayer:GetUUID()] = true
	aPlayer:GetWorld():QueueTask(  -- Need to queue the actual work onto the world tick thread, so that teleporting works
		function()
			self.mNumFinishedPlayers = self.mNumFinishedPlayers + 1
			self.mScore:addPlayerScore(aPlayer, self.mNumFinishedPlayers)
			if (self.mNumFinishedPlayers == 1) then
				self:broadcastMessage(string.format("%s has won this round", aPlayer:GetName()))
			elseif (self.mNumFinishedPlayers == 2) then
				self:broadcastMessage(string.format("%s finished 2nd this round", aPlayer:GetName()))
			elseif (self.mNumFinishedPlayers == 3) then
				self:broadcastMessage(string.format("%s finished 3rd this round", aPlayer:GetName()))
			else
				aPlayer:SendMessage(string.format("You finished %dth", self.mNumFinishedPlayers))  -- Assume fewer than 21 players, otherwise we'd need additional logic for "21st"
			end
			self.mCurrentArena:teleportEntityToStart(aPlayer)

			-- If this was the last player, continue in the next arena:
			if (self.mNumFinishedPlayers == #self.mPlayersArray) then
				self:broadcastMessage("The round has finished")
				self.mCurrentArena:world():ScheduleTask(20,
					function()
						self:continueInNextArena()
					end
				)
			end
		end
	)
end





--- Registers the hooks that the race needs to manage everything
-- Called once from the global Initialize()
function Race:registerHooks()
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_MOVING,
		function(aPlayer, aNewPosition)
			self:checkPlayerPositionForFinish(aPlayer, aNewPosition)
		end
	)

	-- Keep players from breaking blocks while the race is underway:
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_BREAKING_BLOCK,
		function (aPlayer)
			if (self.mIsInProgress and self.mPlayersByUuid[aPlayer:GetUUID()]) then
				return true
			end
		end
	)

	-- Keep players from placing blocks while the race is underway:
	cPluginManager:AddHook(cPluginManager.HOOK_PLAYER_PLACING_BLOCK,
		function (aPlayer)
			if (self.mIsInProgress and self.mPlayersByUuid[aPlayer:GetUUID()]) then
				return true
			end
		end
	)
end





gRace = Race:new()
