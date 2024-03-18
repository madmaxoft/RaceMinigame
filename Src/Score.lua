-- Score.lua

-- Implements the Score class that counts the per-player score for a race





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
end





--- Broadcasts the score to everyone on the server
function Score:broadcastToAll()
	TODO()
end
