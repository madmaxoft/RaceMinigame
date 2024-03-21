-- ConsoleCommands.lua

-- Implements the console command handlers referenced in Info.lua





--- Handler for the "rmg list" command
-- Lists all the arenas
function conRmgList(aSplit)
	local arenas = {}
	for idx, arena in ipairs(gArenas.mArenas) do
		arenas[idx] = string.format("%s  (%s, %d tracks)", arena:name(), arena:worldName(), #arena:tracks())
	end
	table.sort(arenas)

	LOG(string.format("Number of arenas: %d", #arenas))
	for _, arena in ipairs(arenas) do
		LOG(arena)
	end
	return true
end





--- Handler for the "rmg reload" command
-- Reloads the arena configuration from the config file
function conRmgReload(aSplit)
	if (gRace:isInProgress()) then
		LOGWARNING("Cannot reload config, a race is underway.")
		return true
	end

	-- Reload into a copy first, if the load fails, we want to keep the old config:
	local replacementArenas = gArenas:new()
	local isSuccess, msg = replacementArenas:load()
	if not(isSuccess) then
		LOGWARNING("Failed to load arena config: " .. tostring(msg))
		return true
	end
	gArenas = replacementArenas

	LOG("Config was reloaded")
	return true
end





--- Handler for the "rmg save" command
-- Saves the current arena configuration to the config file, overwriting any potential changes
function conRmgSave(aSplit)
	local isSuccess, msg = gArenas:save()
	if not(isSuccess) then
		LOGWARNING("Failed to save config: " .. tostring(msg))
		return true
	end
	LOG("Config was saved")
	return true
end





--- Handler for the "rmg alljoin" command
-- Makes all the players join the race
function conRmgAlljoin(aSplit)
	-- Add all the players:
	local acc = {}
	local numAdded = 0
	cRoot:Get():ForEachPlayer(
		function(aPlayer)
			if not(gRace:hasPlayerJoined(aPlayer)) then
				local isSuccess, msg = gRace:addPlayer(aPlayer)
				if not(isSuccess) then
					table.insert(acc, string.format("%s: %s", aPlayer:GetName(), tostring(msg)))
				else
					numAdded = numAdded + 1
				end
			end
		end
	)

	-- Report the status:
	LOG(string.format("%d players joined the race", numAdded))
	if (acc[1]) then
		LOG(string.format("%d players didn't join:", #acc))
		for _, msg in ipairs(acc) do
			LOG("\t" .. msg)
		end
	end
	return true
end
