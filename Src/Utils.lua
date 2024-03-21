-- Utils.lua

-- Implements various utilities used throughout the plugin.





--- Serializes a Lua value into a string, so that it can be saved to a file and later re-loaded
-- Any table members are expected to be only pure-Lua elements - numbers, strings, tables (no userdata!)
-- Supports recursively descending into member tables, but doesn't support multi-references
-- The value is serialized as from the equals-sign until EOF, only tables span multiple lines.
-- aIndent is used only for table values, indicating the indent level to be used on subsequent lines.
function serializeValue(aValue, aIndent)
	aIndent = aIndent or ""
	assert(type(aIndent) == "string")

	local t = type(aValue)
	if (t == "table") then
		local res = "\n" .. aIndent .. "{\n"
		-- First process the array-members:
		local numArrayMembers = #aValue
		local isProcessed = {}
		for idx = 1, numArrayMembers do
			res = res .. aIndent .. "\t" .. serializeValue(aValue[idx], aIndent .. "\t") .. ",\n"
			isProcessed[idx] = true
		end
		for k, v in pairs(aValue) do
			if not(isProcessed[k]) then
				res = res .. aIndent .. "\t" .. tostring(k) .. " = " .. serializeValue(v, aIndent .. "\t") .. ",\n"
			end
		end
		return res .. aIndent .. "}"
	elseif (t == "number") then
		return tostring(aValue)
	elseif (t == "string") then
		return string.format("%q", aValue)
	elseif (t == "boolean") then
		return aValue and "true" or "false"
	end
	error("Value not serializable")
end





--- Returns a Vector3 loaded from the specified pure-Lua table, loaded from config
-- Can be used for Vector3i, Vector3f or Vector3d, the second param decides which class to produce (Vector3d by default)
-- See saveVector3dToTable() for the counterpart
function loadVector3FromTable(aTable, aClass)
	assert(type(aTable) == "table")
	aClass = aClass or Vector3d
	assert((aClass == Vector3i) or (aClass == Vector3f) or (aClass == Vector3d))
	assert(tonumber(aTable[1]))
	assert(tonumber(aTable[2]))
	assert(tonumber(aTable[3]))

	return aClass:new(tonumber(aTable[1]), tonumber(aTable[2]), tonumber(aTable[3]))
end





--- Returns a pure-Lua table representing the specified Vector3, so that it can be saved to a config file
-- Can be used for Vector3i, Vector3f or Vector3d
-- See loadVector3dFromTable() for the counterpart
function saveVector3ToTable(aVector)
	assert(tonumber(aVector.x))
	assert(tonumber(aVector.y))
	assert(tonumber(aVector.z))

	return {
		aVector.x,
		aVector.y,
		aVector.z
	}
end





--- Returns a cCuboid loaded from the specified pure-Lua table, loaded from config
-- See saveVector3dToTable() for the counterpart
function loadCuboidFromTable(aTable)
	assert(type(aTable) == "table")
	assert(aTable.p1)
	assert(aTable.p2)

	return cCuboid(loadVector3FromTable(aTable.p1, Vector3i), loadVector3FromTable(aTable.p2, Vector3i))
end





--- Returns a pura-Lua table representing the specified cCuboid, so that it can be save to a config file
-- See loadCuboidFromTable() for the counterpart
function saveCuboidToTable(aCuboid)
	assert(tolua.type(aCuboid) == "cCuboid")

	return {
		p1 = saveVector3ToTable(aCuboid.p1),
		p2 = saveVector3ToTable(aCuboid.p2),
	}
end





--- Teleports the specified entity to the specified world, coords and look vector
-- It can handle both teleporting to the same world or to another world than the entity is now at
-- NOTE: If the entity is another world, the teleport is done asynchronously after this call returns.
function teleportEntityToWorldPos(aEntity, aWorld, aStartPos, aStartYawDegrees, aStartPitchDegrees)
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





