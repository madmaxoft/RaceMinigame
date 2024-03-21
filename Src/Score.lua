-- Score.lua

-- Implements the Score class that counts the per-player score for a race





--- Number of points to be awarded for the places (place -> score):
local gPointsForPlace = {3, 2, 1}





Score = {}





function Score:new(aObj)
	aObj = aObj or {}
	setmetatable(aObj, self)
	self.__index = self
	aObj:init()
	return aObj
end





--- Initializes the class' members to the default values
function Score:init()
	self.mScoreByUuid = {}
end





--- Broadcasts the score to everyone on the server
function Score:broadcastToAll()
	local scores = {}
	local n = 1
	for uuid, score in pairs(self.mScoreByUuid) do
		local name = cMojangAPI:GetPlayerNameFromUUID(uuid)
		scores[n] = {mName = name, mScore = score}
		n = n + 1
	end
	table.sort(scores,
		function (aScore1, aScore2)
			return (aScore1.mScore < aScore2.mScore)
		end
	)

	local root = cRoot:Get()
	root:BroadcastChat("Final race results:")
	for _, score in ipairs(scores) do
		root:BroadcastChat(string.format("%s: %d", score.mName, score.mScore))
	end
end





--- Adds a new race result to the score - the specified player has placed in the specified place
function Score:addPlayerScore(aPlayer, aPlace)
	local numPoints = gPointsForPlace[aPlace]
	if not(numPoints) then
		return
	end
	local uuid = aPlayer:GetUUID()
	self.mScoreByUuid[uuid] = (self.mScoreByUuid[uuid] or 0) + numPoints
end
