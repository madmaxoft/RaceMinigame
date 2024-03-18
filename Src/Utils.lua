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
