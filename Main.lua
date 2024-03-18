-- Main.lua

-- Implements the main plugin entrypoint




-- Load packages from the Src folder:
local thisPluginPath = cPluginManager:Get():GetCurrentPlugin():GetLocalFolder()
package.path = thisPluginPath .. "/Src/?.lua;" .. package.path

-- Load the sources by their dependencies:
require("Commands")
require("Arenas")





function Initialize(aPlugin)
	-- Load the InfoReg shared library:
	dofile(cPluginManager:GetPluginsPath() .. "/InfoReg.lua")

	--Bind all the commands:
	RegisterPluginInfoCommands(gPluginInfo)
	RegisterPluginInfoConsoleCommands(gPluginInfo)

	-- Load the Arena config:
	local isSuccess, msg = gArenas:load()
	if not(isSuccess) then
		LOGWARNING("RaceMinigame: Failed to load arena config: " .. msg)
	end

	LOG("RaceMinigame initialized")
	return true
end
