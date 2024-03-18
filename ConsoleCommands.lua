-- ConsoleCommands.lua

-- Implements the console command handlers referenced in Info.lua





--- Handler for the "rmg list" command
-- Lists all the arenas
function conRmgList(aSplit)
	local arenas = {}
	for idx, arena in ipairs(gArenas.mArenas) do
		arenas[idx] = string.format("%s  (%s)", arena.mName, arena.mWorld:GetName())
	end
	table.sort(arenas)

	LOG(string.format("Number of arenas: %d", #arenas))
	for _, arena in ipairs(arenas) do
		LOG(arena)
	end
	return true
end
