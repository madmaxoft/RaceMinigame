-- Race.lua

-- Implements the Race class and provides the global singleton gRace object, representing an on-going race.





require("Score")





local Race = {}





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
	self.mPlayers = { n = 0 }
	self.mCurrentArena = nil
	self.mScore = Score:new()
end






--- Returns whether a race is currently in progress
function Race:isInProgress()
	return self.mIsInProgress
end





--- Starts a new race from the specified race arena (first one if none specified)
function Race:start(aArena)
	TODO()
end





--- Continues the race in the next arena.
-- Players who haven't finished their track in the current arena are awarded no points.
function Race:continueInNextArena()
	TODO()
end






--- Finishes the race
-- Returns the Score object calculated from the finished race.
function Race:finish()
	TODO()

	local score = self.mScore
	self.mScore = Score:new()
	return score
end





gRace = Race:new()
